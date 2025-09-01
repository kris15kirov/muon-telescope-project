
import RPi.GPIO as GPIO

ENABLE_PIN = 17  # Enable pin (active low) - Pin 11
DIR_PIN = 13  # Direction pin - Pin 13
STEP_PIN = 22  # Step pin - Pin 15
PWM_FREQ = 500  # Hz
GPIO.setmode(GPIO.BOARD)
#GPIO.setup(ENABLE_PIN, GPIO.OUT)
GPIO.setup(DIR_PIN, GPIO.OUT)
#GPIO.setup(STEP_PIN, GPIO.OUT)
#pwm = GPIO.PWM(STEP_PIN, PWM_FREQ)
#pwm_started = False

GPIO.output(DIR_PIN, GPIO.LOW)  # type: ignore
