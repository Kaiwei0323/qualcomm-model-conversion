# Use Ubuntu 22.04 as the base image
#
# Expected host workflow (SDKs and data are not downloaded inside this file):
#   1. On the host:  bash download.sh
#      (populates models/, encodings/, and sdks/ with NDK + SNPE extracted; zips removed after unzip)
#   2. docker build -t qualcomm-model-conversion .
#      COPY below brings those folders into the image at /app
#
# Live sync with your PC (project folder ↔ container /app):
#   docker compose run --rm app bash
# or:
#   docker run --rm -it -v "${PWD}:/app" -w /app qualcomm-model-conversion:local bash
FROM ubuntu:22.04

# Set non-interactive mode to prevent tzdata prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Match layout after unzipping the two SDK archives into /app/sdks
# (SNPE zip extracts qairt/<version>/ under sdks/; NDK zip contains android-ndk-r27d/)
ENV SNPE_ROOT=/app/sdks/v2.22.6.240515/qairt/2.22.6.240515
ENV ANDROID_NDK_ROOT=/app/sdks/android-ndk-r26c-linux/android-ndk-r26c
# Set the working directory inside the container
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    sudo \
    python3.10 \
    python3-pip \
    python3.10-venv \
    libtinfo5 \
    wget \
    unzip \
    ca-certificates \
    make \
    && rm -rf /var/lib/apt/lists/*

# Project + pre-downloaded models/, encodings/, sdks/ (from download.sh on the host)
COPY . .

# sdks/ is not in git; without download.sh the COPY above has no SNPE tree and setup_env.sh fails obscurely
RUN test -f "${SNPE_ROOT}/bin/check-python-dependency" \
  || (echo "ERROR: SNPE SDK not found at ${SNPE_ROOT}. On the host, from the repo root run: bash download.sh" \
      && exit 1)

# Use `bash` so CRLF scripts still run; keep LF via .gitattributes (./setup_env.sh needs Unix shebang)
RUN bash setup_env.sh

# SNPE for every interactive bash shell
RUN echo "source ${SNPE_ROOT}/bin/envsetup.sh" >> /etc/bash.bashrc

# Non-interactive tools: export when running `docker run ... command`
ENV PATH="${SNPE_ROOT}/bin:${PATH}"
