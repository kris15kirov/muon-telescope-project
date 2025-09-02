import threading
import time

try:
    import RPi.GPIO as GPIO
except (ImportError, RuntimeError):

    class MockGPIO:
        BCM = 11
        BOARD = 10
        OUT = 0
        IN = 1
        HIGH = 1
        LOW = 0

        def setmode(self, *a, **kw):
            pass

        def setup(self, *a, **kw):
            pass

        def output(self, *a, **kw):
            pass

        def cleanup(self, *a, **kw):
            pass

        # PWM CLASS COMMENTED OUT - NOT NEEDED AT THIS POINT OF THE PROJECT
        # class PWM:
        #     def __init__(self, *a, **kw):
        #         pass

        #     def start(self, *a, **kw):
        #         pass

        #     def stop(self, *a, **kw):
        #         pass

    GPIO = MockGPIO()
    # GPIO.PWM = MockGPIO.PWM  # PWM not needed at this point


# Global motor state
motor_state = {
    "is_moving": False,
    "current_position": 0,
    "target_position": 0,
    "is_enabled": False,
    "step_delay": 0.020,
    "paused" : False,
}

ENABLE_PIN = 17  # Enable pin (active low)
DIR_PIN = 27  # Direction pin
STEP_PIN = 22  # Step pin
motor_lock = threading.Lock()
GPIO.setmode(GPIO.BCM)
GPIO.setup(ENABLE_PIN, GPIO.OUT)
GPIO.setup(DIR_PIN, GPIO.OUT)
GPIO.setup(STEP_PIN, GPIO.OUT)
GPIO.output(ENABLE_PIN, GPIO.LOW)

def enable_motor():
    GPIO.output(ENABLE_PIN, GPIO.LOW)


def disable_motor():
    GPIO.output(ENABLE_PIN, GPIO.HIGH)


def set_direction(direction):
    GPIO.output(DIR_PIN, GPIO.HIGH if direction else GPIO.LOW)


def do_steps(steps, step_delay):
    global motor_state
    with motor_lock:
        ii=0
        while ii < abs(steps):
            ii += 1
            GPIO.output(STEP_PIN, GPIO.HIGH)
            time.sleep(step_delay / 2)
            GPIO.output(STEP_PIN, GPIO.LOW)
            time.sleep(step_delay / 2)


def cleanup():
    GPIO.cleanup()


motor_thread = None


def _motor_worker(steps, step_delay):
    with motor_lock:
        do_steps(steps, step_delay)


def start_motor(steps, step_delay):
    global motor_thread
    if motor_thread is not None and motor_thread.is_alive():
        return False
    motor_thread = threading.Thread(target=_motor_worker, args=(steps, step_delay))
    motor_thread.start()
    return True


def is_motor_busy():
    return motor_thread is not None and motor_thread.is_alive()
