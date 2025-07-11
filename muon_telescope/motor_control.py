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

        class PWM:
            def __init__(self, *a, **kw):
                pass

            def start(self, *a, **kw):
                pass

            def stop(self, *a, **kw):
                pass

    GPIO = MockGPIO()
    GPIO.PWM = MockGPIO.PWM

ENABLE_PIN = 17
DIR_PIN = 18
STEP_PIN = 27
PWM_FREQ = 500
motor_lock = threading.Lock()
GPIO.setmode(GPIO.BCM)
GPIO.setup(ENABLE_PIN, GPIO.OUT)
GPIO.setup(DIR_PIN, GPIO.OUT)
GPIO.setup(STEP_PIN, GPIO.OUT)
pwm = GPIO.PWM(STEP_PIN, PWM_FREQ)
pwm_started = False


def enable_motor():
    GPIO.output(ENABLE_PIN, GPIO.LOW)


def disable_motor():
    GPIO.output(ENABLE_PIN, GPIO.HIGH)


def set_direction(direction):
    GPIO.output(DIR_PIN, GPIO.HIGH if direction else GPIO.LOW)


def do_steps(steps, step_delay=0.002):
    with motor_lock:
        enable_motor()
        for _ in range(abs(steps)):
            GPIO.output(STEP_PIN, GPIO.HIGH)
            time.sleep(step_delay / 2)
            GPIO.output(STEP_PIN, GPIO.LOW)
            time.sleep(step_delay / 2)
        disable_motor()


def do_steps_pwm(steps, frequency=500):
    global pwm_started
    with motor_lock:
        enable_motor()
        set_direction(steps > 0)
        if not pwm_started:
            pwm.start(50)
            pwm_started = True
        time.sleep(abs(steps) / frequency)
        pwm.stop()
        pwm_started = False
        disable_motor()


def cleanup():
    GPIO.cleanup()


motor_thread = None


def _motor_worker(steps, step_delay=0.002):
    with motor_lock:
        enable_motor()
        do_steps(steps, step_delay)
        disable_motor()


def start_motor(steps, step_delay=0.002):
    global motor_thread
    if motor_thread is not None and motor_thread.is_alive():
        return False
    motor_thread = threading.Thread(target=_motor_worker, args=(steps, step_delay))
    motor_thread.start()
    return True


def is_motor_busy():
    return motor_thread is not None and motor_thread.is_alive()
