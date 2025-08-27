#!/usr/bin/env bash
set -euo pipefail

MODEL_DEFAULT="../../vision/models/best.pt"
W="${W:-1280}"; H="${H:-720}"; FPS="${FPS:-30}"
IMGSZ="${IMGSZ:-640}"; CONF="${CONF:-0.25}"
SHOW=0; CSI=1; USB_INDEX=0; RESTART_ARGUS=0
OUT="${OUT:-}"

usage(){ cat <<USG
Usage:
  ./run_yolo_live.sh [MODEL_PATH] [--csi] [--usb INDEX] [--show] [--out FILE] [--restart-argus]
Env overrides: W,H,FPS, IMGSZ, CONF, OUT
USG
}

MODEL="${1:-$MODEL_DEFAULT}"; shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --csi) CSI=1 ;;
    --usb) CSI=0; USB_INDEX="${2:-0}"; shift ;;
    --show) SHOW=1 ;;
    --out) OUT="${2:-}"; shift ;;
    --restart-argus) RESTART_ARGUS=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 2 ;;
  esac; shift || true
done

if ! command -v python3 >/dev/null 2>&1; then echo "❌ python3 not found"; exit 1; fi
if ! python3 - <<'PY' >/dev/null 2>&1; then
import sys
try: import ultralytics, cv2, numpy
except: sys.exit(1)
PY
then echo "❌ Missing deps (ultralytics, opencv, numpy). Run scripts/install_jp62_min.sh"; exit 1; fi

if [[ "$CSI" -eq 1 && "$RESTART_ARGUS" -eq 1 ]]; then
  if [[ -t 0 ]]; then sudo systemctl restart nvargus-daemon || true; else echo "ℹ️ no TTY; skip Argus restart"; fi
fi

if [[ "$SHOW" -eq 1 ]]; then
  export DISPLAY="${DISPLAY:-:0}"; command -v xhost >/dev/null 2>&1 && xhost +SI:localuser:"$USER" >/dev/null 2>&1 || true
  [[ -z "${DISPLAY:-}" ]] && echo "⚠️ no DISPLAY; running headless" && SHOW=0
fi

python3 - <<PY
import os, sys, time, cv2
from ultralytics import YOLO

model_path = "${MODEL}"
if not os.path.exists(model_path): sys.exit(f"❌ Model not found: {model_path}")
if model_path.endswith(".pt"):
    eng = os.path.splitext(model_path)[0] + ".engine"
    if os.path.exists(eng):
        print(f"🔁 Using engine: {eng}"); model_path = eng

W,H,FPS = int("${W}"), int("${H}"), int("${FPS}")
IMGSZ,CONF = int("${IMGSZ}"), float("${CONF}")
SHOW,CSI,USB = ${SHOW}, ${CSI}, int("${USB_INDEX}")
OUT = "${OUT}"

m = YOLO(model_path)
if CSI:
    gst = ("nvarguscamerasrc ! "
           f"video/x-raw(memory:NVMM), width={W}, height={H}, framerate={FPS}/1 ! "
           "nvvidconv ! video/x-raw, format=BGRx ! videoconvert ! video/x-raw, format=BGR ! appsink")
    cap = cv2.VideoCapture(gst, cv2.CAP_GSTREAMER)
else:
    cap = cv2.VideoCapture(USB)
    cap.set(cv2.CAP_PROP_FRAME_WIDTH,W); cap.set(cv2.CAP_PROP_FRAME_HEIGHT,H); cap.set(cv2.CAP_PROP_FPS,FPS)
if not cap.isOpened(): sys.exit("❌ Failed to open camera")

writer=None
if OUT:
    fourcc=cv2.VideoWriter_fourcc(*'mp4v'); os.makedirs(os.path.dirname(OUT) or ".", exist_ok=True)
    writer=cv2.VideoWriter(OUT,fourcc,float(FPS),(W,H)); print("→ saving to",OUT)

win="YOLO Camera (q to quit)"
if SHOW:
    try: cv2.namedWindow(win,cv2.WINDOW_NORMAL); cv2.resizeWindow(win,W,H)
    except: SHOW=0; print("⚠️ could not create window; headless")

t0=time.time(); n=0
try:
    while True:
        ok,frame=cap.read()
        if not ok: print("⚠️ empty frame"); break
        r=m.predict(source=frame,device=0,imgsz=IMGSZ,conf=CONF,verbose=False)
        out=r[0].plot()
        if writer: writer.write(out)
        if SHOW:
            cv2.imshow(win,out)
            if (cv2.waitKey(1)&0xFF)==ord('q'): break
        n+=1
finally:
    cap.release()
    writer and writer.release()
    SHOW and cv2.destroyAllWindows()
dt=time.time()-t0
print(f"✅ Done. Frames={n}, Avg FPS={n/dt:.2f}" if dt>0 and n>0 else "✅ Done.")
PY
