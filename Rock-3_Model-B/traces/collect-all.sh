#!/bin/bash
# ============================================
# Collect All Traces Script
# ============================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create directories
mkdir -p "$SCRIPT_DIR/dmesg"
mkdir -p "$SCRIPT_DIR/ftrace"
mkdir -p "$SCRIPT_DIR/perf"
mkdir -p "$SCRIPT_DIR/strace"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Collecting All Traces${NC}"
echo -e "${GREEN}  Timestamp: $TIMESTAMP${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 1. Collect dmesg
echo -e "${BLUE}1. Collecting dmesg...${NC}"
dmesg > "$SCRIPT_DIR/dmesg/current_${TIMESTAMP}.log"
dmesg -H -L -T > "$SCRIPT_DIR/dmesg/human_${TIMESTAMP}.log"
echo -e "${GREEN}✓ dmesg collected${NC}"

# 2. Collect system info
echo -e "${BLUE}2. Collecting system info...${NC}"
uname -a > "$SCRIPT_DIR/system_info_${TIMESTAMP}.txt"
cat /proc/cpuinfo > "$SCRIPT_DIR/cpuinfo_${TIMESTAMP}.txt"
cat /proc/meminfo > "$SCRIPT_DIR/meminfo_${TIMESTAMP}.txt"
uptime > "$SCRIPT_DIR/uptime_${TIMESTAMP}.txt"
echo -e "${GREEN}✓ System info collected${NC}"

# 3. Collect perf data (if available)
echo -e "${BLUE}3. Collecting perf data...${NC}"
if command -v perf &> /dev/null; then
    # CPU profiling
    perf record -a -g -F 99 -o "$SCRIPT_DIR/perf/cpu_${TIMESTAMP}.data" sleep 5 2>/dev/null
    perf script -i "$SCRIPT_DIR/perf/cpu_${TIMESTAMP}.data" > "$SCRIPT_DIR/perf/cpu_${TIMESTAMP}.txt" 2>/dev/null
    
    # DDR monitoring (if available)
    if perf list 2>/dev/null | grep -q rockchip_ddr; then
        perf stat -a -e rockchip_ddr/bytes/,rockchip_ddr/read-bytes/,rockchip_ddr/write-bytes/ sleep 5 > "$SCRIPT_DIR/perf/ddr_${TIMESTAMP}.txt" 2>&1
    fi
    echo -e "${GREEN}✓ Perf data collected${NC}"
else
    echo -e "${YELLOW}⚠ perf not available${NC}"
fi

# 4. Collect ftrace (if available)
echo -e "${BLUE}4. Collecting ftrace...${NC}"
if [ -d /sys/kernel/debug/tracing ]; then
    cp /sys/kernel/debug/tracing/trace "$SCRIPT_DIR/ftrace/trace_${TIMESTAMP}.txt" 2>/dev/null || true
    echo -e "${GREEN}✓ Ftrace collected${NC}"
else
    echo -e "${YELLOW}⚠ ftrace not available${NC}"
fi

# 5. Collect strace for common commands
echo -e "${BLUE}5. Collecting strace...${NC}"
if command -v strace &> /dev/null; then
    strace -f -o "$SCRIPT_DIR/strace/ls_${TIMESTAMP}.log" ls /tmp 2>/dev/null || true
    strace -f -o "$SCRIPT_DIR/strace/cat_${TIMESTAMP}.log" cat /proc/cpuinfo 2>/dev/null || true
    echo -e "${GREEN}✓ Strace collected${NC}"
else
    echo -e "${YELLOW}⚠ strace not available${NC}"
fi

# 6. Collect peripheral info
echo -e "${BLUE}6. Collecting peripheral info...${NC}"
if command -v i2cdetect &> /dev/null; then
    i2cdetect -l > "$SCRIPT_DIR/i2c_buses_${TIMESTAMP}.txt" 2>/dev/null || true
    i2cdetect -y 1 > "$SCRIPT_DIR/i2c_scan_${TIMESTAMP}.txt" 2>/dev/null || true
fi

if command -v lsusb &> /dev/null; then
    lsusb > "$SCRIPT_DIR/usb_${TIMESTAMP}.txt" 2>/dev/null
fi

if ip link show eth0 &> /dev/null; then
    ip link show eth0 > "$SCRIPT_DIR/network_${TIMESTAMP}.txt" 2>/dev/null
    if command -v ethtool &> /dev/null; then
        ethtool eth0 > "$SCRIPT_DIR/ethtool_${TIMESTAMP}.txt" 2>/dev/null
    fi
fi

# Temperature sensors
for zone in /sys/class/thermal/thermal_zone*; do
    if [ -f "$zone/temp" ]; then
        echo "$(basename $zone): $(($(cat $zone/temp)/1000))°C" >> "$SCRIPT_DIR/temperature_${TIMESTAMP}.txt"
    fi
done

echo -e "${GREEN}✓ Peripheral info collected${NC}"

# Summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Collection Complete${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Traces saved to: $SCRIPT_DIR${NC}"
echo "Files:"
ls -la "$SCRIPT_DIR"/*.txt 2>/dev/null
ls -la "$SCRIPT_DIR"/*.log 2>/dev/null
ls -la "$SCRIPT_DIR"/*.data 2>/dev/null
echo ""
echo -e "${GREEN}✅ All traces collected successfully${NC}"
