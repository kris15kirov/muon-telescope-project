import RPi.GPIO as GPIO
import threading
import time

# Pin configuration (update as needed)
ENABLE_PIN = 17
DIR_PIN = 18
STEP_PIN = 27
PWM_FREQ = 500  # Hz

# Threading lock for safe concurrent access
motor_lock = threading.Lock()

# GPIO setup
GPIO.setmode(GPIO.BCM)
GPIO.setup(ENABLE_PIN, GPIO.OUT)
GPIO.setup(DIR_PIN, GPIO.OUT)
GPIO.setup(STEP_PIN, GPIO.OUT)

# PWM setup for step pin
pwm = GPIO.PWM(STEP_PIN, PWM_FREQ)
pwm_started = False

def enable_motor():
    GPIO.output(ENABLE_PIN, GPIO.LOW)  # Enable is active low

def disable_motor():
    GPIO.output(ENABLE_PIN, GPIO.HIGH)

def set_direction(direction):
    GPIO.output(DIR_PIN, GPIO.HIGH if direction else GPIO.LOW)

def do_steps(steps, step_delay=0.002):
    """Perform a number of steps with optional delay (seconds) between steps."""
    with motor_lock:
        enable_motor()
        for _ in range(abs(steps)):
            GPIO.output(STEP_PIN, GPIO.HIGH)
            time.sleep(step_delay / 2)
            GPIO.output(STEP_PIN, GPIO.LOW)
            time.sleep(step_delay / 2)
        disable_motor()

def do_steps_pwm(steps, frequency=500):
    """Perform steps using PWM for smoother control."""
    global pwm_started
    with motor_lock:
        enable_motor()
        set_direction(steps > 0)
        if not pwm_started:
            pwm.start(50)  # 50% duty cycle
            pwm_started = True
        time.sleep(abs(steps) / frequency)
        pwm.stop()
        pwm_started = False
        disable_motor()

def cleanup():
    GPIO.cleanup() 