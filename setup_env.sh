#!/bin/bash

# Exit on any error
set -e

echo "Starting environment setup..."

# Export SNPE_ROOT
echo "SNPE_ROOT is set to: ${SNPE_ROOT}"

# Check Python dependencies
echo "Checking Python dependencies..."
"${SNPE_ROOT}/bin/check-python-dependency" || { echo "Python dependency check failed."; exit 1; }

# Check Linux dependencies
echo "Checking Linux dependencies..."
bash "${SNPE_ROOT}/bin/check-linux-dependency.sh" || { echo "Linux dependency check failed."; exit 1; }

# make is installed in the Dockerfile; add package installs here if tools are missing at runtime

# Export ANDROID_NDK_ROOT
export PATH="${ANDROID_NDK_ROOT}:${PATH}"
echo "ANDROID_NDK_ROOT is set to: ${ANDROID_NDK_ROOT}"

# Check SNPE environment
echo "Checking SNPE environment setup..."
"${SNPE_ROOT}/bin/envcheck" -c || { echo "SNPE environment check failed."; exit 1; }

# Install Python packages (onnxruntime 1.17.x wheels need NumPy 1.x; NumPy 2 breaks ORT with _ARRAY_API)
echo "Installing required Python packages..."
python3 -m pip install --no-cache-dir "numpy>=1.26.0,<2" \
    || { echo "Failed to install NumPy."; exit 1; }
python3 -m pip install --no-cache-dir onnx==1.12.0 onnxruntime==1.17.1 onnxsim \
    || { echo "Failed to install ONNX tools."; exit 1; }
python3 -m pip install --no-cache-dir ultralytics flask \
    || { echo "Failed to install ultralytics."; exit 1; }
python3 -m pip install --no-cache-dir "numpy>=1.26.0,<2" \
    || { echo "Failed to re-pin NumPy."; exit 1; }

# Source SNPE environment setup
echo "Sourcing SNPE environment setup..."
# shellcheck source=/dev/null
source "${SNPE_ROOT}/bin/envsetup.sh" || { echo "Failed to source SNPE environment."; exit 1; }

echo "Environment setup completed successfully."
