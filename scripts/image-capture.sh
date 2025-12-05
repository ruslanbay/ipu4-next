RESOLUTION=4096x3072
FMT=Y10_1X10
VFMT=SGBRG10
FRAME_NUM=30
WIDTH=$(echo ${RESOLUTION} | awk -F 'x' '{print $1}')
HEIGHT=$(echo ${RESOLUTION} | awk -F 'x' '{print $2}')

media-ctl -r
media-ctl -V "\"Intel IPU4 TPG 0\":0 [fmt:SBGGR8_1X8/${RESOLUTION}]"

media-ctl -V "\"Intel IPU4 CSI-2 0\":1 [fmt:$FMT/${RESOLUTION}]"
media-ctl -V "\"Intel IPU4 CSI2 BE SOC\":0 [fmt:$FMT/${RESOLUTION}]"
media-ctl -V "\"Intel IPU4 CSI2 BE SOC\":1 [fmt:$FMT/${RESOLUTION}]"

media-ctl -l "\"Intel IPU4 TPG 0\":0 -> \"Intel IPU4 CSI2 BE SOC\":0[4]"
media-ctl -l "\"Intel IPU4 CSI2 BE SOC\":8 -> \"Intel IPU4 BE SOC capture 0\":0[5]"

CAPTURE_DEV=$(media-ctl -e "Intel IPU4 BE SOC capture 0")

# Capture a single frame using yavta
yavta -c1 -n1 "${CAPTURE_DEV}" -I -s"${RESOLUTION}" -Fframe-single.bin -f "${VFMT}"
# Device /dev/video27 opened.
# Device `ipu4p' on `PCI:pci:intel-ipu' (driver 'intel-ipu4-isys') supports video, capture, without mplanes.
# Video format set: SGBRG10 (30314247) 4096x3072 (stride 8192) field none buffer size 25174016
# Video format: SGBRG10 (30314247) 4096x3072 (stride 8192) field none buffer size 25174016
# 1 buffers requested.
# length: 25174016 offset: 0 timestamp type/source: mono/EoF
# Buffer 0/0 mapped at address 0x7f5322bfe000.

# Capture an image using v4l2-ctl
v4l2-ctl -d "${CAPTURE_DEV}" --stream-mmap --stream-count=1 --stream-to=frame-single.bin