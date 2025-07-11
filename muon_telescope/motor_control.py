import threading
import time

try:
    import RPi.GPIO as GPIO

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
        if ENABLE_PIN is not None:
            GPIO.output(ENABLE_PIN, GPIO.LOW)

    def disable_motor():
        if ENABLE_PIN is not None:
            GPIO.output(ENABLE_PIN, GPIO.HIGH)

    def set_direction(direction):
        if DIR_PIN is not None:
            GPIO.output(DIR_PIN, GPIO.HIGH if direction else GPIO.LOW)

    def do_steps(steps, step_delay=0.002):
        with motor_lock:
            enable_motor()
            for _ in range(abs(steps)):
                if STEP_PIN is not None:
                    GPIO.output(STEP_PIN, GPIO.HIGH)
                time.sleep(step_delay / 2)
                if STEP_PIN is not None:
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

except ImportError:
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

    def do_steps_pwm(steps, frequency=500):
        print(f"[MOCK] do_steps_pwm({steps}, {frequency}) called")
        time.sleep(abs(steps) / frequency)

    def cleanup():
        print("[MOCK] cleanup() called")


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
    global motor_thread
    return motor_thread is not None and motor_thread.is_alive()
