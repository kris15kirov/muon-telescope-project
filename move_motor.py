#!/usr/bin/env python3
import argparse
from muon_telescope.motor_control import (
    enable_motor,
    disable_motor,
    set_direction,
    do_steps,
)


def main():
    parser = argparse.ArgumentParser(
        description="Move the stepper motor a specified number of steps."
    )
    parser.add_argument(
        "--steps",
        type=int,
        required=True,
        help="Number of steps to move (positive for CW, negative for CCW)",
    )
    parser.add_argument(
        "--direction",
        choices=["CW", "CCW"],
        default=None,
        help="Direction: CW (clockwise) or CCW (counterclockwise). If not set, inferred from steps sign.",
    )
    parser.add_argument(
        "--step-delay",
        type=float,
        default=0.002,
        help="Delay between steps in seconds (default: 0.002)",
    )
    args = parser.parse_args()

    steps = abs(args.steps)
    direction = args.direction
    if direction is None:
        direction = "CW" if args.steps > 0 else "CCW"
    set_direction(direction == "CW")
    enable_motor()
    do_steps(steps, args.step_delay)
    disable_motor()
    print(
        f"Moved {steps} steps {'clockwise' if direction == 'CW' else 'counterclockwise'}."
    )


if __name__ == "__main__":
    main()
