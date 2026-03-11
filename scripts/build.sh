#!/bin/bash
set -e

ANDROID_VERSION="${1:-android13}"
KERNEL_VERSION="${2:-5.15}"
DEVICE="${3:-sm8550}"

echo "Building kernel for $DEVICE ($ANDROID_VERSION-$KERNEL_VERSION)"

if [ -z "$ANDROID_VERSION" ] || [ -z "$KERNEL_VERSION" ]; then
    echo "Usage: $0 <android_version> <kernel_version> <device>"
    echo "Example: $0 android13 15 sm8550"
    exit 1
fi

export LLVM=1
export LLVM_IAS=1
export CC=clang
export CXX=clang++

if command -v sccache &> /dev/null; then
    export SCCACHE=1
fi

cd "$(dirname "$0")/../sm8550"

make ARCH=arm64 O=out gki_defconfig vendor/kalama_GKI.config vendor/oplus/kalama_GKI.config vendor/debugfs.config

make -j$(nproc) ARCH=arm64 O=out Image
