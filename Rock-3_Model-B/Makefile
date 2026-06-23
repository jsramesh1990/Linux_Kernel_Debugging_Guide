# =========================================================================
# Rock 3 Model B - Master Makefile
# =========================================================================

.PHONY: all build clean help test docker

# Default target
all: help

# Build targets
build: build-kernel build-modules build-app
	@echo "✅ All builds complete!"

build-kernel:
	@echo "🔨 Building kernel..."
	@$(MAKE) -C src/kernel rock3_defconfig
	@$(MAKE) -C src/kernel -j$(nproc) Image dtbs modules
	@mkdir -p output/kernel/dtbs/rockchip
	@cp src/kernel/arch/arm64/boot/Image output/kernel/
	@cp src/kernel/arch/arm64/boot/dts/rockchip/*.dtb output/kernel/dtbs/rockchip/
	@echo "✅ Kernel built"

build-modules:
	@echo "🔨 Building modules..."
	@mkdir -p output/modules
	@for module in src/modules/*/; do \
		if [ -f "$$module/Makefile" ]; then \
			echo "Building $$module..."; \
			$(MAKE) -C $$module -C ../kernel M=$$PWD modules; \
			$(MAKE) -C $$module -C ../kernel M=$$PWD modules_install INSTALL_MOD_PATH=../../../output/modules; \
		fi \
	done
	@echo "✅ Modules built"

build-app:
	@echo "🔨 Building application..."
	@mkdir -p src/applications/build
	@cd src/applications/build && cmake .. && make -j$(nproc)
	@mkdir -p output/apps
	@cp src/applications/build/rock3-app output/apps/
	@echo "✅ Application built"

# Docker targets
docker-build:
	@echo "🐳 Building Docker image..."
	@cd docker && docker build -t rock3-builder:latest .
	@echo "✅ Docker image built"

docker-up:
	@echo "🐳 Starting Docker container..."
	@cd docker && docker-compose up -d
	@echo "✅ Container started"

docker-down:
	@echo "🐳 Stopping Docker container..."
	@cd docker && docker-compose down
	@echo "✅ Container stopped"

docker-shell:
	@echo "🐳 Entering Docker container..."
	@cd docker && docker-compose exec builder bash

# Test targets
test:
	@echo "🧪 Running tests..."
	@./test/integration/run-all-tests.sh

test-system:
	@./test/integration/test-system.sh

test-performance:
	@./test/integration/test-performance.sh

test-peripheral:
	@./test/integration/test-peripheral.sh

# Trace collection
traces-collect:
	@echo "📊 Collecting traces..."
	@./traces/collect-all.sh

# Clean targets
clean:
	@echo "🧹 Cleaning..."
	@rm -rf output/*
	@rm -rf traces/*/*.log
	@rm -rf traces/*/*.txt
	@rm -rf traces/*/*.data
	@find . -name "*.o" -delete
	@find . -name "*.ko" -delete
	@find . -name "*.so" -delete
	@find . -name "*.a" -delete
	@rm -rf src/applications/build
	@for module in src/modules/*/; do \
		if [ -f "$$module/Makefile" ]; then \
			$(MAKE) -C $$module clean || true; \
		fi \
	done
	@echo "✅ Clean complete"

clean-all: clean
	@echo "🧹 Deep cleaning..."
	@$(MAKE) -C src/kernel mrproper || true
	@echo "✅ Deep clean complete"

# Help
help:
	@echo "=========================================================================="
	@echo "  Rock 3 Model B - Build System"
	@echo "=========================================================================="
	@echo ""
	@echo "Build targets:"
	@echo "  build            - Build everything (kernel, modules, app)"
	@echo "  build-kernel     - Build only kernel"
	@echo "  build-modules    - Build only modules"
	@echo "  build-app        - Build only application"
	@echo ""
	@echo "Docker targets:"
	@echo "  docker-build     - Build Docker image"
	@echo "  docker-up        - Start Docker container"
	@echo "  docker-down      - Stop Docker container"
	@echo "  docker-shell     - Enter Docker container shell"
	@echo ""
	@echo "Test targets:"
	@echo "  test             - Run all tests"
	@echo "  test-system      - Run system tests"
	@echo "  test-performance - Run performance tests"
	@echo "  test-peripheral  - Run peripheral tests"
	@echo ""
	@echo "Trace targets:"
	@echo "  traces-collect   - Collect all traces"
	@echo ""
	@echo "Clean targets:"
	@echo "  clean            - Clean build artifacts"
	@echo "  clean-all        - Deep clean (including kernel)"
	@echo ""
	@echo "Other:"
	@echo "  help             - Show this help"
	@echo "=========================================================================="
