#!/bin/bash
set -e

IMAGE_PATH="${1:-sm8550/out/arch/arm64/boot/Image}"

echo "Validating kernel build output..."

if [ ! -f "$IMAGE_PATH" ]; then
    echo "Error: Image not found at $IMAGE_PATH"
    exit 1
fi

SIZE=$(stat -c%s "$IMAGE_PATH")
echo "Image size: $SIZE bytes"

if [ $SIZE -lt 10000000 ]; then
    echo "Warning: Image size seems too small"
    exit 1
fi

echo "Validating Image header..."
if xxd -l 32 "$IMAGE_PATH" | grep -q "MZ"; then
    echo "Error: Image is a PE/COFF file, not a kernel"
    exit 1
fi

FILE_INFO=$(file "$IMAGE_PATH")
echo "File type: $FILE_INFO"

echo "Build validation passed!"
