#!/bin/bash
# ============================================
# Run All Tests for Rock 3 Model B
# ============================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Rock 3 Model B - Test Suite Runner${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Running all test suites..."
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="$SCRIPT_DIR"

# Create test output directory
mkdir -p "$TEST_DIR/results"

# Function to run a test suite
run_test_suite() {
    local test_script="$1"
    local test_name="$2"
    
    echo -e "${BLUE}Running $test_name...${NC}"
    echo "--------------------------------------------------"
    
    if "$test_script" 2>&1 | tee "$TEST_DIR/results/${test_name}.log"; then
        echo -e "${GREEN}✅ $test_name passed${NC}"
        return 0
    else
        echo -e "${RED}❌ $test_name failed${NC}"
        return 1
    fi
    echo ""
}

# Run test suites
PASSED=0
FAILED=0

# Test 1: System Tests
if run_test_suite "$TEST_DIR/test-system.sh" "System Tests"; then
    ((PASSED++))
else
    ((FAILED++))
fi

# Test 2: Performance Tests
if run_test_suite "$TEST_DIR/test-performance.sh" "Performance Tests"; then
    ((PASSED++))
else
    ((FAILED++))
fi

# Test 3: Peripheral Tests
if run_test_suite "$TEST_DIR/test-peripheral.sh" "Peripheral Tests"; then
    ((PASSED++))
else
    ((FAILED++))
fi

# Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Test Suite Summary${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Passed: $PASSED test suites${NC}"
echo -e "${RED}Failed: $FAILED test suites${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All test suites passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some test suites failed!${NC}"
    echo "Check logs in: $TEST_DIR/results/"
    exit 1
fi
