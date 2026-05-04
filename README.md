# Qualcomm model conversion (SNPE + Docker)

Convert a YOLOv8 ONNX model to SNPE DLC inside Docker, with your project folder synced to the container.

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Windows)
- [Git for Windows](https://git-scm.com/download/win) (includes **Git Bash**) or **WSL**, to run `download.sh`
- **`wget`** and **`unzip`** available in that shell (Git Bash includes them)

## 1. Download assets on the host

From the repository root:

```bash
bash download.sh
```

This fills **`models/`**, **`encodings/`**, and **`sdks/`** (Android NDK + SNPE zips are downloaded, extracted, and the zip files are removed).

## 2. Build the image

```bash
docker compose build
```

There is **no** `-d` flag on **`build`**. (`-d` is used with **`up`** for detached mode.)

To build and start the stack in the background in one step:

```bash
docker compose up -d --build
```

## 3. Open a shell in the container

**Option A — container already running** (e.g. after `docker compose up -d`):

```bash
docker compose exec app bash
```

**Option B — one-off shell** (no need to run `up` first):

```bash
docker compose run --rm app bash
```

Your repo is mounted at **`/app`**; files you create under **`/app`** appear in this directory on Windows.

## 4. Inside the container: ONNX → DLC

Create an output folder (once):

```bash
mkdir -p dlcs
```

### YOLOv8

Inspect an existing DLC (optional):

```bash
snpe-dlc-info -i dlcs/yolov8s_fp32.dlc
```

Convert ONNX to DLC with quantization encodings:

```bash
snpe-onnx-to-dlc \
  --input_network models/yolov8s_opset10.onnx \
  --quantization_overrides encodings/yolo8_act.encodings \
  --output_path dlcs/yolov8s_fp32.dlc
```

Inspect the result:

```bash
snpe-dlc-info -i dlcs/yolov8s_fp32.dlc
```

Use the same **`dlcs/...`** path in both commands so the file you write is the one you inspect.

### DETR ResNet101

Convert **`models/detr_resnet101.onnx`** to float DLC (no **`--quantization_overrides`** in this flow):

```bash
snpe-onnx-to-dlc \
  --input_network models/detr_resnet101.onnx \
  --output_path dlcs/detr_resnet101_fp32.dlc
```

Inspect the result:

```bash
snpe-dlc-info -i dlcs/detr_resnet101_fp32.dlc
```

## 5. Calibration data and INT8 quantization (optional)

Put calibration images under **`test_img/`** (create the folder if needed). The **`create_*`** scripts ship with the SNPE SDK (Inception v3 example); **`-s`** sets the square side length of the generated **`.raw`** tensors.

### YOLOv8

After you have a float DLC (**`dlcs/yolov8s_fp32.dlc`**), you can quantize to INT8 using a small set of representative images.

1. Build square resized images / raw assets and a file list at **`640×640`**, then run **`snpe-dlc-quantize`**:

```bash
mkdir -p output_img_640

python3 ${SNPE_ROOT}/examples/Models/InceptionV3/scripts/create_inceptionv3_raws.py \
  -s 640 -i test_img/ -d output_img_640

python3 ${SNPE_ROOT}/examples/Models/InceptionV3/scripts/create_file_list.py \
  -i output_img_640 -o output_img_640/image_file_list.txt -e '*.raw'

snpe-dlc-quantize \
  --input_dlc dlcs/yolov8s_fp32.dlc \
  --override_params \
  --input_list output_img_640/image_file_list.txt \
  --output_dlc dlcs/yolov8s_int8.dlc
```

Ensure **`output_img_640`** exists before the first script runs (**`mkdir -p output_img_640`**).

Inspect the quantized DLC:

```bash
snpe-dlc-info -i dlcs/yolov8s_int8.dlc
```

### DETR ResNet101

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

## Command cheat sheet

| Goal | Command |
|------|--------|
| Download data + SDKs | `bash download.sh` |
| Build image | `docker compose build` |
| Run service in background | `docker compose up -d` |
| Shell (service running) | `docker compose exec app bash` |
| Shell (temporary container) | `docker compose run --rm app bash` |
| Float DLC → INT8 DLC | `snpe-dlc-quantize ...` (see section 5: YOLOv8 or DETR ResNet101) |

## Notes

- **`docker compose exec app bash`** only works if the **`app`** service is **running**. Start it with **`docker compose up -d`** or use **`docker compose run --rm app bash`** instead.
- If **`snpe-onnx-to-dlc`** fails with NumPy / ONNX Runtime errors, rebuild the image after **`setup_env.sh`** changes (`docker compose build --no-cache`).
