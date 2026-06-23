#!/bin/bash
# ============================================
# Perf Examples for Rock 3 Model B
# ============================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}    Perf Examples for Rock 3          ${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if perf is installed
if ! command -v perf &> /dev/null; then
    echo -e "${RED}Error: perf not installed${NC}"
    echo "Install with: sudo apt install linux-tools-common linux-tools-generic"
    exit 1
fi

echo -e "${BLUE}Example 1: System-wide Statistics${NC}"
echo "-----------------------------------"
echo "Running perf stat for 1 second..."
perf stat -a sleep 1 2>&1 | head -20

echo ""
echo -e "${GREEN}✓ System-wide statistics complete${NC}"
echo ""

# ------------------------------------------------------------

echo -e "${BLUE}Example 2: CPU Performance Counters${NC}"
echo "------------------------------------"
echo "Counting CPU events for 1 second..."

perf stat -e cycles,instructions,cache-misses,cache-references sleep 1 2>&1 | grep -E "cycles|instructions|cache"

echo ""
echo -e "${GREEN}✓ CPU performance counters complete${NC}"
echo ""

# ------------------------------------------------------------

echo -e "${BLUE}Example 3: DDR Monitoring (RK3568 Specific)${NC}"
echo "--------------------------------------------"
echo "Monitoring DDR bandwidth for 1 second..."

# Check if DDR events exist
if perf list 2>/dev/null | grep -q rockchip_ddr; then
    perf stat -a -e rockchip_ddr/bytes/,\
        rockchip_ddr/read-bytes/,\
        rockchip_ddr/write-bytes/ sleep 1 2>&1 | grep rockchip_ddr
else
    echo -e "${YELLOW}DDR events not available (not running on RK3568?)${NC}"
fi

echo ""
echo -e "${GREEN}✓ DDR monitoring complete${NC}"
echo ""

# ------------------------------------------------------------

echo -e "${BLUE}Example 4: CPU Profiling${NC}"
echo "--------------------------"
echo "Profiling CPU for 3 seconds..."

perf record -a -g -F 99 -o perf_example.data sleep 3 2>/dev/null

echo -e "${BLUE}Perf report (first 20 lines):${NC}"
perf report -i perf_example.data --stdio --no-children 2>/dev/null | head -20

# Cleanup
rm -f perf_example.data

echo ""
echo -e "${GREEN}✓ CPU profiling complete${NC}"
echo ""

# ------------------------------------------------------------

echo -e "${BLUE}Example 5: Process Monitoring${NC}"
echo "-------------------------------"
echo "Monitoring current process ($$) for 2 seconds..."

perf stat -p $$ sleep 2 2>&1 | head -15

echo ""
echo -e "${GREEN}✓ Process monitoring complete${NC}"
echo ""

# ------------------------------------------------------------

echo -e "${BLUE}Example 6: Event List${NC}"
echo "-----------------------"
echo "Listing available events (first 20)..."

perf list 2>/dev/null | head -20

echo ""
echo -e "${GREEN}✓ Event list complete${NC}"
echo ""

# ------------------------------------------------------------

echo -e "${BLUE}Example 7: Cache Performance${NC}"
echo "-------------------------------"
echo "Analyzing cache performance..."

perf stat -e L1-dcache-loads,\
    L1-dcache-load-misses,\
    LLC-loads,\
    LLC-load-misses sleep 1 2>&1 | grep -E "L1|LLC"

echo ""
echo -e "${GREEN}✓ Cache performance complete${NC}"
echo ""

# ------------------------------------------------------------

echo -e "${BLUE}Example 8: Scheduler Analysis${NC}"
echo "-------------------------------"
echo "Analyzing scheduler events for 2 seconds..."

perf stat -e context-switches,\
    migrations,\
    page-faults sleep 2 2>&1 | grep -E "context-switches|migrations|page-faults"

echo ""
echo -e "${GREEN}✓ Scheduler analysis complete${NC}"
echo ""

# ------------------------------------------------------------

echo -e "${BLUE}Example 9: Perf Top${NC}"
echo "-----------------------"
echo "Running perf top for 2 seconds (sample only)..."
echo -e "${YELLOW}Note: perf top is interactive, showing sample data${NC}"

timeout 2 perf top --stdio -d 1 2>/dev/null | head -20 || true

echo ""
echo -e "${GREEN}✓ Perf top sample complete${NC}"
echo ""

# ------------------------------------------------------------

echo -e "${BLUE}Example 10: Trace Comparison${NC}"
echo "-------------------------------"
echo "Comparing two different workloads..."

# Baseline
echo "Baseline workload:"
perf stat -e cycles,instructions sleep 1 2>&1 | grep -E "cycles|instructions"

# Workload
echo "Workload with extra operations:"
perf stat -e cycles,instructions ls -la /tmp 2>/dev/null | grep -E "cycles|instructions"

echo ""
echo -e "${GREEN}✓ Trace comparison complete${NC}"
echo ""

# ------------------------------------------------------------

echo -e "${BLUE}Example 11: Generate Flame Graph Data${NC}"
echo "-------------------------------------"
echo "Recording data for flame graph..."

perf record -a -g -F 99 -o flamegraph.data sleep 2 2>/dev/null

echo "Generating flame graph script output..."
perf script -i flamegraph.data 2>/dev/null | head -20

# Cleanup
rm -f flamegraph.data

echo ""
echo -e "${GREEN}✓ Flame graph data generation complete${NC}"
echo ""

# ------------------------------------------------------------

echo -e "${BLUE}Example 12: Multiple Event Groups${NC}"
echo "-------------------------------------"
echo "Counting multiple event groups..."

perf stat -e "{cycles,instructions},{cache-misses,cache-references}" sleep 1 2>&1 | head -15

echo ""
echo -e "${GREEN}✓ Multiple event groups complete${NC}"
echo ""

# ------------------------------------------------------------

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}    All Perf Examples Complete         ${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "For more information:"
echo "  - perf --help"
echo "  - perf list"
echo "  - perf stat --help"
echo "  - perf record --help"
echo "  - perf report --help"
