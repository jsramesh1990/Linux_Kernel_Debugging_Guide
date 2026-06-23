#!/bin/bash
# ============================================
# System Test Suite for Rock 3 Model B
# ============================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Function to print test result
print_result() {
    local test_name="$1"
    local result="$2"
    local message="$3"
    
    if [ "$result" == "PASS" ]; then
        echo -e "${GREEN}✓ PASS${NC} - $test_name: $message"
        ((TESTS_PASSED++))
    elif [ "$result" == "FAIL" ]; then
        echo -e "${RED}✗ FAIL${NC} - $test_name: $message"
        ((TESTS_FAILED++))
    else
        echo -e "${YELLOW}⚠ SKIP${NC} - $test_name: $message"
        ((TESTS_SKIPPED++))
    fi
}

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  System Test Suite for Rock 3        ${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Starting tests at $(date)"
echo ""

# ------------------------------------------------------------
# Test 1: Kernel Version
# ------------------------------------------------------------
echo -e "${BLUE}Test 1: Kernel Version${NC}"
echo "------------------------"

KERNEL_VERSION=$(uname -r)

if [ -n "$KERNEL_VERSION" ]; then
    print_result "Kernel Version" "PASS" "Linux $KERNEL_VERSION"
else
    print_result "Kernel Version" "FAIL" "Could not determine kernel version"
fi

echo ""

# ------------------------------------------------------------
# Test 2: Architecture
# ------------------------------------------------------------
echo -e "${BLUE}Test 2: Architecture${NC}"
echo "------------------------"

ARCH=$(uname -m)

if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    print_result "Architecture" "PASS" "ARM64 ($ARCH)"
elif [ "$ARCH" = "armv7l" ] || [ "$ARCH" = "armhf" ]; then
    print_result "Architecture" "PASS" "ARM32 ($ARCH) - Note: Rock 3 is ARM64"
else
    print_result "Architecture" "WARN" "Non-ARM architecture: $ARCH"
fi

echo ""

# ------------------------------------------------------------
# Test 3: CPU Cores
# ------------------------------------------------------------
echo -e "${BLUE}Test 3: CPU Cores${NC}"
echo "---------------------"

CPU_CORES=$(nproc 2>/dev/null || grep -c "^processor" /proc/cpuinfo)

if [ "$CPU_CORES" -gt 0 ]; then
    print_result "CPU Cores" "PASS" "Detected $CPU_CORES CPU cores"
else
    print_result "CPU Cores" "FAIL" "Could not detect CPU cores"
fi

echo ""

# ------------------------------------------------------------
# Test 4: Memory Size
# ------------------------------------------------------------
echo -e "${BLUE}Test 4: Memory Size${NC}"
echo "----------------------"

MEM_TOTAL=$(free -m | grep Mem | awk '{print $2}')

if [ "$MEM_TOTAL" -gt 0 ]; then
    print_result "Memory Size" "PASS" "Total RAM: ${MEM_TOTAL}MB"
else
    print_result "Memory Size" "FAIL" "Could not detect memory size"
fi

echo ""

# ------------------------------------------------------------
# Test 5: Root Filesystem
# ------------------------------------------------------------
echo -e "${BLUE}Test 5: Root Filesystem${NC}"
echo "--------------------------"

ROOT_DEV=$(df / | tail -1 | awk '{print $1}')
ROOT_SIZE=$(df -h / | tail -1 | awk '{print $2}')
ROOT_USED=$(df -h / | tail -1 | awk '{print $3}')
ROOT_USE=$(df / | tail -1 | awk '{print $5}')

if [ -n "$ROOT_DEV" ]; then
    print_result "Root Filesystem" "PASS" "$ROOT_DEV ($ROOT_SIZE, used: $ROOT_USED, $ROOT_USE)"
else
    print_result "Root Filesystem" "FAIL" "Could not detect root filesystem"
fi

echo ""

# ------------------------------------------------------------
# Test 6: Mounted Partitions
# ------------------------------------------------------------
echo -e "${BLUE}Test 6: Mounted Partitions${NC}"
echo "----------------------------"

PARTITIONS=$(mount | grep "^/dev" | wc -l)

if [ "$PARTITIONS" -gt 0 ]; then
    print_result "Mounted Partitions" "PASS" "Found $PARTITIONS mounted partition(s)"
    mount | grep "^/dev" | head -5 | awk '{print "  " $1 " on " $3 " type " $5}'
else
    print_result "Mounted Partitions" "WARN" "No partitions found"
fi

echo ""

# ------------------------------------------------------------
# Test 7: Systemd Status
# ------------------------------------------------------------
echo -e "${BLUE}Test 7: Systemd Status${NC}"
echo "------------------------"

if command -v systemctl &> /dev/null; then
    SYSTEMD_OK=$(systemctl status 2>/dev/null | head -1 | grep -q "State: running" && echo "yes" || echo "no")
    
    if [ "$SYSTEMD_OK" = "yes" ]; then
        print_result "Systemd Status" "PASS" "Systemd running"
    else
        print_result "Systemd Status" "WARN" "Systemd not running or not found"
    fi
else
    print_result "Systemd Status" "SKIP" "Systemd not installed"
fi

echo ""

# ------------------------------------------------------------
# Test 8: Running Processes
# ------------------------------------------------------------
echo -e "${BLUE}Test 8: Running Processes${NC}"
echo "--------------------------"

PROCESSES=$(ps aux 2>/dev/null | wc -l)

if [ "$PROCESSES" -gt 10 ]; then
    print_result "Running Processes" "PASS" "$PROCESSES processes running"
else
    print_result "Running Processes" "WARN" "Low process count: $PROCESSES"
fi

echo ""

# ------------------------------------------------------------
# Test 9: Load Average
# ------------------------------------------------------------
echo -e "${BLUE}Test 9: Load Average${NC}"
echo "----------------------"

LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1,$2,$3}')
LOAD_1=$(echo $LOAD | awk '{print $1}' | sed 's/,//')
LOAD_5=$(echo $LOAD | awk '{print $2}' | sed 's/,//')
LOAD_15=$(echo $LOAD | awk '{print $3}' | sed 's/,//')

if [ -n "$LOAD_1" ]; then
    print_result "Load Average" "PASS" "$LOAD_1, $LOAD_5, $LOAD_15"
else
    print_result "Load Average" "FAIL" "Could not get load average"
fi

echo ""

# ------------------------------------------------------------
# Test 10: Swap Usage
# ------------------------------------------------------------
echo -e "${BLUE}Test 10: Swap Usage${NC}"
echo "---------------------"

SWAP_TOTAL=$(free -m | grep Swap | awk '{print $2}')
SWAP_USED=$(free -m | grep Swap | awk '{print $3}')

if [ "$SWAP_TOTAL" -gt 0 ]; then
    SWAP_PERCENT=$((SWAP_USED * 100 / SWAP_TOTAL))
    print_result "Swap Usage" "PASS" "Total: ${SWAP_TOTAL}MB, Used: ${SWAP_USED}MB (${SWAP_PERCENT}%)"
else
    print_result "Swap Usage" "SKIP" "No swap configured"
fi

echo ""

# ------------------------------------------------------------
# Test 11: Hostname
# ------------------------------------------------------------
echo -e "${BLUE}Test 11: Hostname${NC}"
echo "---------------------"

HOSTNAME=$(hostname 2>/dev/null)

if [ -n "$HOSTNAME" ]; then
    print_result "Hostname" "PASS" "$HOSTNAME"
else
    print_result "Hostname" "FAIL" "Could not get hostname"
fi

echo ""

# ------------------------------------------------------------
# Test 12: Uptime
# ------------------------------------------------------------
echo -e "${BLUE}Test 12: Uptime${NC}"
echo "------------------"

UPTIME_RAW=$(cat /proc/uptime | awk '{print $1}')
UPTIME_DAYS=$((UPTIME_RAW / 86400))
UPTIME_HOURS=$(( (UPTIME_RAW % 86400) / 3600 ))
UPTIME_MINS=$(( (UPTIME_RAW % 3600) / 60 ))

if [ -n "$UPTIME_RAW" ]; then
    print_result "Uptime" "PASS" "${UPTIME_DAYS}d ${UPTIME_HOURS}h ${UPTIME_MINS}m"
else
    print_result "Uptime" "FAIL" "Could not get uptime"
fi

echo ""

# ------------------------------------------------------------
# Test 13: DNS Resolution
# ------------------------------------------------------------
echo -e "${BLUE}Test 13: DNS Resolution${NC}"
echo "------------------------"

if command -v ping &> /dev/null; then
    if ping -c 1 -W 2 google.com 2>/dev/null >/dev/null; then
        print_result "DNS Resolution" "PASS" "DNS working"
    else
        print_result "DNS Resolution" "FAIL" "DNS resolution failed"
    fi
else
    print_result "DNS Resolution" "SKIP" "ping not available"
fi

echo ""

# ------------------------------------------------------------
# Test 14: Date/Time
# ------------------------------------------------------------
echo -e "${BLUE}Test 14: Date/Time${NC}"
echo "---------------------"

CURRENT_TIME=$(date "+%Y-%m-%d %H:%M:%S")
CURRENT_UTC=$(date -u "+%Y-%m-%d %H:%M:%S")

if [ -n "$CURRENT_TIME" ]; then
    print_result "Date/Time" "PASS" "Local: $CURRENT_TIME, UTC: $CURRENT_UTC"
else
    print_result "Date/Time" "FAIL" "Could not get date/time"
fi

echo ""

# ------------------------------------------------------------
# Test Summary
# ------------------------------------------------------------
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Test Summary${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Passed: ${TESTS_PASSED}${NC}"
echo -e "${RED}Failed: ${TESTS_FAILED}${NC}"
echo -e "${YELLOW}Skipped: ${TESTS_SKIPPED}${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All system tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some system tests failed!${NC}"
    exit 1
fi
