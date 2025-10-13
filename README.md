# PlevelAI - Pan/Tilt Laser Weeder Module

PlevelAI turns a Jetson-powered camera feed into commands for a pan/tilt laser head. It detects weeds with YOLO, projects detections onto the ground plane, solves pan/tilt angles, and streams motion commands to an Arduino Nano R4 that drives the steppers (and soon, the laser gate).

## What it does today
- Captures CSI or USB camera frames and runs a YOLO detector (`yolo_log_and_stream.py`).
- Logs detections, projects them through the calibrated homography, and prioritises a target queue (`apps/weeder_runtime`).
- Solves pan/tilt angles with the kinematics helpers and emits JSON commands over USB serial (`control/host`).
- Offers a minimal dashboard with video, status, and event feed (`dashboard`).

## Hardware snapshot
- Jetson (Orin/NX class) or Linux laptop for inference + runtime.
- CSI or USB camera aimed at the weeding zone.
- Pan/tilt head driven by two NEMA 17 steppers.
- Arduino Nano R4 WiFi (or compatible) receiving serial commands and translating degrees -> step pulses.

## Software pipeline at a glance
1. YOLO inference produces detections and MJPEG stream (`make run` or `./launch`).
2. Detections are logged to `detections.log`.
3. `apps.weeder_runtime.runtime` tails the log, filters duplicates, and solves pan/tilt angles via `kinematics.pan_tilt`.
4. The runtime sends `{ "cmd": "move", "joints": {"pan": theta, "tilt": phi}, ... }` over USB serial.
5. (Optional) Dashboard server exposes `/video`, `/api/status`, and `/api/events` for monitoring.

## Repository layout
- `apps/` - entry points (`yolo_live`, `weeder_runtime`).
- `configs/` - robot and calibration configuration (`robot.yaml`).
- `control/` - host serial bridge plus Arduino Nano R4 starter firmware.
- `dashboard/` - FastAPI backend + simple JS frontend for monitoring.
- `docs/` - architecture and calibration notes.
- `kinematics/` - pan/tilt inverse kinematics helpers.
- `scripts/` - launch wrappers, installers, TRT exporter.
- `vision/` - calibration utilities and model helpers.
- `yolo_log_and_stream.py`, `yolo_to_log.py` - detection and logging utilities.

## Requirements
**Hardware:** Jetson running JetPack 6.x (preferred) or a Linux machine with CUDA/GPU, CSI or USB camera, and the pan/tilt rig connected to an Arduino Nano R4 over USB.

**Software:** Python 3.8+, OpenCV, NumPy, `ultralytics`, FastAPI (for the dashboard), plus JetPack system dependencies. `scripts/quickstart.sh` will bootstrap the minimum packages on a Jetson.

## Quickstart (Jetson)
```bash
git clone https://github.com/Barneyrabble/plevelai.git
cd plevelai
# Place or symlink YOLO weights (PT/engine) at vision/models/best.pt
./launch
```

The launcher prints the video URL (default `http://<host>:8080/video`) and writes detections to `~/plevelai/detections.log`. By default, it expects a CSI camera (`SENSOR_ID=0`) and runs the runtime against `configs/robot.yaml`.

### Useful launch variations
```bash
MODEL=/path/to/best.pt ./launch                 # override model path
CAM=usb USB_INDEX=0 ./launch                    # use USB camera
DRY_RUN=1 ./launch                              # run runtime without serial writes
SERIAL_PORT=/dev/ttyACM0 BAUDRATE=115200 ./launch
SKIP_HOME=1 ./launch                            # bypass automatic homing
HOME_ONCE=1 ./launch                            # force a home cycle once
PORT=9090 ./launch                              # change MJPEG/HTTP port
```

## YOLO viewer only
The legacy quickstart still works if you just want a window on the Jetson:
```bash
./scripts/quickstart.sh            # CSI camera, shows window on :0
SHOW=0 ./scripts/quickstart.sh     # headless
CAM=usb USB_INDEX=1 ./scripts/quickstart.sh
```

## Runtime / IK loop on its own
You can run the runtime in a separate shell for debugging:
```bash
python -m apps.weeder_runtime.runtime --config configs/robot.yaml --log detections.log --dry-run --verbose
python -m apps.weeder_runtime.runtime --serial-port /dev/ttyACM0
```

## Dashboard (optional)
```bash
./dashboard/start_server.sh
# Opens FastAPI on http://localhost:8000 with MJPEG stream at /video
```

The backend launches YOLO + IK internally using the same defaults as `./launch`, and the frontend displays status/events in the browser.

## Configuration and calibration
- `configs/robot.yaml` - fill in pan/tilt geometry, joint limits, homing, serial port/baud rate, and queue thresholds.
- `vision/calibration/` - store the homography (`H_img_to_ground.npy`) and calibration notes.
- `docs/IK_PIPELINE.md` - IK + control walkthrough and required measurements.
- `docs/PLEVELAI_OVERVIEW.md` - mission overview and bring-up checklist.

Update these files before running against hardware to ensure the runtime projects to the correct ground coordinates and respects the mechanical limits.

## Next milestones
- Flesh out the Arduino Nano R4 firmware with motion planning and safety interlocks.
- Integrate laser gating once hardware is ready.
- Harden the dashboard for remote operation and telemetry logging.

If you hit issues, start with `DRY_RUN=1 ./launch` (no serial) and inspect `detections.log` and `telemetry.csv` (when enabled) to confirm the pipeline is producing reasonable pan/tilt targets.
