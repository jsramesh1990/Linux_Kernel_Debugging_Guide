#!/bin/bash
# Complete build and debug workflow for Rock 3

set -e

PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
OUTPUT_DIR="$PROJECT_ROOT/output"
TRACE_DIR="$PROJECT_ROOT/traces"

echo "=== Rock 3 Debug Project Build & Test ==="

# 1. Build Kernel
echo "Building Kernel..."
cd "$PROJECT_ROOT/src/kernel"
make rock3_defconfig
make -j$(nproc) Image dtbs modules

# Install to output
cp arch/arm64/boot/Image "$OUTPUT_DIR/kernel/"
cp arch/arm64/boot/dts/rockchip/*.dtb "$OUTPUT_DIR/kernel/"
make modules_install INSTALL_MOD_PATH="$OUTPUT_DIR/modules"

# 2. Build Custom Module (if present)
if [ -d "$PROJECT_ROOT/src/modules" ]; then
    echo "Building custom modules..."
    cd "$PROJECT_ROOT/src/modules"
    make -C "$PROJECT_ROOT/src/kernel" M=$(pwd) modules
    make -C "$PROJECT_ROOT/src/kernel" M=$(pwd) modules_install \
        INSTALL_MOD_PATH="$OUTPUT_DIR/modules"
fi

# 3. Build User Application
if [ -d "$PROJECT_ROOT/src/applications" ]; then
    echo "Building user application..."
    cd "$PROJECT_ROOT/src/applications"
    mkdir -p build && cd build
    cmake ..
    make -j$(nproc)
    cp ./your_app "$OUTPUT_DIR/apps/"
fi

# 4. Verify Build
echo "Verifying kernel image..."
file "$OUTPUT_DIR/kernel/Image"

# 5. Run Performance Test with perf
echo "Running DDR performance test..."
perf stat -a -e rockchip_ddr/cycles/,\
    rockchip_ddr/bytes/ sleep 5 \
    > "$TRACE_DIR/perf/ddr-test.txt" 2>&1

# 6. Capture system state with dmesg
echo "Capturing dmesg..."
dmesg > "$TRACE_DIR/dmesg/system-state.txt"

# 7. Run trace if specified
if [ "$1" == "--trace" ]; then
    echo "Recording kernel trace..."
    sudo trace-cmd record -p function_graph -e sched_switch sleep 5
    sudo trace-cmd extract -o "$TRACE_DIR/ftrace/trace.dat"
    echo "Trace saved to $TRACE_DIR/ftrace/trace.dat"
fi

echo "=== Build and Test Complete ==="
echo "Check output at: $OUTPUT_DIR"
echo "Check traces at: $TRACE_DIR"
