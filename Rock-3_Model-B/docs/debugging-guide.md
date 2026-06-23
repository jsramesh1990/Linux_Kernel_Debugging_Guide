# Comprehensive Debugging Guide for Rock 3 Model B

## Table of Contents
1. [Performance Profiling with perf](#1-performance-profiling-with-perf)
2. [Kernel Tracing with ftrace](#2-kernel-tracing-with-ftrace)
3. [System Call Tracing with strace](#3-system-call-tracing-with-strace)
4. [Kernel Messages with dmesg](#4-kernel-messages-with-dmesg)
5. [Peripheral-Specific Debugging](#5-peripheral-specific-debugging)
6. [Memory Analysis](#6-memory-analysis)
7. [Network Debugging](#7-network-debugging)
8. [Advanced Debugging Tools](#8-advanced-debugging-tools)
9. [Performance Verification Matrix](#9-performance-verification-matrix)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. Performance Profiling with perf

### DDR Monitoring (RK3568 Specific)
The Rock 3's RK3568 processor has built-in DDR Performance Monitoring Unit (PMU) support.

```bash
# Monitor DDR bandwidth
perf stat -a -e rockchip_ddr/cycles/,\
    rockchip_ddr/read-bytes/,\
    rockchip_ddr/write-bytes/,\
    rockchip_ddr/bytes/ sleep 1

# Sample output:
# 125,456,789  rockchip_ddr/cycles/
# 2,345,678   rockchip_ddr/read-bytes/
# 1,234,567   rockchip_ddr/write-bytes/
# 3,580,245   rockchip_ddr/bytes/

# Monitor DDR operations
perf stat -a -e \
    rockchip_ddr/read-ops/,\
    rockchip_ddr/write-ops/,\
    rockchip_ddr/all-ops/ sleep 1

# Continuous DDR monitoring
watch -n 1 'perf stat -a -e rockchip_ddr/bytes/ sleep 1 2>&1 | grep rockchip_ddr'
