#!/bin/bash
# Build Rock 3 project inside Docker

docker build -t rock3-builder docker/

docker run --rm \
    -v $(pwd)/src:/workspace/src \
    -v $(pwd)/output:/workspace/output \
    -v $(pwd)/scripts:/workspace/scripts \
    --privileged \
    rock3-builder \
    bash -c "
        cd /workspace/src/kernel
        make rock3_defconfig
        make -j\$(nproc) Image dtbs
        cp arch/arm64/boot/Image /workspace/output/kernel/
    "
