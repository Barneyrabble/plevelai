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
