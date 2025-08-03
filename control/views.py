from django.shortcuts import render, redirect
from django.contrib import messages
from django.contrib.auth import logout as auth_logout
from django.urls import reverse
import requests
from .forms import ControlForm, RegisterForm
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
import json
from datetime import datetime

from pathlib import Path
from django.contrib.auth.decorators import user_passes_test
import threading
import time

from django.contrib.auth.views import LoginView
from django.contrib.auth.decorators import login_required
from django.core.exceptions import PermissionDenied


class MyLoginView(LoginView):
    redirect_authenticated_user = True


BASE_DIR = Path(__file__).resolve().parent.parent

BACKEND_API_URL = "http://localhost:8000/api"  # Adjust as needed

try:
    from muon_telescope.motor_control import (
        enable_motor,
        disable_motor,
        set_direction,
        do_steps,
        cleanup,
        start_motor,
        is_motor_busy,
    )

    MOTOR_CONTROL_AVAILABLE = True
except ImportError as e:
    print(f"Warning: Motor control not available: {e}")

    def enable_motor():
        pass

    def disable_motor():
        pass

    def set_direction(direction):
        pass

    def do_steps(steps, step_delay=0.002):
        pass

    def cleanup():
        pass

    MOTOR_CONTROL_AVAILABLE = False

# Motor parameters
STEPS_PER_REVOLUTION = 200
MICROSTEPS = 16
TOTAL_STEPS_PER_REV = STEPS_PER_REVOLUTION * MICROSTEPS

# Global motor state
motor_state = {
    "is_moving": False,
    "current_position": 0,
    "target_position": 0,
    "is_enabled": False,
}

# Movement logs
movement_logs = []

# Threading event for pause/resume
motor_pause_event = threading.Event()
motor_pause_event.set()  # Initially not paused

motor_thread = None

# Motor control lock for thread-safe operations
motor_lock = threading.Lock()


def log_movement(action, details):
    """Log motor movement for history."""
    log_entry = {
        "timestamp": datetime.now().isoformat(),
        "action": action,
        "details": details,
        "position": motor_state["current_position"],
    }
    movement_logs.append(log_entry)
    # Keep only last 100 entries
    if len(movement_logs) > 100:
        movement_logs.pop(0)


def is_admin(user):
    return user.is_superuser or user.is_staff


def admin_required(view_func):
    def _wrapped_view(request, *args, **kwargs):
        if not is_admin(request.user):
            raise PermissionDenied
        return view_func(request, *args, **kwargs)

    return _wrapped_view


@login_required
def control(request):
    if request.method == "POST":
        form = ControlForm(request.POST)
        if form.is_valid():
            if "logout" in request.POST:
                auth_logout(request)
                return redirect(reverse("login"))
            elif "go" in request.POST:
                angle = form.cleaned_data["angle"]
                try:
                    r = requests.post(
                        f"{BACKEND_API_URL}/goto_angle", json={"angle": angle}
                    )
                    if r.ok:
                        messages.info(request, f"Moving to angle {angle}°")
                    else:
                        messages.error(request, f"Failed to move: {r.text}")
                except Exception as e:
                    messages.error(request, f"Error: {e}")
                return redirect("control")
            elif "set_zero" in request.POST:
                zero = form.cleaned_data["zero"]
                try:
                    r = requests.post(f"{BACKEND_API_URL}/set_zero_position", json=zero)
                    if r.ok:
                        messages.success(request, f"Zero position set to {zero}")
                    else:
                        messages.error(request, f"Failed to set zero: {r.text}")
                except Exception as e:
                    messages.error(request, f"Error: {e}")
                return redirect("control")
    else:
        form = ControlForm()
    template_name = "control/control.html"
    return render(request, template_name, {"form": form})


def register(request):
    if request.method == "POST":
        form = RegisterForm(request.POST)
        if form.is_valid():
            form.save()
            messages.success(
                request, "Account created successfully. You can now log in."
            )
            return redirect("login")
    else:
        form = RegisterForm()
    return render(request, "control/register.html", {"form": form})


# API Endpoints


@csrf_exempt
@require_http_methods(["POST"])
def api_move_motor(request):
    """Move motor to specified angle."""
    try:
        data = json.loads(request.body)
        angle = data.get("angle", 0)

        # Calculate steps needed
        steps = int((angle / 360) * TOTAL_STEPS_PER_REV)

        # Set direction
        set_direction(steps > 0)

        # Move motor
        motor_state["is_moving"] = True
        motor_state["target_position"] = angle
        do_steps(abs(steps))
        motor_state["current_position"] = angle
        motor_state["is_moving"] = False

        log_movement("move", {"angle": angle, "steps": steps})

        return JsonResponse(
            {
                "status": "success",
                "message": f"Moved to {angle}°",
                "position": motor_state["current_position"],
            }
        )
    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)}, status=400)


@csrf_exempt
@require_http_methods(["POST"])
def api_stop_motor(request):
    """Stop motor movement."""
    try:
        motor_state["is_moving"] = False
        disable_motor()

        log_movement("stop", {"position": motor_state["current_position"]})

        return JsonResponse(
            {
                "status": "success",
                "message": "Motor stopped",
                "position": motor_state["current_position"],
            }
        )
    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)}, status=400)


@csrf_exempt
@require_http_methods(["POST"])
def api_reset_position(request):
    """Reset motor position to zero."""
    try:
        # Move to zero position
        current_pos = motor_state["current_position"]
        steps = int((current_pos / 360) * TOTAL_STEPS_PER_REV)

        if steps != 0:
            set_direction(steps < 0)  # Reverse direction
            motor_state["is_moving"] = True
            do_steps(abs(steps))
            motor_state["is_moving"] = False

        motor_state["current_position"] = 0

        log_movement("reset", {"from_position": current_pos})

        return JsonResponse(
            {"status": "success", "message": "Position reset to zero", "position": 0}
        )
    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)}, status=400)


@require_http_methods(["GET"])
def api_motor_status(request):
    """Get current motor status."""
    return JsonResponse(
        {
            "is_moving": motor_state["is_moving"],
            "current_position": motor_state["current_position"],
            "target_position": motor_state["target_position"],
            "is_enabled": motor_state["is_enabled"],
        }
    )


@require_http_methods(["GET"])
def api_movement_logs(request):
    """Get movement history logs."""
    return JsonResponse({"logs": movement_logs[-20:]})  # Return last 20 entries


@csrf_exempt
@require_http_methods(["POST"])
def api_goto_angle(request):
    """Move to specific angle (alias for move_motor)."""
    return api_move_motor(request)


@csrf_exempt
@require_http_methods(["POST"])
def api_set_zero_position(request):
    """Set zero position reference."""
    try:
        data = json.loads(request.body)
        zero_pos = int(data.get("position", 0))

        motor_state["current_position"] = zero_pos

        log_movement("set_zero", {"zero_position": zero_pos})

        return JsonResponse(
            {
                "status": "success",
                "message": f"Zero position set to {zero_pos}",
                "zero_position": zero_pos,
            }
        )
    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)}, status=400)


@csrf_exempt
@require_http_methods(["POST"])
def api_enable_stepper(request):
    """Enable stepper motor."""
    try:
        enable_motor()
        motor_state["is_enabled"] = True

        log_movement("enable", {})

        return JsonResponse({"status": "success", "message": "Stepper motor enabled"})
    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)}, status=400)


@csrf_exempt
@require_http_methods(["POST"])
def api_disable_stepper(request):
    """Disable stepper motor."""
    try:
        disable_motor()
        motor_state["is_enabled"] = False

        log_movement("disable", {})

        return JsonResponse({"status": "success", "message": "Stepper motor disabled"})
    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)}, status=400)


@csrf_exempt
@require_http_methods(["POST"])
def api_set_direction(request):
    """Set motor direction."""
    try:
        data = json.loads(request.body)
        direction = data.get("direction", "plus")

        if direction == "plus":
            set_direction(True)
            direction_name = "clockwise"
        else:
            set_direction(False)
            direction_name = "counter-clockwise"

        log_movement("set_direction", {"direction": direction_name})

        return JsonResponse(
            {"status": "success", "message": f"Direction set to {direction_name}"}
        )
    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)}, status=400)


@require_http_methods(["GET"])
def api_health(request):
    """Health check endpoint."""
    return JsonResponse(
        {
            "status": "healthy",
            "timestamp": datetime.now().isoformat(),
            "motor_enabled": motor_state["is_enabled"],
        }
    )


@csrf_exempt
@require_http_methods(["POST"])
@admin_required
def api_shutdown(request):
    print(
        f"User: {request.user}, is_superuser: {request.user.is_superuser}, is_staff: {request.user.is_staff}, is_authenticated: {request.user.is_authenticated}"
    )
    try:
        import subprocess

        log_movement("shutdown", {})
        # Use '+5' for 5 minutes delay; 'now' for immediate shutdown
        subprocess.run(["sudo", "shutdown", "-h", "+5"], check=True)
        return JsonResponse(
            {
                "status": "success",
                "message": "Shutdown command sent. System will power off in 5 seconds.",
            }
        )
    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)}, status=400)


@csrf_exempt
@require_http_methods(["POST"])
def api_set_step_period(request):
    """Set step period for motor movement."""
    try:
        data = json.loads(request.body)
        period_ms = data.get("period_ms", 2)

        # Convert to seconds
        step_delay = period_ms / 1000.0

        # Store in motor state for future use
        motor_state["step_delay"] = step_delay

        log_movement("set_step_period", {"period_ms": period_ms})

        return JsonResponse(
            {"status": "success", "message": f"Step period set to {period_ms}ms"}
        )
    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)}, status=400)


@csrf_exempt
@require_http_methods(["POST"])
def api_do_steps(request):
    """Perform a specific number of steps in a non-blocking way."""
    try:
        data = json.loads(request.body)
        steps = data.get("steps", 0)
        if steps == 0:
            return JsonResponse(
                {"status": "error", "message": "Steps must be non-zero"}, status=400
            )
        step_delay = motor_state.get("step_delay", 0.002)
        set_direction(steps > 0)
        started = start_motor(abs(steps), step_delay)
        if started:
            motor_state["is_moving"] = True
            log_movement("do_steps_async", {"steps": steps})
            return JsonResponse(
                {"status": "started", "message": f"Started {steps} steps"}
            )
        else:
            return JsonResponse(
                {"status": "busy", "message": "Motor is already running"}, status=409
            )
    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)}, status=400)


@csrf_exempt
@require_http_methods(["POST"])
def api_do_steps_pwm(request):
    """Perform a specific number of steps using PWM for smooth stepping."""
    try:
        data = json.loads(request.body)
        steps = data.get("steps", 0)
        frequency = data.get("frequency", 500)  # Default 500 Hz
        if steps == 0:
            return JsonResponse(
                {"status": "error", "message": "Steps must be non-zero"}, status=400
            )
        # Set direction
        set_direction(steps > 0)
        # Move motor using PWM
        motor_state["is_moving"] = True
        if MOTOR_CONTROL_AVAILABLE:
            from muon_telescope.motor_control import do_steps_pwm

            do_steps_pwm(abs(steps), frequency)
        motor_state["is_moving"] = False
        # Update position (approximate)
        position_change = (steps / TOTAL_STEPS_PER_REV) * 360
        motor_state["current_position"] += position_change
        log_movement(
            "do_steps_pwm",
            {
                "steps": steps,
                "frequency": frequency,
                "position_change": position_change,
            },
        )
        return JsonResponse(
            {
                "status": "success",
                "message": f"Completed {steps} steps with PWM",
                "position": motor_state["current_position"],
            }
        )
    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)}, status=400)


@require_http_methods(["GET"])
def api_motor_busy(request):
    """Check if the motor is currently running."""
    return JsonResponse({"busy": is_motor_busy()})


@csrf_exempt
@require_http_methods(["POST"])
@admin_required
def api_quit_motor(request):
    """Disable the motor (admin only)."""
    try:
        disable_motor()
        motor_state["is_enabled"] = False
        log_movement("quit_motor", {})
        return JsonResponse({"status": "success", "message": "Motor disabled (quit)"})
    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)}, status=400)


@csrf_exempt
@require_http_methods(["POST"])
def api_pause_motor(request):
    """Pause motor movement."""
    try:
        motor_pause_event.clear()
        log_movement("pause_motor", {})
        return JsonResponse({"status": "success", "message": "Motor paused"})
    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)}, status=400)


@csrf_exempt
@require_http_methods(["POST"])
def api_resume_motor(request):
    """Resume motor movement."""
    try:
        motor_pause_event.set()
        log_movement("resume_motor", {})
        return JsonResponse({"status": "success", "message": "Motor resumed"})
    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)}, status=400)


# Example of background thread motor movement with pause/resume


def threaded_do_steps(steps, step_delay=0.002):
    with motor_lock:
        enable_motor()
        for _ in range(abs(steps)):
            while not motor_pause_event.is_set():
                time.sleep(0.1)  # Wait while paused
            # Use do_steps for actual stepping, which handles GPIO or mock
            do_steps(1, step_delay)
        disable_motor()


# To use in an endpoint:
# global motor_thread
# if motor_thread is None or not motor_thread.is_alive():
#     motor_thread = threading.Thread(target=threaded_do_steps, args=(steps, step_delay))
#     motor_thread.start()
# else:
#     return JsonResponse({"status": "error", "message": "Motor is already moving"}, status=400)
