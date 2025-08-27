.PHONY: run headless usb trt

run:
	@CAM=csi SHOW=1 ./scripts/quickstart.sh

headless:
	@SHOW=0 ./scripts/quickstart.sh

usb:
	@CAM=usb USB_INDEX=0 SHOW=1 ./scripts/quickstart.sh

trt:
	@./scripts/export_trt.sh vision/models/best.pt
