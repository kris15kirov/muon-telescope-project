from django.urls import path
from django.contrib.auth import views as auth_views
from . import views

import threading
import time

try:
    # Import RPi.GPIO and catch RuntimeError immediately
    import RPi.GPIO as GPIO
except (ImportError, RuntimeError):
    GPIO = None

if GPIO:
    ENABLE_PIN = 17  # Enable pin (active low) - Pin 11
    DIR_PIN = 27  # Direction pin - Pin 13
    STEP_PIN = 22  # Step pin - Pin 15
    PWM_FREQ = 500  # Hz
    motor_lock = threading.Lock()
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(ENABLE_PIN, GPIO.OUT)
    GPIO.setup(DIR_PIN, GPIO.OUT)
    GPIO.setup(STEP_PIN, GPIO.OUT)
    #pwm = GPIO.PWM(STEP_PIN, PWM_FREQ)
    #pwm_started = False

    GPIO.output(DIR_PIN, GPIO.HIGH)  # type: ignore
    
    def enable_motor():
        GPIO.output(ENABLE_PIN, GPIO.LOW)  # type: ignore

    def disable_motor():
        GPIO.output(ENABLE_PIN, GPIO.HIGH)  # type: ignore

    def set_direction(direction):
        GPIO.output(DIR_PIN, GPIO.HIGH if direction else GPIO.LOW)  # type: ignore

    def do_steps(steps, step_delay=0.002):
        with motor_lock:
            for _ in range(abs(steps)):
                GPIO.output(STEP_PIN, GPIO.HIGH)  # type: ignore
                time.sleep(step_delay / 2)
                GPIO.output(STEP_PIN, GPIO.LOW)  # type: ignore
                time.sleep(step_delay / 2)

#    def do_steps_pwm(steps, frequency=500):
#        global pwm_started
#        with motor_lock:
#            set_direction(steps > 0)
#            if not pwm_started:
#                pwm.start(50)
#                pwm_started = True
#            time.sleep(abs(steps) / frequency)
#            pwm.stop()
#            pwm_started = False

    def cleanup():
        GPIO.cleanup()

else:
    ENABLE_PIN = DIR_PIN = STEP_PIN = PWM_FREQ = None
    motor_lock = threading.Lock()

    def enable_motor():
        print("[MOCK] enable_motor() called")

    def disable_motor():
        print("[MOCK] disable_motor() called")

    def set_direction(direction):
        print(f"[MOCK] set_direction({direction}) called")

    def do_steps(steps, step_delay=0.002):
        print(f"[MOCK] do_steps({steps}, {step_delay}) called")
        time.sleep(abs(steps) * step_delay)

#    def do_steps_pwm(steps, frequency=500):
#        print(f"[MOCK] do_steps_pwm({steps}, {frequency}) called")
#        time.sleep(abs(steps) / frequency)

    def cleanup():
        print("[MOCK] cleanup() called")


urlpatterns = [
    path("", views.control, name="control"),
    path("logout/", auth_views.LogoutView.as_view(next_page="login"), name="logout"),
    path("register/", views.register, name="register"),
    # API Endpoints
    path("api/motor/move/", views.api_move_motor, name="api_move_motor"),
    path("api/motor/stop/", views.api_stop_motor, name="api_stop_motor"),
    path("api/motor/reset/", views.api_reset_position, name="api_reset_position"),
    path("api/status/", views.api_motor_status, name="api_motor_status"),
    path("api/logs/", views.api_movement_logs, name="api_movement_logs"),
    path("api/goto_angle/", views.api_goto_angle, name="api_goto_angle"),
    path(
        "api/set_zero_position/",
        views.api_set_zero_position,
        name="api_set_zero_position",
    ),
    path("api/enable_stepper/", views.api_enable_stepper, name="api_enable_stepper"),
    path("api/disable_stepper/", views.api_disable_stepper, name="api_disable_stepper"),
    path("api/set_direction/", views.api_set_direction, name="api_set_direction"),
    path("api/health/", views.api_health, name="api_health"),
    path("api/quit_motor/", views.api_quit_motor, name="api_quit_motor"),
    path("api/pause_motor/", views.api_pause_motor, name="api_pause_motor"),
    path("api/resume_motor/", views.api_resume_motor, name="api_resume_motor"),
    path("api/motor_busy/", views.api_motor_busy, name="api_motor_busy"),
]
