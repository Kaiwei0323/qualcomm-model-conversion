#!/usr/bin/env bash
set -euo pipefail

# Host workflow (outside Docker)
#   1. bash download.sh
#      (downloads models/, encodings/ and sdks, unzips SDKs, then removes the zip files)
#   2. docker build -t qualcomm-model-conversion .
#
# To use host folders without rebuilding the image:
#   docker run --rm -it -v "$(pwd)":/app -w /app qualcomm-model-conversion bash

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "${ROOT}/models" "${ROOT}/sdks" "${ROOT}/encodings"

NDK_ZIP="${ROOT}/sdks/android-ndk-r26c-linux.zip"
SNPE_ZIP="${ROOT}/sdks/v2.22.6.240515.zip"

echo "Downloading model..."
wget -c "https://www.inventecna.com/files/models/detection/yolov8/yolov8s_opset10.onnx" \
  -O "${ROOT}/models/yolov8s_opset10.onnx"

wget -c "https://www.inventecna.com/files/models/detection/detr/detr_resnet101.onnx" \
  -O "${ROOT}/models/detr_resnet101.onnx"

echo "Downloading Android NDK (zip)..."
wget -c "https://www.inventecna.com/files/sdks/android/android-ndk-r26c-linux.zip" \
  -O "${NDK_ZIP}"

echo "Downloading SNPE SDK (zip)..."
wget -c "https://www.inventecna.com/files/sdks/snpe/v2.22.6.240515.zip" \
  -O "${SNPE_ZIP}"

echo "Downloading encodings..."
wget -c "https://www.inventecna.com/files/models/detection/yolov8/yolo8_act.encodings" \
  -O "${ROOT}/encodings/yolo8_act.encodings"

echo "Extracting SDK zips into ${ROOT}/sdks/ ..."
unzip -o "${NDK_ZIP}" -d "${ROOT}/sdks"
unzip -o "${SNPE_ZIP}" -d "${ROOT}/sdks"

echo "Removing zip archives..."
rm -f "${NDK_ZIP}" "${SNPE_ZIP}"

echo "Done. Run: docker build -t qualcomm-model-conversion ."
