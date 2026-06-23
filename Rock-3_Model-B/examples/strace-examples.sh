#!/bin/bash
# ============================================
# Strace Examples for Rock 3 Model B
# ============================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}    Strace Examples for Rock 3        ${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if strace is installed
if ! command -v strace &> /dev/null; then
    echo -e "${RED}Error: strace not installed${NC}"
    echo "Install with: sudo apt install strace"
    exit 1
fi

# Function to run strace and show output
run_strace() {
    local cmd="$1"
    local options="${2:-}"
    echo -e "${BLUE}Running: strace $options $cmd${NC}"
    echo -e "${BLUE}Output (first 20 lines):${NC}"
    eval "strace $options $cmd 2>&1 | head -20"
    echo ""
}

echo -e "${BLUE}Example 1: Basic System Call Tracing${NC}"
echo "--------------------------------------"
echo "Tracing all system calls of 'ls' command..."
run_strace "ls -la /tmp" "-c"

echo -e "${GREEN}✓ Basic system call tracing complete${NC}"
echo ""

# ------------------------------------------------------------

echo -e "${BLUE}Example 2: Filter Specific System Calls${NC}"
echo "-------------------------------------------"
echo "Tracing only file operations..."
run_strace "ls -la /tmp" "-e open,openat,close,read,write"

echo -e "${GREEN}✓ Filtered system call tracing complete${NC}"
echo ""

# ------------------------------------------------------------

echo -e "${BLUE}Example 3: Network System Calls${NC}"
echo "-----------------------------------"
echo "Tracing network-related system calls..."
run_strace "curl -s http://google.com > /dev/null 2>&1 || true" "-e socket,connect,accept,recv,send"

echo -e "${GREEN}✓ Network system call tracing complete${NC}"
echo ""

# ------------------------------------------------------------

echo -e "${BLUE}Example 4: Process System Calls${NC}"
echo "------------------------------------"
echo "Tracing process-related system calls..."
run_strace "sh -c 'echo test > /tmp/test.txt'" "-e fork,execve,waitpid,clone"

echo -e "${GREEN}✓ Process system call tracing complete${NC}"
echo ""

# ------------------------------------------------------------

echo -e "${BLUE}Example 5: Memory System Calls${NC}"
echo "----------------------------------"
echo "Tracing memory-related system calls..."
run_strace "ls" "-e mmap,munmap,brk,mprotect"

echo -e "${GREEN}✓ Memory system call tracing complete${NC}"
echo ""

# ------------------------------------------------------------

echo -e "${BLUE}Example 6: With Timestamps${NC}"
echo "------------------------------"
echo "Tracing with timestamps..."
run_strace "ls" "-r -tt -T"

echo -e "${GREEN}✓ Timestamp tracing complete${NC}"
echo ""

# ------------------------------------------------------------

echo -e "${BLUE}Example 7: Save to File${NC}"
echo "-----------------------------"
echo "Saving trace to file..."

STRACE_LOG="/tmp/strace_example.log"
strace -f -o $STRACE_LOG ls -la /tmp 2>/dev/null

echo -e "${BLUE}Trace saved to: $STRACE_LOG${NC}"
echo -e "${BLUE}First 20 lines of trace:${NC}"
head -20 $STRACE_LOG

rm -f $STRACE_LOG

echo ""
echo -e "${GREEN}✓ Save to file complete${NC}"
echo ""

# ------------------------------------------------------------

echo -e "${BLUE}Example 8: Attach to Running Process${NC}"
echo "-------------------------------------"
echo "Attaching to current shell process (PID: $$)..."

# Create a background process that does something
sleep 5 &
BG_PID=$!

echo -e "${YELLOW}Attaching to PID: $BG_PID for 2 seconds...${NC}"
timeout 2 strace -p $BG_PID 2>&1 | head -20 || true

# Cleanup
kill $BG_PID 2>/dev/null || true

echo ""
echo -e "${GREEN}✓ Attach to process complete${NC}"
echo ""

# ------------------------------------------------------------

echo -e "${BLUE}Example 9: Summary Statistics${NC}"
echo "--------------------------------"
echo "Generating summary statistics..."
run_strace "ls -R /tmp 2>/dev/null || true" "-c"

echo -e "${GREEN}✓ Summary statistics complete${NC}"
echo ""

# ------------------------------------------------------------

echo -e "${BLUE}Example 10: Signal Tracing${NC}"
echo "-------------------------------"
echo "Tracing signal handling..."
run_strace "sleep 1" "-e signal,rt_sigaction"

echo -e "${GREEN}✓ Signal tracing complete${NC}"
echo ""

# ------------------------------------------------------------

echo -e "${BLUE}Example 11: File Descriptor Tracing${NC}"
echo "-------------------------------------"
echo "Tracing file descriptors..."
run_strace "ls" "-y"

echo -e "${GREEN}✓ File descriptor tracing complete${NC}"
echo ""

# ------------------------------------------------------------

echo -e "${BLUE}Example 12: Verbose Output${NC}"
echo "-----------------------------"
echo "Tracing with verbose output..."
run_strace "ls /tmp" "-v"

echo -e "${GREEN}✓ Verbose output complete${NC}"
echo ""

# ------------------------------------------------------------

echo -e "${BLUE}Example 13: I/O Tracing${NC}"
echo "-------------------------"
echo "Tracing I/O operations..."
run_strace "dd if=/dev/zero of=/tmp/test_io bs=1024 count=10 2>/dev/null" "-e read,write,lseek"

rm -f /tmp/test_io

echo ""
echo -e "${GREEN}✓ I/O tracing complete${NC}"
echo ""

# ------------------------------------------------------------

echo -e "${BLUE}Example 14: Time Statistics${NC}"
echo "-------------------------------"
echo "Tracing with time statistics..."
run_strace "find /tmp -name '*.txt' 2>/dev/null || true" "-r -T"

echo -e "${GREEN}✓ Time statistics complete${NC}"
echo ""

# ------------------------------------------------------------

echo -e "${BLUE}Example 15: Child Process Tracing${NC}"
echo "------------------------------------"
echo "Tracing with child processes..."
run_strace "sh -c 'ls; echo test'" "-f"

echo -e "${GREEN}✓ Child process tracing complete${NC}"
echo ""

# ------------------------------------------------------------

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}    All Strace Examples Complete       ${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "For more information:"
echo "  - strace --help"
echo "  - man strace"
echo "  - strace -c <command>  # Summary"
echo "  - strace -e trace=file <command>  # File operations"
echo "  - strace -e trace=network <command>  # Network operations"
echo "  - strace -e trace=process <command>  # Process operations"
echo "  - strace -e trace=memory <command>  # Memory operations"
echo ""
echo -e "${YELLOW}Useful strace options:${NC}"
echo "  -c          # Summary statistics"
echo "  -f          # Follow children"
echo "  -tt         # Microsecond timestamps"
echo "  -T          # Show time spent in calls"
echo "  -r          # Relative timestamps"
echo "  -v          # Verbose output"
echo "  -o file     # Output to file"
echo "  -p PID      # Attach to process"
echo "  -e expr     # Filter system calls"
