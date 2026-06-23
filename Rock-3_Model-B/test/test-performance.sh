#!/bin/bash
# ============================================
# Performance Test Suite for Rock 3 Model B
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
echo -e "${GREEN}  Performance Test Suite for Rock 3    ${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Starting tests at $(date)"
echo ""

# ------------------------------------------------------------
# Test 1: CPU Performance
# ------------------------------------------------------------
echo -e "${BLUE}Test 1: CPU Performance${NC}"
echo "---------------------------"

# Check if perf is available
if ! command -v perf &> /dev/null; then
    print_result "CPU Performance" "SKIP" "perf not installed"
else
    # Run CPU test
    CPU_RESULT=$(perf stat -e cycles,instructions,cache-misses sleep 1 2>&1)
    
    if echo "$CPU_RESULT" | grep -q "cycles"; then
        CYCLES=$(echo "$CPU_RESULT" | grep "cycles" | awk '{print $1}' | tr -d ',')
        INSTRUCTIONS=$(echo "$CPU_RESULT" | grep "instructions" | awk '{print $1}' | tr -d ',')
        
        if [ -n "$CYCLES" ] && [ -n "$INSTRUCTIONS" ]; then
            print_result "CPU Performance" "PASS" "Cycles: $CYCLES, Instructions: $INSTRUCTIONS"
        else
            print_result "CPU Performance" "FAIL" "Could not parse perf output"
        fi
    else
        print_result "CPU Performance" "FAIL" "Perf failed to run"
    fi
fi

echo ""

# ------------------------------------------------------------
# Test 2: DDR Performance (RK3568 Specific)
# ------------------------------------------------------------
echo -e "${BLUE}Test 2: DDR Performance${NC}"
echo "---------------------------"

if ! command -v perf &> /dev/null; then
    print_result "DDR Performance" "SKIP" "perf not installed"
else
    # Check if DDR events are available
    if perf list 2>/dev/null | grep -q "rockchip_ddr"; then
        DDR_RESULT=$(perf stat -a -e rockchip_ddr/bytes/ sleep 1 2>&1)
        
        if echo "$DDR_RESULT" | grep -q "rockchip_ddr/bytes/"; then
            BYTES=$(echo "$DDR_RESULT" | grep "rockchip_ddr/bytes/" | awk '{print $1}' | tr -d ',')
            if [ -n "$BYTES" ]; then
                MB=$((BYTES / 1024 / 1024))
                print_result "DDR Performance" "PASS" "Bandwidth: ${MB}MB in 1s"
            else
                print_result "DDR Performance" "FAIL" "Could not parse DDR bytes"
            fi
        else
            print_result "DDR Performance" "FAIL" "DDR events not available"
        fi
    else
        print_result "DDR Performance" "SKIP" "DDR PMU not available (not RK3568?)"
    fi
fi

echo ""

# ------------------------------------------------------------
# Test 3: Memory Performance
# ------------------------------------------------------------
echo -e "${BLUE}Test 3: Memory Performance${NC}"
echo "-----------------------------"

# Check memory
MEM_TOTAL=$(free -m | grep Mem | awk '{print $2}')
MEM_AVAIL=$(free -m | grep Mem | awk '{print $7}')
MEM_USED=$((MEM_TOTAL - MEM_AVAIL))

if [ "$MEM_TOTAL" -gt 0 ]; then
    MEM_PERCENT=$((MEM_USED * 100 / MEM_TOTAL))
    if [ "$MEM_PERCENT" -lt 90 ]; then
        print_result "Memory Performance" "PASS" "Total: ${MEM_TOTAL}MB, Used: ${MEM_USED}MB (${MEM_PERCENT}%)"
    else
        print_result "Memory Performance" "FAIL" "Memory usage too high: ${MEM_PERCENT}%"
    fi
else
    print_result "Memory Performance" "FAIL" "Could not read memory info"
fi

echo ""

# ------------------------------------------------------------
# Test 4: Storage Performance (Disk I/O)
# ------------------------------------------------------------
echo -e "${BLUE}Test 4: Storage Performance${NC}"
echo "-----------------------------"

# Check if dd is available
if command -v dd &> /dev/null; then
    # Write test
    WRITE_RESULT=$(dd if=/dev/zero of=/tmp/test_io bs=1M count=10 2>&1)
    WRITE_SPEED=$(echo "$WRITE_RESULT" | grep -o "[0-9.]* MB/s" | head -1)
    
    # Read test
    READ_RESULT=$(dd if=/tmp/test_io of=/dev/null bs=1M count=10 2>&1)
    READ_SPEED=$(echo "$READ_RESULT" | grep -o "[0-9.]* MB/s" | head -1)
    
    # Clean up
    rm -f /tmp/test_io
    
    if [ -n "$WRITE_SPEED" ] && [ -n "$READ_SPEED" ]; then
        print_result "Storage Performance" "PASS" "Write: $WRITE_SPEED, Read: $READ_SPEED"
    else
        print_result "Storage Performance" "FAIL" "Could not measure I/O speed"
    fi
else
    print_result "Storage Performance" "SKIP" "dd command not available"
fi

echo ""

# ------------------------------------------------------------
# Test 5: Thermal Performance
# ------------------------------------------------------------
echo -e "${BLUE}Test 5: Thermal Performance${NC}"
echo "-----------------------------"

# Check thermal zones
if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    TEMP=$(cat /sys/class/thermal/thermal_zone0/temp)
    TEMP_C=$((TEMP / 1000))
    
    if [ "$TEMP_C" -lt 80 ]; then
        print_result "Thermal Performance" "PASS" "Temperature: ${TEMP_C}°C"
    elif [ "$TEMP_C" -lt 90 ]; then
        print_result "Thermal Performance" "WARN" "Temperature: ${TEMP_C}°C (approaching limit)"
    else
        print_result "Thermal Performance" "FAIL" "Temperature too high: ${TEMP_C}°C"
    fi
else
    print_result "Thermal Performance" "SKIP" "No thermal zone found"
fi

echo ""

# ------------------------------------------------------------
# Test 6: Network Performance
# ------------------------------------------------------------
echo -e "${BLUE}Test 6: Network Performance${NC}"
echo "-----------------------------"

# Check network interface
if ip link show eth0 &> /dev/null; then
    # Check if eth0 is up
    if ip link show eth0 | grep -q "UP"; then
        # Get speed using ethtool
        if command -v ethtool &> /dev/null; then
            SPEED=$(ethtool eth0 2>/dev/null | grep Speed | awk '{print $2}')
            if [ -n "$SPEED" ]; then
                print_result "Network Performance" "PASS" "Speed: $SPEED"
            else
                print_result "Network Performance" "WARN" "Could not determine speed"
            fi
        else
            print_result "Network Performance" "WARN" "ethtool not installed"
        fi
    else
        print_result "Network Performance" "FAIL" "eth0 is down"
    fi
else
    print_result "Network Performance" "SKIP" "eth0 not found"
fi

echo ""

# ------------------------------------------------------------
# Test 7: Interrupt Performance
# ------------------------------------------------------------
echo -e "${BLUE}Test 7: Interrupt Performance${NC}"
echo "------------------------------"

if [ -f /proc/interrupts ]; then
    # Count interrupts
    IRQ_COUNT=$(cat /proc/interrupts | grep -v "CPU" | wc -l)
    IRQ_TOTAL=$(cat /proc/interrupts | awk 'NR>1 {sum=0; for(i=2;i<=NF;i++) sum+=$i; print sum}' | head -1)
    
    if [ -n "$IRQ_TOTAL" ] && [ "$IRQ_TOTAL" -gt 0 ]; then
        print_result "Interrupt Performance" "PASS" "Total interrupts: $IRQ_TOTAL, Sources: $IRQ_COUNT"
    else
        print_result "Interrupt Performance" "FAIL" "Could not read interrupts"
    fi
else
    print_result "Interrupt Performance" "SKIP" "/proc/interrupts not found"
fi

echo ""

# ------------------------------------------------------------
# Test 8: Process Context Switching
# ------------------------------------------------------------
echo -e "${BLUE}Test 8: Context Switching${NC}"
echo "---------------------------"

if command -v perf &> /dev/null; then
    # Measure context switches
    CS_RESULT=$(perf stat -e context-switches sleep 1 2>&1)
    
    if echo "$CS_RESULT" | grep -q "context-switches"; then
        CS_COUNT=$(echo "$CS_RESULT" | grep "context-switches" | awk '{print $1}' | tr -d ',')
        if [ -n "$CS_COUNT" ]; then
            print_result "Context Switching" "PASS" "Context switches/sec: $CS_COUNT"
        else
            print_result "Context Switching" "FAIL" "Could not parse context switches"
        fi
    else
        print_result "Context Switching" "FAIL" "Perf context-switch event not available"
    fi
else
    print_result "Context Switching" "SKIP" "perf not installed"
fi

echo ""

# ------------------------------------------------------------
# Test 9: System Load
# ------------------------------------------------------------
echo -e "${BLUE}Test 9: System Load${NC}"
echo "------------------------"

# Get load average
LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1,$2,$3}')
LOAD_1=$(echo $LOAD | awk '{print $1}' | sed 's/,//')
LOAD_5=$(echo $LOAD | awk '{print $2}' | sed 's/,//')
LOAD_15=$(echo $LOAD | awk '{print $3}' | sed 's/,//')

if [ -n "$LOAD_1" ]; then
    # Get number of CPUs
    CPU_COUNT=$(nproc 2>/dev/null || echo 4)
    LOAD_THRESHOLD=$((CPU_COUNT * 80 / 100))
    
    if (( $(echo "$LOAD_1 < $LOAD_THRESHOLD" | bc -l 2>/dev/null || echo 1) )); then
        print_result "System Load" "PASS" "Load: $LOAD_1, $LOAD_5, $LOAD_15 (${CPU_COUNT} cores)"
    else
        print_result "System Load" "WARN" "Load high: $LOAD_1 (${CPU_COUNT} cores)"
    fi
else
    print_result "System Load" "FAIL" "Could not get load average"
fi

echo ""

# ------------------------------------------------------------
# Test 10: File System Performance
# ------------------------------------------------------------
echo -e "${BLUE}Test 10: File System Performance${NC}"
echo "--------------------------------"

# Create test file
echo "Testing file system..." > /tmp/fs_test.txt
sync

# Measure write time
START=$(date +%s%N)
echo "Test data" >> /tmp/fs_test.txt
sync
END=$(date +%s%N)
WRITE_TIME=$(( (END - START) / 1000000 ))

# Measure read time
START=$(date +%s%N)
cat /tmp/fs_test.txt > /dev/null
END=$(date +%s%N)
READ_TIME=$(( (END - START) / 1000000 ))

# Clean up
rm -f /tmp/fs_test.txt

if [ "$WRITE_TIME" -lt 100 ] && [ "$READ_TIME" -lt 100 ]; then
    print_result "File System" "PASS" "Write: ${WRITE_TIME}ms, Read: ${READ_TIME}ms"
else
    print_result "File System" "WARN" "Write: ${WRITE_TIME}ms, Read: ${READ_TIME}ms (may be slow)"
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
    echo -e "${GREEN}✅ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed!${NC}"
    exit 1
fi
