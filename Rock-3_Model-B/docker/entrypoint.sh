#!/bin/bash
# ============================================
# Docker Entrypoint Script for Rock 3 Builder
# ============================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print banner
echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║     🚀 Rock 3 Model B - Docker Build Environment          ║"
echo "║                                                            ║"
echo "║     Platform: RK3568 (ARM64)                              ║"
echo "║     OS: Ubuntu 22.04 LTS                                  ║"
echo "║     User: $(whoami)                                       ║"
echo "║     Workspace: $(pwd)                                     ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check environment
echo -e "${BLUE}📋 Environment Check:${NC}"
echo "  Architecture: $(uname -m)"
echo "  Cross-compile: $CROSS_COMPILE"
echo "  ARCH: $ARCH"
echo "  CC: $CC"
echo "  CXX: $CXX"
echo ""

# Check if source directories exist
echo -e "${BLUE}📁 Directory Check:${NC}"
if [ -d "/workspace/src/kernel" ]; then
    echo -e "  ✅ Kernel source: /workspace/src/kernel"
else
    echo -e "  ⚠️  Kernel source not found in /workspace/src/kernel"
fi

if [ -d "/workspace/src/modules" ]; then
    echo -e "  ✅ Modules source: /workspace/src/modules"
else
    echo -e "  ℹ️  No modules source found"
fi

if [ -d "/workspace/src/applications" ]; then
    echo -e "  ✅ Application source: /workspace/src/applications"
else
    echo -e "  ℹ️  No application source found"
fi
echo ""

# Check output directory
if [ -d "/workspace/output" ]; then
    echo -e "  📦 Output directory: /workspace/output"
fi
echo ""

# Check ccache
if [ -d "/home/$(whoami)/.ccache" ]; then
    echo -e "${BLUE}💾 CCache:${NC}"
    ccache -s
    echo ""
fi

# Check tools
echo -e "${BLUE}🔧 Available Tools:${NC}"
for tool in aarch64-linux-gnu-gcc trace-cmd perf strace gdb; do
    if command -v $tool &> /dev/null; then
        echo -e "  ✅ $tool"
    else
        echo -e "  ❌ $tool (not found)"
    fi
done
echo ""

# Print helpful aliases
echo -e "${YELLOW}📝 Useful Commands:${NC}"
echo "  kernel-build  - Build kernel with default config"
echo "  make -j\$(nproc) Image  - Build just kernel image"
echo "  make modules  - Build kernel modules"
echo "  trace-cmd record -p function_graph sleep 10  - Record function graph"
echo "  perf stat -a -e rockchip_ddr/bytes/ sleep 1  - Monitor DDR"
echo "  strace -f -o trace.log ./your_app  - Trace system calls"
echo ""

# Execute command or start shell
if [ $# -eq 0 ]; then
    echo -e "${GREEN}Starting interactive shell...${NC}"
    exec /bin/bash
else
    echo -e "${GREEN}Executing: $@${NC}"
    exec "$@"
fi
