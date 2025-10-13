# Arduino Nano R4 Controller Skeleton

This folder contains a starting point for the PlevelAI actuator firmware. The sketch expects an Arduino Nano R4 WiFi that receives JSON commands over USB serial from the host runtime.

## Features Provided
- Homing routine for axes with normally-closed limit switches (skip automatically if a limit pin is set to `0xFF`).
- Command queue (FIFO) fed by `{"cmd":"move"}` JSON lines.
- Simple trapezoidal profile with configurable feed rates and step-per-degree scaling (defaults assume 6400 pulses/rev, i.e. ~17.78 steps/deg).
- Periodic telemetry burst (`{"status":...}`) so the host can monitor state.

## Wiring Notes
- Pan driver step pin → `PAN_STEP_PIN` (default `D2`).
- Pan driver dir pin → `PAN_DIR_PIN` (default `D3`).
- Tilt driver step pin → `TILT_STEP_PIN` (default `D5`).
- Tilt driver dir pin → `TILT_DIR_PIN` (default `D6`).
- Limit switches should pull the input low when the axis is at home; set the pin to `0xFF` if none are installed yet.
- Provide motor power from the external driver supply; the Nano only shares ground and the logic signals.

## Dependencies
Install these through the Arduino Library Manager:
- [ArduinoJson](https://arduinojson.org/) (tested with 6.21+)
- [AccelStepper](https://www.airspayce.com/mikem/arduino/AccelStepper/) if you prefer to replace the minimal step generator included here.

## Building
1. Open `nano_r4.ino` in the Arduino IDE (2.x) or compile via `arduino-cli`:
   ```bash
   arduino-cli compile --fqbn arduino:renesas_uno:unor4wifi control/arduino/nano_r4
   arduino-cli upload --fqbn arduino:renesas_uno:unor4wifi --port /dev/ttyACM0 control/arduino/nano_r4
   ```
2. Monitor the serial console at 115200 baud to view telemetry.

## Next Steps
- Replace the placeholder motion planner with your preferred stepper driver (TMC, A4988, etc.).
- Integrate laser gating once the hardware interlocks are ready.
- Extend telemetry with driver current, limit states, and laser watchdog feedback.
