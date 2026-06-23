# Test Makefile

.PHONY: all test-system test-performance test-peripheral test-all clean

all: test-all

test-system:
	@echo "Running System Tests..."
	@./test-system.sh

test-performance:
	@echo "Running Performance Tests..."
	@./test-performance.sh

test-peripheral:
	@echo "Running Peripheral Tests..."
	@./test-peripheral.sh

test-all:
	@echo "Running All Tests..."
	@./run-all-tests.sh

clean:
	@echo "Cleaning test results..."
	@rm -rf results/
	@echo "Clean complete"

help:
	@echo "Available targets:"
	@echo "  test-system      - Run system tests"
	@echo "  test-performance - Run performance tests"
	@echo "  test-peripheral  - Run peripheral tests"
	@echo "  test-all         - Run all tests"
	@echo "  clean            - Clean test results"
	@echo "  help             - Show this help"
