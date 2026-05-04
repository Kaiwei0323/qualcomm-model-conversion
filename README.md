# Qualcomm model conversion (SNPE + Docker)

Convert ONNX model to SNPE DLC inside Docker

## Dependencies

- SNPE SDK: v2.22.6.240515
- Android NDK: android-ndk-r26c-linux

## 1. Download assets on the host

From the repository root:

```bash
bash download.sh
```

This will download Android NDK, SNPE SDK, Yolov8, detr, and encoding file check **`models/`**, **`encodings/`**, and **`sdks/`**.

## 2. Build the image

```bash
docker compose up -d --build
```

This will take around 10 mins.

## 3. Open a shell in the container

```bash
docker compose exec app bash
```

This directory is mounted at **`/app`**; files you create under **`/app`** appear in this directory.

## 4. Inside the container: ONNX → DLC

Create an output folder:

```bash
mkdir -p dlcs
```

### YOLOv8

Inspect an existing DLC (optional):

```bash
snpe-dlc-info -i dlcs/yolov8s_fp32.dlc
```

Yolov8 workflow

Convert ONNX to DLC with quantization encodings:

```bash
snpe-onnx-to-dlc \
  --input_network models/yolov8s_opset10.onnx \
  --quantization_overrides encodings/yolo8_act.encodings \
  --output_path dlcs/yolov8s_fp32.dlc
```

Quantize yolov8 fp32 model to int8
1. prepare calibrate image
1. Build square resized images / raw assets and a file list at **`640×640`**, then run **`snpe-dlc-quantize`**:

```bash
mkdir -p output_img_640

python3 ${SNPE_ROOT}/examples/Models/InceptionV3/scripts/create_inceptionv3_raws.py \
  -s 640 -i test_img/ -d output_img_640

python3 ${SNPE_ROOT}/examples/Models/InceptionV3/scripts/create_file_list.py \
  -i output_img_640 -o output_img_640/image_file_list.txt -e '*.raw'

```
run quantization
```bash
snpe-dlc-quantize \
  --input_dlc dlcs/yolov8s_fp32.dlc \
  --override_params \
  --input_list output_img_640/image_file_list.txt \
  --output_dlc dlcs/yolov8s_int8.dlc
```

Inspect the quantized DLC:

```bash
snpe-dlc-info -i dlcs/yolov8s_int8.dlc
```

### DETR ResNet101

Convert **`models/detr_resnet101.onnx`** to float DLC (no **`--quantization_overrides`** in this flow):

```bash
snpe-onnx-to-dlc \
  --input_network models/detr_resnet101.onnx \
  --output_path dlcs/detr_resnet101_fp32.dlc
```

After you have **`dlcs/detr_resnet101_fp32.dlc`**, build calibration raws at **`480×480`** (match **`-s 480`** to your model’s expected input size), then quantize:

```bash
mkdir -p output_img_480

python3 ${SNPE_ROOT}/examples/Models/InceptionV3/scripts/create_inceptionv3_raws.py \
  -s 480 -i test_img/ -d output_img_480

python3 ${SNPE_ROOT}/examples/Models/InceptionV3/scripts/create_file_list.py \
  -i output_img_480 -o output_img_480/image_file_list.txt -e '*.raw'

snpe-dlc-quantize \
  --input_dlc dlcs/detr_resnet101_fp32.dlc \
  --input_list output_img_480/image_file_list.txt \
  --output_dlc dlcs/detr_resnet101_int8.dlc
```

Inspect the quantized DLC:

```bash
snpe-dlc-info -i dlcs/detr_resnet101_int8.dlc
```

