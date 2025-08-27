# PlevelAI — MVP (Jetson camera → laser weeder)

Repo layout:
- vision/ — camera, calibration, detection
- kinematics/ — inverse kinematics
- control/ — Teensy firmware + host control (steppers + laser)
- apps/ — runnable apps (today: YOLO live)
- configs/ — camera & runtime configs
- scripts/ — install & export helpers
- docs/ — setup, calibration, architecture

Start with the MVP app in `apps/yolo_live`.

## Quickstart (Jetson)
```bash
git clone https://github.com/Barneyrabble/plevelai.git
cd plevelai
# put/copy/symlink your weights to vision/models/best.pt  (or store at /ssd/yolo/best_1.pt)
./scripts/quickstart.sh    # opens a live window on the Jetson monitor
```

**Common variations**
```bash
SHOW=0 ./scripts/quickstart.sh              # headless, no window
CAM=usb USB_INDEX=0 ./scripts/quickstart.sh # USB webcam instead of CSI
RESTART_ARGUS=1 ./scripts/quickstart.sh     # if CSI was busy earlier
make run                                    # same as quickstart (CSI)
make usb                                    # USB webcam run
```

