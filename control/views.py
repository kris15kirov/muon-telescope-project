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

BASE_DIR = Path(__file__).resolve().parent.parent

BACKEND_API_URL = "http://localhost:8000/api"  # Adjust as needed

# Import motor control
try:
    from muon_telescope.motor_control import (
        enable_motor,
        disable_motor,
        set_direction,
        do_steps,
        cleanup,
    )

    MOTOR_CONTROL_AVAILABLE = True
except ImportError as e:
    print(f"Warning: Motor control not available: {e}")

    # Mock functions for development
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
        zero_pos = int(data)

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
def api_shutdown(request):
    """Shutdown the Raspberry Pi."""
    try:
        import subprocess

        log_movement("shutdown", {})

        # Schedule shutdown in 5 seconds
        subprocess.run(["shutdown", "-h", "5"], check=True)

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
    """Perform a specific number of steps."""
    try:
        data = json.loads(request.body)
        steps = data.get("steps", 0)

        if steps == 0:
            return JsonResponse(
                {"status": "error", "message": "Steps must be non-zero"}, status=400
            )

        # Get step delay from motor state or use default
        step_delay = motor_state.get("step_delay", 0.002)

        # Set direction
        set_direction(steps > 0)

        # Move motor
        motor_state["is_moving"] = True
        do_steps(abs(steps), step_delay)
        motor_state["is_moving"] = False

        # Update position (approximate)
        position_change = (steps / TOTAL_STEPS_PER_REV) * 360
        motor_state["current_position"] += position_change

        log_movement("do_steps", {"steps": steps, "position_change": position_change})

        return JsonResponse(
            {
                "status": "success",
                "message": f"Completed {steps} steps",
                "position": motor_state["current_position"],
            }
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
