#!/usr/bin/env python3
"""
GPIO Test Script for Muon Telescope Stepper Motor Control
Tests DM556 stepper motor driver via RPi.GPIO

Hardware Setup:
- GPIO 17: Enable (EN+)
- GPIO 18: Direction (DIR+)
- GPIO 27: Step (PUL+)
- GND: Common ground for all signals
"""

import RPi.GPIO as GPIO
import time
import sys

# GPIO Pin Definitions
ENABLE_PIN = 17  # Enable pin (active low)
DIR_PIN = 18  # Direction pin
STEP_PIN = 27  # Step pin
PULSE_WIDTH = 0.001  # Pulse width in seconds (1ms)

# Motor parameters
STEPS_PER_REVOLUTION = 200  # Standard stepper motor
MICROSTEPS = 16  # DM556 default microstepping
TOTAL_STEPS_PER_REV = STEPS_PER_REVOLUTION * MICROSTEPS


def setup_gpio():
    """Initialize GPIO pins for stepper motor control."""
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(ENABLE_PIN, GPIO.OUT)
    GPIO.setup(DIR_PIN, GPIO.OUT)
    GPIO.setup(STEP_PIN, GPIO.OUT)

    # Initialize pins
    GPIO.output(ENABLE_PIN, GPIO.HIGH)  # Disable motor initially
    GPIO.output(DIR_PIN, GPIO.LOW)
    GPIO.output(STEP_PIN, GPIO.LOW)

    print("GPIO pins initialized:")
    print(f"  Enable: GPIO{ENABLE_PIN}")
    print(f"  Direction: GPIO{DIR_PIN}")
    print(f"  Step: GPIO{STEP_PIN}")


def enable_motor():
    """Enable the stepper motor."""
    GPIO.output(ENABLE_PIN, GPIO.LOW)
    print("Motor enabled")


def disable_motor():
    """Disable the stepper motor."""
    GPIO.output(ENABLE_PIN, GPIO.HIGH)
    print("Motor disabled")


def set_direction(clockwise=True):
    """Set motor direction."""
    if clockwise:
        GPIO.output(DIR_PIN, GPIO.HIGH)
        print("Direction: Clockwise")
    else:
        GPIO.output(DIR_PIN, GPIO.LOW)
        print("Direction: Counter-clockwise")


def step_motor(steps, delay=0.01):
    """Move motor by specified number of steps."""
    print(f"Moving {steps} steps with {delay}s delay...")

    for i in range(steps):
        GPIO.output(STEP_PIN, GPIO.HIGH)
        time.sleep(PULSE_WIDTH)
        GPIO.output(STEP_PIN, GPIO.LOW)
        time.sleep(delay)

    print("Movement complete")


def move_degrees(degrees, clockwise=True):
    """Move motor by specified degrees."""
    steps = int((degrees / 360) * TOTAL_STEPS_PER_REV)
    set_direction(clockwise)
    step_motor(steps)
    print(f"Moved {degrees} degrees ({steps} steps)")


def test_basic_movement():
    """Test basic motor movement."""
    print("\n=== Basic Movement Test ===")
    enable_motor()

    # Test 1: Move 90 degrees clockwise
    print("\nTest 1: Moving 90° clockwise")
    move_degrees(90, True)
    time.sleep(1)

    # Test 2: Move 90 degrees counter-clockwise
    print("\nTest 2: Moving 90° counter-clockwise")
    move_degrees(90, False)
    time.sleep(1)

    # Test 3: Move 180 degrees clockwise
    print("\nTest 3: Moving 180° clockwise")
    move_degrees(180, True)
    time.sleep(1)

    # Test 4: Return to starting position
    print("\nTest 4: Returning to start position")
    move_degrees(180, False)

    disable_motor()


def test_continuous_movement():
    """Test continuous movement with different speeds."""
    print("\n=== Continuous Movement Test ===")
    enable_motor()

    # Test different speeds
    speeds = [0.01, 0.005, 0.002]  # Delays in seconds

    for speed in speeds:
        print(f"\nTesting speed: {speed}s delay")
        set_direction(True)
        step_motor(100, speed)  # Move 100 steps
        time.sleep(0.5)

        set_direction(False)
        step_motor(100, speed)  # Return
        time.sleep(0.5)

    disable_motor()


def interactive_test():
    """Interactive test mode."""
    print("\n=== Interactive Test Mode ===")
    print("Commands:")
    print("  e - Enable motor")
    print("  d - Disable motor")
    print("  c - Set clockwise direction")
    print("  w - Set counter-clockwise direction")
    print("  s <steps> - Step motor (e.g., 's 100')")
    print("  m <degrees> - Move degrees (e.g., 'm 90')")
    print("  q - Quit")

    enable_motor()

    while True:
        try:
            cmd = input("\nEnter command: ").strip().lower()

            if cmd == "q":
                break
            elif cmd == "e":
                enable_motor()
            elif cmd == "d":
                disable_motor()
            elif cmd == "c":
                set_direction(True)
            elif cmd == "w":
                set_direction(False)
            elif cmd.startswith("s "):
                try:
                    steps = int(cmd.split()[1])
                    step_motor(steps)
                except (ValueError, IndexError):
                    print("Invalid steps value")
            elif cmd.startswith("m "):
                try:
                    degrees = float(cmd.split()[1])
                    move_degrees(degrees)
                except (ValueError, IndexError):
                    print("Invalid degrees value")
            else:
                print("Unknown command")

        except KeyboardInterrupt:
            break

    disable_motor()


def cleanup():
    """Clean up GPIO pins."""
    GPIO.cleanup()
    print("\nGPIO cleanup complete")


def main():
    """Main test function."""
    print("Muon Telescope GPIO Test Script")
    print("=" * 40)

    try:
        setup_gpio()

        while True:
            print("\nSelect test mode:")
            print("1. Basic movement test")
            print("2. Continuous movement test")
            print("3. Interactive test")
            print("4. Exit")

            choice = input("Enter choice (1-4): ").strip()

            if choice == "1":
                test_basic_movement()
            elif choice == "2":
                test_continuous_movement()
            elif choice == "3":
                interactive_test()
            elif choice == "4":
                break
            else:
                print("Invalid choice")

    except KeyboardInterrupt:
        print("\nTest interrupted by user")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        cleanup()


if __name__ == "__main__":
    main()
