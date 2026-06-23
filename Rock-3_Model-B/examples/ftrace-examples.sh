#!/bin/bash
# ============================================
# Ftrace Examples for Rock 3 Model B
# ============================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}    Ftrace Examples for Rock 3        ${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if debugfs is mounted
if ! mount | grep -q debugfs; then
    echo -e "${YELLOW}Mounting debugfs...${NC}"
    sudo mount -t debugfs none /sys/kernel/debug
fi

# Function to check if ftrace is available
check_ftrace() {
    if [ ! -d /sys/kernel/debug/tracing ]; then
        echo -e "${RED}Error: ftrace not available${NC}"
        exit 1
    fi
}

# Function to reset ftrace
reset_ftrace() {
    echo 0 > /sys/kernel/debug/tracing/tracing_on
    echo nop > /sys/kernel/debug/tracing/current_tracer
    echo > /sys/kernel/debug/tracing/trace
    echo 1 > /sys/kernel/debug/tracing/tracing_on
}

# Function to view trace
view_trace() {
    echo -e "${BLUE}--- Trace Output ---${NC}"
    cat /sys/kernel/debug/tracing/trace | head -30
    echo -e "${BLUE}--- End of Trace ---${NC}"
}

echo -e "${BLUE}Example 1: Function Tracer${NC}"
echo "------------------------------"
echo "Tracing function calls for 2 seconds..."

# Set function tracer
reset_ftrace
echo function > /sys/kernel/debug/tracing/current_tracer
echo 1 > /sys/kernel/debug/tracing/tracing_on

# Run workload
sleep 2

# Disable and view
echo 0 > /sys/kernel/debug/tracing/tracing_on
view_trace

echo ""
echo -e "${GREEN}✓ Function tracer example complete${NC}"
echo ""

# ------------------------------------------------------------

echo -e "${BLUE}Example 2: Function Graph Tracer${NC}"
echo "--------------------------------"
echo "Tracing function graph for 2 seconds..."

# Set function graph tracer
reset_ftrace
echo function_graph > /sys/kernel/debug/tracing/current_tracer
echo 5 > /sys/kernel/debug/tracing/max_graph_depth
echo 1 > /sys/kernel/debug/tracing/tracing_on

# Run workload
sleep 2

# Disable and view
echo 0 > /sys/kernel/debug/tracing/tracing_on
view_trace

echo ""
echo -e "${GREEN}✓ Function graph tracer example complete${NC}"
echo ""

# ------------------------------------------------------------

echo -e "${BLUE}Example 3: Event Tracing${NC}"
echo "-------------------------"
echo "Tracing sched_switch events for 2 seconds..."

# Set event tracer
reset_ftrace
echo nop > /sys/kernel/debug/tracing/current_tracer
echo 1 > /sys/kernel/debug/tracing/events/sched/sched_switch/enable
echo 1 > /sys/kernel/debug/tracing/tracing_on

# Run workload
sleep 2

# Disable and view
echo 0 > /sys/kernel/debug/tracing/tracing_on
echo 0 > /sys/kernel/debug/tracing/events/sched/sched_switch/enable
view_trace

echo ""
echo -e "${GREEN}✓ Event tracer example complete${NC}"
echo ""

# ------------------------------------------------------------

echo -e "${BLUE}Example 4: Function Filtering${NC}"
echo "-------------------------------"
echo "Tracing only 'do_sys_open' function..."

# Set function filter
reset_ftrace
echo do_sys_open > /sys/kernel/debug/tracing/set_ftrace_filter
echo function > /sys/kernel/debug/tracing/current_tracer
echo 1 > /sys/kernel/debug/tracing/tracing_on

# Run workload
sleep 2

# Disable and view
echo 0 > /sys/kernel/debug/tracing/tracing_on
echo '' > /sys/kernel/debug/tracing/set_ftrace_filter
view_trace

echo ""
echo -e "${GREEN}✓ Function filter example complete${NC}"
echo ""

# ------------------------------------------------------------

echo -e "${BLUE}Example 5: trace-cmd Recording${NC}"
echo "-------------------------------"
echo "Using trace-cmd to record for 2 seconds..."

# Check if trace-cmd is installed
if ! command -v trace-cmd &> /dev/null; then
    echo -e "${YELLOW}trace-cmd not installed. Skipping...${NC}"
    echo "Install with: sudo apt install trace-cmd"
else
    # Record with trace-cmd
    sudo trace-cmd record -p function_graph -e sched_switch sleep 2 2>/dev/null
    
    # Extract
    sudo trace-cmd extract -o trace.dat 2>/dev/null
    
    # Report
    echo -e "${BLUE}Trace-cmd report (first 20 lines):${NC}"
    sudo trace-cmd report -i trace.dat 2>/dev/null | head -20
    
    # Cleanup
    sudo rm -f trace.dat
    sudo rm -f trace.dat.*
    
    echo ""
    echo -e "${GREEN}✓ trace-cmd example complete${NC}"
fi

echo ""

# ------------------------------------------------------------

echo -e "${BLUE}Example 6: Stack Trace${NC}"
echo "-------------------------"
echo "Tracing with stack trace enabled..."

# Set stack trace
reset_ftrace
echo 1 > /sys/kernel/debug/tracing/options/stacktrace
echo function > /sys/kernel/debug/tracing/current_tracer
echo 1 > /sys/kernel/debug/tracing/tracing_on

# Run workload
sleep 2

# Disable and view
echo 0 > /sys/kernel/debug/tracing/tracing_on
echo 0 > /sys/kernel/debug/tracing/options/stacktrace
view_trace

echo ""
echo -e "${GREEN}✓ Stack trace example complete${NC}"
echo ""

# ------------------------------------------------------------

echo -e "${BLUE}Example 7: IRQ Tracing${NC}"
echo "--------------------------"
echo "Tracing IRQ events for 2 seconds..."

# Set IRQ trace
reset_ftrace
echo 1 > /sys/kernel/debug/tracing/events/irq/irq_handler_entry/enable
echo 1 > /sys/kernel/debug/tracing/events/irq/irq_handler_exit/enable
echo 1 > /sys/kernel/debug/tracing/tracing_on

# Run workload
sleep 2

# Disable and view
echo 0 > /sys/kernel/debug/tracing/tracing_on
echo 0 > /sys/kernel/debug/tracing/events/irq/irq_handler_entry/enable
echo 0 > /sys/kernel/debug/tracing/events/irq/irq_handler_exit/enable
view_trace

echo ""
echo -e "${GREEN}✓ IRQ trace example complete${NC}"
echo ""

# ------------------------------------------------------------

echo -e "${BLUE}Example 8: Peripheral Tracing (I2C)${NC}"
echo "-------------------------------------"
echo "Tracing I2C events for 2 seconds..."

# Check if I2C events exist
if [ -d /sys/kernel/debug/tracing/events/i2c ]; then
    reset_ftrace
    echo 1 > /sys/kernel/debug/tracing/events/i2c/*/enable
    echo 1 > /sys/kernel/debug/tracing/tracing_on
    
    # Run workload (scan I2C bus)
    i2cdetect -y 1 2>/dev/null || echo "  (I2C bus may not exist)"
    
    # Disable and view
    echo 0 > /sys/kernel/debug/tracing/tracing_on
    echo 0 > /sys/kernel/debug/tracing/events/i2c/*/enable
    view_trace
else
    echo -e "${YELLOW}I2C events not available${NC}"
fi

echo ""
echo -e "${GREEN}✓ Peripheral trace example complete${NC}"
echo ""

# ------------------------------------------------------------

# Reset ftrace
reset_ftrace

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}    All Ftrace Examples Complete       ${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "For more details, check:"
echo "  - /sys/kernel/debug/tracing/available_tracers"
echo "  - /sys/kernel/debug/tracing/events/"
echo "  - trace-cmd --help"
