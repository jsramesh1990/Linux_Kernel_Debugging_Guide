CPU Profiling
bash

# Record CPU events for 30 seconds
perf record -a -g -F 99 sleep 30

# Analyze the recorded data
perf report --stdio

# Show top functions
perf report --stdio --sort symbol | head -20

# Annotate specific function
perf annotate -d function_name

# CPU statistics
perf stat -e cycles,instructions,cache-misses,cache-references sleep 1

# Count context switches
perf stat -e context-switches sleep 1

# CPU frequency monitoring
perf stat -e cpu-clock sleep 1

Cache Performance Analysis
bash

# L1 cache misses
perf stat -e L1-dcache-load-misses,L1-dcache-loads sleep 10

# LLC (Last Level Cache) misses
perf stat -e LLC-load-misses,LLC-loads sleep 10

# All cache events
perf stat -e cache-misses,cache-references,L1-dcache-load-misses,L1-icache-load-misses,LLC-load-misses sleep 10

# Ratio of cache misses
perf stat -e L1-dcache-load-misses,L1-dcache-loads sleep 10
# Miss rate = misses / loads * 100

Generate Flame Graphs
bash

# Record stack traces
perf record -a -g -F 99 sleep 30

# Clone FlameGraph repository
git clone https://github.com/brendangregg/FlameGraph

# Generate flame graph
perf script | ./FlameGraph/stackcollapse-perf.pl | \
    ./FlameGraph/flamegraph.pl > flamegraph.svg

# Open in browser
firefox flamegraph.svg

Process-Level Monitoring
bash

# Monitor specific process
perf stat -p $(pgrep process_name) sleep 5

# Profile specific process
perf record -p $(pgrep process_name) -g sleep 10
perf report

# Trace process with children
perf record -F 99 -p $(pgrep process_name) -- sleep 10

2. Kernel Tracing with ftrace
Basic ftrace Commands
bash

# Check if ftrace is enabled
mount | grep debugfs || mount -t debugfs none /sys/kernel/debug

# Available tracers
cat /sys/kernel/debug/tracing/available_tracers

# Available events
ls /sys/kernel/debug/tracing/events/

# Enable function tracer
echo function > /sys/kernel/debug/tracing/current_tracer
echo 1 > /sys/kernel/debug/tracing/tracing_on
cat /sys/kernel/debug/tracing/trace
echo 0 > /sys/kernel/debug/tracing/tracing_on

# Clear trace buffer
echo > /sys/kernel/debug/tracing/trace

Function Graph Tracing
bash

# Enable function graph tracer
echo function_graph > /sys/kernel/debug/tracing/current_tracer

# Set max depth
echo 5 > /sys/kernel/debug/tracing/max_graph_depth

# Enable tracing
echo 1 > /sys/kernel/debug/tracing/tracing_on

# Run your workload
sleep 5

# Disable and view
echo 0 > /sys/kernel/debug/tracing/tracing_on
cat /sys/kernel/debug/tracing/trace

# Save to file
cat /sys/kernel/debug/tracing/trace > trace.log

Event Tracing
bash

# List events
ls /sys/kernel/debug/tracing/events/

# Enable specific event
echo 1 > /sys/kernel/debug/tracing/events/sched/sched_switch/enable

# Enable multiple events
echo 1 > /sys/kernel/debug/tracing/events/sched/*/enable
echo 1 > /sys/kernel/debug/tracing/events/irq/*/enable

# Enable with filters
echo 'prev_pid != 0' > /sys/kernel/debug/tracing/events/sched/sched_switch/filter

# View trace
cat /sys/kernel/debug/tracing/trace

Using trace-cmd
bash

# Install trace-cmd
sudo apt install trace-cmd kernelshark

# Record function graph
sudo trace-cmd record -p function_graph sleep 10

# Record specific events
sudo trace-cmd record -e sched_switch -e irq_handler_entry sleep 10

# Record function tracing
sudo trace-cmd record -p function sleep 10

# Record with module
sudo trace-cmd record --module drm sleep 5

# Record specific PID
sudo trace-cmd record -p function -P $(pgrep process_name) sleep 10

# Extract trace data
sudo trace-cmd extract -o trace.dat

# View report
sudo trace-cmd report -i trace.dat

# Filter report
sudo trace-cmd report -i trace.dat -e sched_switch

# Show latency
sudo trace-cmd report -i trace.dat --latency

# Save as text
sudo trace-cmd report -i trace.dat > trace.txt

# KernelShark GUI
kernelshark trace.dat

Function Filtering
bash

# Set function filter
echo do_sys_open > /sys/kernel/debug/tracing/set_ftrace_filter

# Set multiple functions
echo do_sys_open > /sys/kernel/debug/tracing/set_ftrace_filter
echo do_sys_close >> /sys/kernel/debug/tracing/set_ftrace_filter

# Add functions with wildcard
echo 'do_sys_*' > /sys/kernel/debug/tracing/set_ftrace_filter

# Ignore functions
echo 'do_sys_open' > /sys/kernel/debug/tracing/set_ftrace_notrace

# View filter
cat /sys/kernel/debug/tracing/set_ftrace_filter

Stack Trace
bash

# Enable stack trace
echo 1 > /sys/kernel/debug/tracing/options/stacktrace

# Trace with stack
echo function > /sys/kernel/debug/tracing/current_tracer
echo 1 > /sys/kernel/debug/tracing/tracing_on
cat /sys/kernel/debug/tracing/trace

3. System Call Tracing with strace
Basic Usage
bash

# Trace all system calls
strace -f -o strace.log ./your_app

# Filter specific calls
strace -e open,read,write,ioctl ./your_app

# With timestamps
strace -r -tt -T ./your_app

# Attach to running process
strace -p $(pgrep your_app)

# Trace children
strace -f ./your_app

# Summary only
strace -c ./your_app

Advanced Options
bash

# Trace network calls
strace -e socket,connect,accept,recv,send ./your_app

# Trace file operations
strace -e open,close,read,write,stat,access ./your_app

# Trace process operations
strace -e fork,execve,waitpid,clone ./your_app

# Trace memory operations
strace -e mmap,munmap,brk ./your_app

# Trace signal handling
strace -e signal,rt_sigaction ./your_app

# Timestamp options
strace -t -T -r ./your_app

# Print file descriptors
strace -y ./your_app

# Verbose output
strace -v ./your_app

Save and Analyze
bash

# Save to file
strace -f -o strace.log ./your_app

# Filter log
grep "open" strace.log
grep "write" strace.log

# Count system calls
cat strace.log | cut -d'(' -f1 | sort | uniq -c | sort -nr

# Find slow operations
grep "<[0-9]" strace.log | sort -t'<' -k2 -rn | head -10

4. Kernel Messages with dmesg
Basic Commands
bash

# View all messages
dmesg

# Human-readable with timestamps
dmesg -H -L -T

# Follow new messages
dmesg -w

# Filter by level
dmesg -l err,crit,alert,emerg

# Filter by facility
dmesg -f kern
dmesg -f daemon

# Show only last N lines
dmesg | tail -20

# Search for specific device
dmesg | grep -i hdmi
dmesg | grep -i ethernet
dmesg | grep -i usb
dmesg | grep -i i2c
dmesg | grep -i spi
dmesg | grep -i gpio
dmesg | grep -i pwm

Advanced dmesg Usage
bash

# Clear dmesg buffer
sudo dmesg -c

# Save to file
dmesg > kernel-messages.log

# Monitor specific messages
dmesg -w | grep -i error

# Show with colors
dmesg --color=always

# Show with nano timestamp
dmesg --time-format=iso

# Facility and level
dmesg -f kern,l -l err

5. Peripheral-Specific Debugging
I2C Debugging
bash

# List I2C buses
i2cdetect -l

# Scan bus for devices
i2cdetect -y 1
i2cdetect -r -y 1

# Read from device
i2cget -y 1 0x50 0x00

# Write to device
i2cset -y 1 0x50 0x00 0xFF

# Dump all registers
i2cdump -y 1 0x50

# Read multiple bytes
i2ctransfer -y 1 w1@0x50 0x00 r8

# Trace I2C traffic
sudo trace-cmd record -e i2c:* -e i2c_smbus:* sleep 10
sudo trace-cmd report | grep i2c

# Dynamic debug
echo 'file drivers/i2c/* +p' > /sys/kernel/debug/dynamic_debug/control
dmesg -w | grep i2c

SPI Debugging
bash

# List SPI devices
ls /dev/spi*

# Show SPI settings
cat /sys/class/spi_master/spi*/device/*/modalias

# Test SPI communication
spidev_test -D /dev/spidev0.0 -v

# Send/receive data
spidev_test -D /dev/spidev0.0 -s 1000000 -p "\x01\x02\x03"

# Trace SPI traffic
sudo trace-cmd record -e spi:* sleep 10
sudo trace-cmd report | grep spi

# Dynamic debug
echo 'file drivers/spi/* +p' > /sys/kernel/debug/dynamic_debug/control

GPIO Debugging
bash

# Export GPIO
echo 17 > /sys/class/gpio/export

# Set direction
echo out > /sys/class/gpio/gpio17/direction
echo in > /sys/class/gpio/gpio17/direction

# Read/Write value
echo 1 > /sys/class/gpio/gpio17/value
cat /sys/class/gpio/gpio17/value

# Un-export
echo 17 > /sys/class/gpio/unexport

# List all GPIOs
ls /sys/class/gpio/gpio*

# Monitor GPIO events
gpio-monitor -t 1 17

# Trace GPIO events
sudo trace-cmd record -e gpio:* sleep 10
sudo trace-cmd report | grep gpio

HDMI Debugging
bash

# Check HDMI status
cat /sys/class/drm/card0-HDMI-A-1/status

# Check EDID
cat /sys/class/drm/card0-HDMI-A-1/edid > edid.bin

# Parse EDID
edid-decode edid.bin

# Set resolution
xrandr --output HDMI-1 --mode 1920x1080

# Get display information
xrandr -q

# Trace HDMI/DRI events
sudo trace-cmd record -e drm:* -e dw_hdmi:* sleep 10
sudo trace-cmd report | grep hdmi

# Kernel messages
dmesg | grep -i hdmi
dmesg -w | grep -i hdmi

Ethernet Debugging
bash

# Show interface status
ip link show eth0
ethtool eth0

# Show statistics
ethtool -S eth0

# Show MAC address
ip link show eth0 | grep ether

# Show speed/duplex
ethtool eth0 | grep Speed
ethtool eth0 | grep Duplex

# Capture network traffic
tcpdump -i eth0 -c 10

# Save to file
tcpdump -i eth0 -w capture.pcap

# Read capture
tcpdump -r capture.pcap

# Trace network events
sudo trace-cmd record -e net:* sleep 10
sudo trace-cmd report | grep net

USB Debugging
bash

# List USB devices
lsusb
lsusb -t
lsusb -v

# Show USB tree
lsusb -t

# USB power management
ls /sys/bus/usb/devices/*/power/

# USB bandwidth
cat /sys/bus/usb/devices/*/speed

# Trace USB events
sudo trace-cmd record -e usb:* sleep 10
sudo trace-cmd report | grep usb

# Kernel messages
dmesg | grep -i usb

PWM Debugging
bash

# Export PWM
echo 0 > /sys/class/pwm/pwmchip0/export

# Set period and duty
echo 1000000 > /sys/class/pwm/pwm0/period
echo 500000 > /sys/class/pwm/pwm0/duty_cycle

# Enable
echo 1 > /sys/class/pwm/pwm0/enable

# Disable
echo 0 > /sys/class/pwm/pwm0/enable

# Unexport
echo 0 > /sys/class/pwm/pwmchip0/unexport

6. Memory Analysis
Memory Usage
bash

# Memory statistics
free -h
cat /proc/meminfo
cat /proc/slabinfo
cat /proc/buddyinfo

# Process memory
top -o %MEM
ps aux --sort=-%mem

# Memory mapping
cat /proc/$$/maps
pmap -x $$

# Vmstat
vmstat 1 5

# Memory leaks (valgrind)
valgrind --leak-check=full ./your_app

# Memory profiling
valgrind --tool=massif ./your_app
ms_print massif.out.*

Kernel Memory Debugging
bash

# Enable memory debugging
echo 'file mm/* +p' > /sys/kernel/debug/dynamic_debug/control

# Check memory allocation
slabtop

7. Network Debugging
TCP Dump
bash

# Capture packets
tcpdump -i eth0 -c 10

# Capture specific port
tcpdump -i eth0 port 80

# Capture host
tcpdump -i eth0 host 192.168.1.100

# Save to file
tcpdump -i eth0 -w capture.pcap

# Read capture
tcpdump -r capture.pcap

# Verbose
tcpdump -i eth0 -vvv

Network Statistics
bash

# Network stats
netstat -i
netstat -s
netstat -rn

# Interface stats
ifconfig
ip -s link

# Listening ports
ss -tuln
netstat -tuln

# Connection tracking
ss -t -a

8. Advanced Debugging Tools
SystemTap
bash

# Install SystemTap
sudo apt install systemtap systemtap-runtime

# Create probe script
cat > probe.stp << 'EOF'
probe kernel.function("do_sys_open") {
    printf("open: %s\n", argstr)
}
EOF

# Run
sudo stap probe.stp

# Trace system calls
sudo stap -e 'probe syscall.* { printf("%s\n", name) }'

eBPF/BCC Tools
bash

# Install BCC
sudo apt install bpfcc-tools

# Trace disk I/O
sudo biotop-bpfcc
sudo biosnoop-bpfcc

# Trace TCP connections
sudo tcpconnect-bpfcc
sudo tcpaccept-bpfcc
sudo tcptop-bpfcc

# Trace file opens
sudo opensnoop-bpfcc

# Trace system calls
sudo trace-bpfcc "do_sys_open"

# Trace memory
sudo memleak-bpfcc

9. Performance Verification Matrix
Component	Tool	Command	Expected Output
DDR	perf	perf stat -a -e rockchip_ddr/bytes/ sleep 1	MB transferred
CPU	perf	perf stat -e cycles,instructions sleep 1	Counter values
I2C	trace-cmd	trace-cmd record -e i2c:* sleep 1	Transaction logs
GPIO	trace-cmd	trace-cmd record -e gpio:* sleep 1	GPIO events
Network	tcpdump	tcpdump -i eth0 -c 10	Packet captures
Storage	iostat	iostat -x 1 5	I/O statistics
Memory	free	free -h	Memory usage
Processes	htop	htop	Process list
Kernel	dmesg	dmesg -H -L -T	Kernel messages
System Calls	strace	strace -c sleep 1	Call statistics
10. Troubleshooting
Kernel Panic
bash

# Enable panic dump
echo 1 > /proc/sys/kernel/panic
echo 1 > /proc/sys/kernel/panic_on_oops

# View panic logs
dmesg | grep -i panic
journalctl -k | grep -i panic

# Core dump settings
ulimit -c unlimited

Performance Issues
bash

# Check interrupts
cat /proc/interrupts
perf top

# Check I/O
iotop
iostat -x 1

# Check CPU
mpstat -P ALL 1
top

# Check memory
free -h
vmstat 1

Application Crashes
bash

# Core dump
ulimit -c unlimited

# GDB debugging
gdb ./your_app core

# Backtrace
(gdb) bt full

# Valgrind
valgrind --leak-check=full ./your_app

System Freeze
bash

# Magic SysRq
echo 1 > /proc/sys/kernel/sysrq

# Show tasks
echo t > /proc/sysrq-trigger

# Show memory
echo m > /proc/sysrq-trigger

# System restart
echo b > /proc/sysrq-trigger

Quick Reference Card
bash

# Perf
perf record -a -g -F 99 sleep 30
perf report --stdio
perf stat -a -e rockchip_ddr/bytes/ sleep 1
perf top

# Ftrace/Trace-cmd
sudo trace-cmd record -p function_graph sleep 10
sudo trace-cmd report -i trace.dat
echo function > /sys/kernel/debug/tracing/current_tracer
cat /sys/kernel/debug/tracing/trace

# Strace
strace -f -o log ./app
strace -e open,read,write ./app
strace -p PID

# Dmesg
dmesg -H -L -T
dmesg -w
dmesg | grep -i error

# I2C/SPI/GPIO
i2cdetect -y 1
spidev_test -D /dev/spidev0.0
echo 17 > /sys/class/gpio/export
cat /sys/class/gpio/gpio17/value

References

    perf Documentation

    ftrace Documentation

    Linux Debugging Tools

    Brendan Gregg's Linux Performance

    Rockchip RK3568 Documentation

text


---

### `docs/perf-analysis.md`
```markdown
# Perf Analysis Guide for Rock 3 Model B

## Table of Contents
1. [Installation and Setup](#installation-and-setup)
2. [Basic Perf Commands](#basic-perf-commands)
3. [DDR Performance Analysis (RK3568)](#ddr-performance-analysis-rk3568)
4. [CPU Performance Analysis](#cpu-performance-analysis)
5. [Cache Performance Analysis](#cache-performance-analysis)
6. [Process Profiling](#process-profiling)
7. [Flame Graphs](#flame-graphs)
8. [Perf Report Analysis](#perf-report-analysis)
9. [Performance Tuning Tips](#performance-tuning-tips)
10. [Common Performance Issues](#common-performance-issues)
11. [Perf Scripts and Examples](#perf-scripts-and-examples)

---

## Installation and Setup

### Install Perf
```bash
# Install perf tools
sudo apt update
sudo apt install linux-tools-common linux-tools-generic
sudo apt install linux-tools-$(uname -r)

# Verify installation
perf --version
perf list

# Install perf for ARM64
sudo apt install linux-tools-common linux-tools-generic

Kernel Configuration

Ensure these options are enabled in kernel config:
bash

CONFIG_PERF_EVENTS=y
CONFIG_PERF_COUNTERS=y
CONFIG_HAVE_PERF_EVENTS=y
CONFIG_PROFILING=y
CONFIG_KALLSYMS=y
CONFIG_KALLSYMS_ALL=y
CONFIG_DEBUG_INFO=y

Basic Perf Commands
System-wide Monitoring
bash

# Basic system statistics
perf stat -a sleep 1

# CPU cycles
perf stat -a -e cycles sleep 1

# Instructions executed
perf stat -a -e instructions sleep 1

# All events
perf stat -a -e cycles,instructions,cache-misses,cache-references sleep 1

# With multiple runs
perf stat -a -r 5 sleep 1

Recording and Reporting
bash

# Record system-wide
perf record -a -g sleep 10

# Record with frequency
perf record -a -F 99 -g sleep 30

# Report
perf report --stdio

# Report with call graph
perf report -g graph --stdio

# Annotate code
perf annotate -d symbol_name

Event List
bash

# List all events
perf list

# List hardware events
perf list hw

# List software events
perf list sw

# List PMU events (Rockchip specific)
perf list | grep rockchip
perf list | grep arm

DDR Performance Analysis (RK3568)
DDR PMU Events

The RK3568 has specific DDR Performance Monitoring Unit events:
bash

# DDR cycles
perf stat -a -e rockchip_ddr/cycles/ sleep 1

# DDR bytes (total)
perf stat -a -e rockchip_ddr/bytes/ sleep 1

# DDR read bytes
perf stat -a -e rockchip_ddr/read-bytes/ sleep 1

# DDR write bytes
perf stat -a -e rockchip_ddr/write-bytes/ sleep 1

# DDR operations
perf stat -a -e rockchip_ddr/read-ops/,\
    rockchip_ddr/write-ops/,\
    rockchip_ddr/all-ops/ sleep 1

DDR Bandwidth Monitoring
bash

# Monitor DDR bandwidth in MB/s
perf stat -a -e rockchip_ddr/bytes/ sleep 1

# Continuous monitoring
watch -n 1 'perf stat -a -e rockchip_ddr/bytes/ sleep 1 2>&1 | grep rockchip_ddr'

# Script for DDR monitoring
cat > monitor-ddr.sh << 'EOF'
#!/bin/bash
while true; do
    echo "=== $(date) ==="
    perf stat -a -e rockchip_ddr/bytes/ sleep 1 2>&1 | grep rockchip_ddr
    sleep 5
done
EOF
chmod +x monitor-ddr.sh
./monitor-ddr.sh

DDR Performance Metrics
bash

# DDR read/write ratio
perf stat -a -e rockchip_ddr/read-bytes/,rockchip_ddr/write-bytes/ sleep 1

# DDR ops per second
perf stat -a -e rockchip_ddr/all-ops/ sleep 1

# DDR bandwidth by process
perf record -e rockchip_ddr/bytes/ -a sleep 10
perf report --stdio

CPU Performance Analysis
CPU Cycle Analysis
bash

# Basic CPU stats
perf stat -e cycles,instructions sleep 1

# CPI (Cycles Per Instruction)
perf stat -e cycles,instructions sleep 1
# CPI = cycles / instructions

# IPC (Instructions Per Cycle)
perf stat -e cycles,instructions sleep 1
# IPC = instructions / cycles

# Branch prediction
perf stat -e branch-misses,branch-instructions sleep 1
# Miss rate = branch-misses / branch-instructions * 100

CPU Frequency Analysis
bash

# CPU clock events
perf stat -e cpu-clock sleep 1

# Task clock
perf stat -e task-clock sleep 1

# CPU migrations
perf stat -e migrations sleep 1

CPU Topology
bash

# Show CPU topology
perf stat -a -e cycles -C 0 sleep 1
perf stat -a -e cycles -C 0-3 sleep 1

# Per-core statistics
perf stat -a -e cycles sleep 1

# CPU affinity
taskset -c 0-3 ./your_app
perf stat -e cycles ./your_app

Cache Performance Analysis
L1 Cache Analysis
bash

# L1 data cache
perf stat -e L1-dcache-loads,L1-dcache-load-misses sleep 10

# L1 instruction cache
perf stat -e L1-icache-loads,L1-icache-load-misses sleep 10

# L1 cache miss rate
perf stat -e L1-dcache-loads,L1-dcache-load-misses sleep 10
# Miss rate = misses / loads * 100

LLC Cache Analysis
bash

# LLC (Last Level Cache)
perf stat -e LLC-loads,LLC-load-misses sleep 10

# LLC store
perf stat -e LLC-stores,LLC-store-misses sleep 10

# Cache references vs misses
perf stat -e cache-references,cache-misses sleep 10
# Miss rate = cache-misses / cache-references * 100

Cache Visualization
bash

# Record cache events
perf record -e cache-misses,cache-references -a -g sleep 10

# Report
perf report --stdio --sort symbol

# Annotate hotspot
perf annotate -d symbol_name

Process Profiling
Single Process
bash

# Profile process
perf record -p $(pgrep process_name) -g sleep 10

# Profile with frequency
perf record -F 99 -p $(pgrep process_name) -g sleep 10

# Profile with children
perf record -F 99 --pid $(pgrep process_name) -g -- sleep 10

Multiple Processes
bash

# Profile multiple PIDs
perf record -p PID1,PID2 -g sleep 10

# Profile all processes
perf record -a -g sleep 10

# Profile with workload
perf record -g ./your_app

Process Statistics
bash

# Process stats
perf stat -e cycles,instructions,cache-misses -p $(pgrep process_name) sleep 5

# Process and children
perf stat --pid $(pgrep process_name) -e cycles,instructions sleep 5

Flame Graphs
Generate Flame Graphs
bash

# Install dependencies
sudo apt install git linux-tools-common

# Clone FlameGraph repository
git clone https://github.com/brendangregg/FlameGraph

# Record data
perf record -a -g -F 99 sleep 30

# Generate flame graph
perf script | ./FlameGraph/stackcollapse-perf.pl | \
    ./FlameGraph/flamegraph.pl > flamegraph.svg

# Open in browser
firefox flamegraph.svg

Differential Flame Graphs
bash

# Record baseline
perf record -a -g -F 99 sleep 10
perf script > baseline.out

# Record after change
perf record -a -g -F 99 sleep 10
perf script > after.out

# Generate differential flamegraph
./FlameGraph/stackcollapse-perf.pl baseline.out > baseline.folded
./FlameGraph/stackcollapse-perf.pl after.out > after.folded
./FlameGraph/difffolded.pl baseline.folded after.folded | \
    ./FlameGraph/flamegraph.pl > diff_flamegraph.svg

Perf Report Analysis
Basic Report
bash

# Report with call graph
perf report -g graph --stdio

# Report sorted by symbol
perf report --stdio --sort symbol

# Report sorted by comm
perf report --stdio --sort comm

# Report sorted by dso
perf report --stdio --sort dso

Detailed Analysis
bash

# Show overhead percentage
perf report --stdio -g none --sort overhead

# Show instruction level
perf report --stdio --show-total-period

# Annotate code
perf annotate -d symbol_name

# Show source code
perf annotate -d symbol_name --stdio -l

Export Reports
bash

# Export to CSV
perf report --stdio -g none | grep -v "#" > report.csv

# Export to JSON (with python)
perf report --stdio -g graph --stdio > report.txt

Performance Tuning Tips
CPU Tuning
bash

# Disable CPU scaling
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Set CPU affinity
taskset -c 0-3 ./your_app

# Set nice level
nice -n -20 ./your_app

# Set scheduler
chrt -f 99 ./your_app

Memory Tuning
bash

# Set hugepages
echo 256 > /proc/sys/vm/nr_hugepages

# Enable THP
echo always > /sys/kernel/mm/transparent_hugepage/enabled

# Increase cache size
echo 1000000 > /proc/sys/vm/dirty_background_bytes

I/O Tuning
bash

# Set I/O priority
ionice -c 1 -n 0 ./your_app

# Mount with noatime
mount -o remount,noatime /

Common Performance Issues
High Interrupt Load
bash

# Check interrupts
cat /proc/interrupts
perf record -e irq:* -a sleep 10
perf report

# Check softirq
cat /proc/softirqs

Cache Misses
bash

# Check cache performance
perf stat -e cache-references,cache-misses ./your_app
# Miss rate > 10% indicates poor data locality

# Check L1 misses
perf stat -e L1-dcache-load-misses,L1-icache-load-misses ./your_app

Memory Bandwidth Issues
bash

# Check DDR bandwidth
perf stat -a -e rockchip_ddr/bytes/ sleep 1
# > 80% utilization indicates bottleneck

# Check memory stall
perf stat -e cpu-cycles,stalled-cycles-frontend,stalled-cycles-backend

Context Switching
bash

# Check context switches
perf stat -e context-switches ./your_app

# Check scheduler events
perf record -e sched:* -a sleep 10
perf report

Perf Scripts and Examples
Monitor Script
bash

#!/bin/bash
# monitor-all.sh - Monitor all performance counters

echo "=== System Performance ==="
perf stat -a sleep 1

echo ""
echo "=== DDR Performance ==="
perf stat -a -e rockchip_ddr/bytes/ sleep 1

echo ""
echo "=== CPU Performance ==="
perf stat -a -e cycles,instructions,cache-misses sleep 1

echo ""
echo "=== Cache Performance ==="
perf stat -a -e L1-dcache-loads,L1-dcache-load-misses,LLC-loads,LLC-load-misses sleep 1

Benchmark Script
bash

#!/bin/bash
# benchmark.sh - Benchmark application

APP="./your_app"
ITERATIONS=5

echo "Benchmarking $APP"
echo "Iterations: $ITERATIONS"

for i in $(seq 1 $ITERATIONS); do
    echo "Run $i:"
    perf stat -e cycles,instructions,cache-misses $APP
    echo ""
done

Profile Script
bash

#!/bin/bash
# profile.sh - Profile application

APP="./your_app"
OUTPUT_DIR="./perf_output"
mkdir -p $OUTPUT_DIR

echo "Profiling $APP"
perf record -g -F 99 $APP
perf report --stdio > $OUTPUT_DIR/report.txt
perf annotate > $OUTPUT_DIR/annotate.txt

echo "Profile saved to $OUTPUT_DIR"

Quick Reference
bash

# DDR Monitoring
perf stat -a -e rockchip_ddr/bytes/ sleep 1

# CPU Profiling
perf record -a -g -F 99 sleep 30

# Process Profiling
perf record -p PID -g sleep 10

# Cache Analysis
perf stat -e cache-misses,cache-references ./app

# Report
perf report --stdio -g graph

# Annotate
perf annotate -d function_name

# Top (live)
perf top

# List events
perf list

References

    perf Documentation

    Brendan Gregg's Perf

    ARM64 Perf Events

    Rockchip RK3568 PMU

text


---

### `docs/ftrace-guide.md`
```markdown
# Ftrace/Trace-cmd Guide for Rock 3 Model B

## Table of Contents
1. [Introduction to Ftrace](#introduction-to-ftrace)
2. [Installation and Setup](#installation-and-setup)
3. [Basic Ftrace Usage](#basic-ftrace-usage)
4. [Tracers Overview](#tracers-overview)
5. [Event Tracing](#event-tracing)
6. [Function Filtering](#function-filtering)
7. [trace-cmd Usage](#trace-cmd-usage)
8. [KernelShark GUI](#kernelshark-gui)
9. [Advanced Ftrace](#advanced-ftrace)
10. [Ftrace Examples and Scripts](#ftrace-examples-and-scripts)

---

## Introduction to Ftrace

Ftrace is the official kernel tracing framework built into the Linux kernel. It allows tracing of kernel functions, events, and system behavior.

### Key Features
- Function tracing
- Function graph tracing
- Event tracing
- Stack tracing
- Trace filtering
- Trace buffers
- Real-time tracing

---

## Installation and Setup

### Kernel Configuration
```bash
# Enable ftrace in kernel config
CONFIG_FTRACE=y
CONFIG_FUNCTION_TRACER=y
CONFIG_FUNCTION_GRAPH_TRACER=y
CONFIG_EVENT_TRACING=y
CONFIG_DEBUG_FS=y
CONFIG_STACK_TRACER=y
CONFIG_IRQSOFF_TRACER=y
CONFIG_PREEMPT_TRACER=y
CONFIG_SCHED_TRACER=y

Mount debugfs
bash

# Mount debugfs
sudo mount -t debugfs none /sys/kernel/debug

# Check if mounted
mount | grep debugfs

# Add to fstab for automatic mount
echo "debugfs /sys/kernel/debug debugfs defaults 0 0" >> /etc/fstab

Check ftrace
bash

# Check ftrace directory
ls /sys/kernel/debug/tracing/

# Available tracers
cat /sys/kernel/debug/tracing/available_tracers

# Check if tracing is enabled
cat /sys/kernel/debug/tracing/tracing_on

Basic Ftrace Usage
Enable/Disable Tracing
bash

# Enable tracing
echo 1 > /sys/kernel/debug/tracing/tracing_on

# Disable tracing
echo 0 > /sys/kernel/debug/tracing/tracing_on

# Check status
cat /sys/kernel/debug/tracing/tracing_on

Set Tracer
bash

# Available tracers
cat /sys/kernel/debug/tracing/available_tracers

# Set function tracer
echo function > /sys/kernel/debug/tracing/current_tracer

# Set function graph tracer
echo function_graph > /sys/kernel/debug/tracing/current_tracer

# Reset to nop
echo nop > /sys/kernel/debug/tracing/current_tracer

View Trace
bash

# View full trace
cat /sys/kernel/debug/tracing/trace

# View trace pipe (live)
cat /sys/kernel/debug/tracing/trace_pipe

# Clear trace buffer
echo > /sys/kernel/debug/tracing/trace

Buffer Size
bash

# Set buffer size (KB)
echo 4096 > /sys/kernel/debug/tracing/buffer_size_kb

# Set total buffer size
echo 32768 > /sys/kernel/debug/tracing/buffer_total_size_kb

# Check buffer size
cat /sys/kernel/debug/tracing/buffer_size_kb

Tracers Overview
Function Tracer
bash

# Enable function tracer
echo function > /sys/kernel/debug/tracing/current_tracer
echo 1 > /sys/kernel/debug/tracing/tracing_on
sleep 1
cat /sys/kernel/debug/tracing/trace | head -50

Function Graph Tracer
bash

# Enable function graph tracer
echo function_graph > /sys/kernel/debug/tracing/current_tracer

# Set max depth
echo 5 > /sys/kernel/debug/tracing/max_graph_depth

# Enable tracing
echo 1 > /sys/kernel/debug/tracing/tracing_on
sleep 1
cat /sys/kernel/debug/tracing/trace

IRQ Off Tracer
bash

# Enable irqsoff tracer
echo irqsoff > /sys/kernel/debug/tracing/current_tracer
echo 1 > /sys/kernel/debug/tracing/tracing_on
# Run workload
sleep 1
cat /sys/kernel/debug/tracing/trace

Preempt Off Tracer
bash

# Enable preemptoff tracer
echo preemptoff > /sys/kernel/debug/tracing/current_tracer
echo 1 > /sys/kernel/debug/tracing/tracing_on
cat /sys/kernel/debug/tracing/trace

Wakeup Tracer
bash

# Enable wakeup tracer
echo wakeup > /sys/kernel/debug/tracing/current_tracer
echo 1 > /sys/kernel/debug/tracing/tracing_on
cat /sys/kernel/debug/tracing/trace

Event Tracing
List Events
bash

# List all events
ls /sys/kernel/debug/tracing/events/

# List specific subsystem
ls /sys/kernel/debug/tracing/events/sched/
ls /sys/kernel/debug/tracing/events/irq/
ls /sys/kernel/debug/tracing/events/i2c/
ls /sys/kernel/debug/tracing/events/gpio/

Enable Events
bash

# Enable single event
echo 1 > /sys/kernel/debug/tracing/events/sched/sched_switch/enable

# Enable all events in subsystem
echo 1 > /sys/kernel/debug/tracing/events/sched/enable

# Enable all events
echo 1 > /sys/kernel/debug/tracing/events/enable

# Disable events
echo 0 > /sys/kernel/debug/tracing/events/enable

Event Filtering
bash

# Set filter
echo 'prev_pid != 0' > /sys/kernel/debug/tracing/events/sched/sched_switch/filter

# Multiple conditions
echo 'prev_pid != 0 && next_pid != 0' > /sys/kernel/debug/tracing/events/sched/sched_switch/filter

# Clear filter
echo '' > /sys/kernel/debug/tracing/events/sched/sched_switch/filter

Common Events
bash

# Scheduler events
echo 1 > /sys/kernel/debug/tracing/events/sched/*/enable

# IRQ events
echo 1 > /sys/kernel/debug/tracing/events/irq/*/enable

# Timer events
echo 1 > /sys/kernel/debug/tracing/events/timer/*/enable

# Workqueue events
echo 1 > /sys/kernel/debug/tracing/events/workqueue/*/enable

# Power events
echo 1 > /sys/kernel/debug/tracing/events/power/*/enable

Function Filtering
Set Filters
bash

# Set function filter
echo do_sys_open > /sys/kernel/debug/tracing/set_ftrace_filter

# Multiple functions
echo do_sys_open > /sys/kernel/debug/tracing/set_ftrace_filter
echo do_sys_close >> /sys/kernel/debug/tracing/set_ftrace_filter

# Wildcard
echo 'do_sys_*' > /sys/kernel/debug/tracing/set_ftrace_filter

# View filter
cat /sys/kernel/debug/tracing/set_ftrace_filter

Ignore Functions
bash

# Ignore specific functions
echo do_sys_open > /sys/kernel/debug/tracing/set_ftrace_notrace

# View ignored functions
cat /sys/kernel/debug/tracing/set_ftrace_notrace

Stack Trace
bash

# Enable stack trace
echo 1 > /sys/kernel/debug/tracing/options/stacktrace

# Disable stack trace
echo 0 > /sys/kernel/debug/tracing/options/stacktrace

trace-cmd Usage
Install trace-cmd
bash

sudo apt install trace-cmd kernelshark

# Check version
trace-cmd --version

Record Traces
bash

# Record function graph
sudo trace-cmd record -p function_graph sleep 10

# Record with specific events
sudo trace-cmd record -e sched_switch -e irq_handler_entry sleep 10

# Record function tracing
sudo trace-cmd record -p function sleep 10

# Record with module
sudo trace-cmd record --module drm sleep 5

# Record specific PID
sudo trace-cmd record -p function -P $(pgrep process_name) sleep 10

# Record with buffer size
sudo trace-cmd record -B 8192 sleep 10

Extract Traces
bash

# Extract trace data
sudo trace-cmd extract -o trace.dat

# Extract with specific events
sudo trace-cmd extract -e sched_switch -o trace.dat

Report Traces
bash

# View report
sudo trace-cmd report -i trace.dat

# Filter by event
sudo trace-cmd report -i trace.dat -e sched_switch

# Show latency
sudo trace-cmd report -i trace.dat --latency

# CPU filtering
sudo trace-cmd report -i trace.dat --cpu 0

# Timestamp filtering
sudo trace-cmd report -i trace.dat --ts-diff

# Save as text
sudo trace-cmd report -i trace.dat > trace.txt

Record and Report
bash

# Record and report in one command
sudo trace-cmd record -p function_graph sleep 5 && sudo trace-cmd report

KernelShark GUI
Install and Run
bash

# Install KernelShark
sudo apt install kernelshark

# Open trace file
kernelshark trace.dat

# Open with live capture
kernelshark --record

GUI Features

    Timeline view

    Event filtering

    CPU selection

    Zoom in/out

    Export to image

    Event statistics

Command Line Options
bash

# Open specific file
kernelshark trace.dat

# Record and open
kernelshark --record -p function_graph sleep 10

# Help
kernelshark --help

Advanced Ftrace
Per-CPU Buffers
bash

# Per-CPU buffer size
echo 4096 > /sys/kernel/debug/tracing/per_cpu/cpu0/buffer_size_kb

# Per-CPU tracing
echo 1 > /sys/kernel/debug/tracing/per_cpu/cpu0/tracing_on

# View per-CPU trace
cat /sys/kernel/debug/tracing/per_cpu/cpu0/trace

Trace Options
bash

# Available options
ls /sys/kernel/debug/tracing/options/

# Enable option
echo 1 > /sys/kernel/debug/tracing/options/stacktrace

# Disable option
echo 0 > /sys/kernel/debug/tracing/options/stacktrace

Dynamic Tracing
bash

# Enable dynamic tracing
echo 1 > /sys/kernel/debug/tracing/filter/on

# Set trace function
echo do_sys_open > /sys/kernel/debug/tracing/filter/trace_functions

Trace Statistics
bash

# View trace statistics
cat /sys/kernel/debug/tracing/trace_stat/function*

# View per-CPU statistics
cat /sys/kernel/debug/tracing/trace_stat/per_cpu/*

Ftrace Examples and Scripts
Example 1: Function Tracing
bash

#!/bin/bash
# trace-function.sh - Trace function calls

echo "Starting function trace"
echo function > /sys/kernel/debug/tracing/current_tracer
echo 1 > /sys/kernel/debug/tracing/tracing_on

# Run workload
sleep 2

echo 0 > /sys/kernel/debug/tracing/tracing_on
echo nop > /sys/kernel/debug/tracing/current_tracer
cat /sys/kernel/debug/tracing/trace > trace.log
echo "Trace saved to trace.log"

Example 2: Event Tracing
bash

#!/bin/bash
# trace-events.sh - Trace specific events

echo "Starting event trace"
echo 1 > /sys/kernel/debug/tracing/events/sched/*/enable
echo 1 > /sys/kernel/debug/tracing/events/irq/*/enable
echo 1 > /sys/kernel/debug/tracing/tracing_on

# Run workload
sleep 2

echo 0 > /sys/kernel/debug/tracing/tracing_on
cat /sys/kernel/debug/tracing/trace > events.log
echo "Events saved to events.log"

Example 3: trace-cmd Script
bash

#!/bin/bash
# trace-cmd-script.sh - Use trace-cmd

echo "Recording trace..."
sudo trace-cmd record -p function_graph -e sched_switch -e irq_handler_entry sleep 5

echo "Extracting trace..."
sudo trace-cmd extract -o trace.dat

echo "Generating report..."
sudo trace-cmd report -i trace.dat > trace_report.txt

echo "Opening KernelShark..."
kernelshark trace.dat

Example 4: Function Filtering
bash

#!/bin/bash
# filter-function.sh - Filter specific functions

echo "Setting function filter"
echo 'do_sys_open' > /sys/kernel/debug/tracing/set_ftrace_filter
echo function > /sys/kernel/debug/tracing/current_tracer
echo 1 > /sys/kernel/debug/tracing/tracing_on

# Run workload
sleep 2

echo 0 > /sys/kernel/debug/tracing/tracing_on
cat /sys/kernel/debug/tracing/trace | grep "do_sys_open" > filtered_trace.log
echo "Filtered trace saved"

Example 5: Real-time Monitoring
bash

#!/bin/bash
# realtime-monitor.sh - Monitor ftrace in real-time

echo "Real-time tracing (Ctrl+C to stop)"
echo function_graph > /sys/kernel/debug/tracing/current_tracer
echo 1 > /sys/kernel/debug/tracing/tracing_on

# Display trace pipe
cat /sys/kernel/debug/tracing/trace_pipe

Example 6: Peripheral Trace
bash

#!/bin/bash
# trace-peripheral.sh - Trace specific peripherals

PERIPHERAL=$1

case $PERIPHERAL in
    i2c)
        sudo trace-cmd record -e i2c:* -e i2c_smbus:* sleep 10
        ;;
    spi)
        sudo trace-cmd record -e spi:* sleep 10
        ;;
    gpio)
        sudo trace-cmd record -e gpio:* sleep 10
        ;;
    usb)
        sudo trace-cmd record -e usb:* sleep 10
        ;;
    net)
        sudo trace-cmd record -e net:* -e sock:* sleep 10
        ;;
    *)
        echo "Usage: $0 {i2c|spi|gpio|usb|net}"
        exit 1
        ;;
esac

sudo trace-cmd report -i trace.dat

Troubleshooting
Permission Issues
bash

# Check permissions
ls -la /sys/kernel/debug/tracing/

# Run as root
sudo su -
# OR add user to debug group
sudo usermod -a -G debug $USER

No Trace Output
bash

# Check tracing_on
cat /sys/kernel/debug/tracing/tracing_on

# Check current_tracer
cat /sys/kernel/debug/tracing/current_tracer

# Check events
ls /sys/kernel/debug/tracing/events/*/enable

Buffer Full
bash

# Clear buffer
echo > /sys/kernel/debug/tracing/trace

# Increase buffer size
echo 8192 > /sys/kernel/debug/tracing/buffer_size_kb

Quick Reference
bash

# Basic ftrace
echo function > /sys/kernel/debug/tracing/current_tracer
echo 1 > /sys/kernel/debug/tracing/tracing_on
cat /sys/kernel/debug/tracing/trace
echo 0 > /sys/kernel/debug/tracing/tracing_on

# trace-cmd
sudo trace-cmd record -p function_graph sleep 10
sudo trace-cmd report -i trace.dat

# Events
echo 1 > /sys/kernel/debug/tracing/events/sched/*/enable

# Filters
echo function_name > /sys/kernel/debug/tracing/set_ftrace_filter

# KernelShark
kernelshark trace.dat

References

    Ftrace Documentation

    trace-cmd Documentation

    KernelShark Documentation

    Linux Tracing Wiki

text


---

### `docs/peripheral-debug.md`
```markdown
# Peripheral Debugging Guide for Rock 3 Model B

## Table of Contents
1. [I2C Debugging](#i2c-debugging)
2. [SPI Debugging](#spi-debugging)
3. [GPIO Debugging](#gpio-debugging)
4. [HDMI Debugging](#hdmi-debugging)
5. [Ethernet Debugging](#ethernet-debugging)
6. [USB Debugging](#usb-debugging)
7. [PWM Debugging](#pwm-debugging)
8. [Temperature Monitoring](#temperature-monitoring)
9. [Peripheral Verification Script](#peripheral-verification-script)
10. [Troubleshooting Guide](#troubleshooting-guide)

---

## I2C Debugging

### Basic Commands
```bash
# Install I2C tools
sudo apt install i2c-tools

# List I2C buses
i2cdetect -l

# Scan bus for devices
i2cdetect -y 1
i2cdetect -r -y 1

# Read from device
i2cget -y 1 0x50 0x00

# Write to device
i2cset -y 1 0x50 0x00 0xFF

# Dump all registers
i2cdump -y 1 0x50

# Read multiple bytes
i2ctransfer -y 1 w1@0x50 0x00 r8

# Read with block
i2ctransfer -y 1 w2@0x50 0x00 0x01 r8

Trace I2C Traffic
bash

# Using ftrace
sudo trace-cmd record -e i2c:* -e i2c_smbus:* sleep 10
sudo trace-cmd report | grep i2c

# Using dynamic debug
echo 'file drivers/i2c/* +p' > /sys/kernel/debug/dynamic_debug/control
dmesg -w | grep i2c

# Using perf
perf record -e i2c:* -a sleep 10
perf report

I2C Device Detection
bash

#!/bin/bash
# detect-i2c.sh - Detect I2C devices

BUS=${1:-1}
echo "Scanning I2C bus $BUS..."
i2cdetect -y $BUS

echo ""
echo "Detected devices:"
i2cdetect -y $BUS | grep -E " [0-9a-f]{2} " | \
    awk '{for(i=2;i<=NF;i++) if($i!="--") print "  0x"$i}'

SPI Debugging
Basic Commands
bash

# Install SPI tools
sudo apt install spidev-tools

# List SPI devices
ls /dev/spi*

# Show SPI settings
cat /sys/class/spi_master/spi*/device/*/modalias

# Test SPI communication
spidev_test -D /dev/spidev0.0 -v

# Send/receive data
spidev_test -D /dev/spidev0.0 -s 1000000 -p "\x01\x02\x03"

# With specific mode
spidev_test -D /dev/spidev0.0 -m 0 -b 8 -s 1000000 -p "\x01"

Trace SPI Traffic
bash

# Using ftrace
sudo trace-cmd record -e spi:* sleep 10
sudo trace-cmd report | grep spi

# Using dynamic debug
echo 'file drivers/spi/* +p' > /sys/kernel/debug/dynamic_debug/control
dmesg -w | grep spi

# Trace with specific device
sudo trace-cmd record -e spi:spi_transfer_start -e spi:spi_transfer_stop sleep 10

GPIO Debugging
Basic Commands
bash

# Export GPIO
echo 17 > /sys/class/gpio/export

# Set direction
echo out > /sys/class/gpio/gpio17/direction
echo in > /sys/class/gpio/gpio17/direction

# Read/Write value
echo 1 > /sys/class/gpio/gpio17/value
cat /sys/class/gpio/gpio17/value

# Un-export
echo 17 > /sys/class/gpio/unexport

# List all GPIOs
ls /sys/class/gpio/gpio*

# Check GPIO direction
cat /sys/class/gpio/gpio17/direction

Monitor GPIO Events
bash

# Using gpio-monitor
gpio-monitor -t 1 17

# Using inotify
inotifywait -m /sys/class/gpio/gpio17/value

# Using udev
udevadm monitor --property --subsystem-match=gpio

# Trace GPIO events
sudo trace-cmd record -e gpio:* sleep 10
sudo trace-cmd report | grep gpio

# Dynamic debug
echo 'file drivers/gpio/* +p' > /sys/kernel/debug/dynamic_debug/control
dmesg -w | grep gpio

GPIO Script
bash

#!/bin/bash
# gpio-monitor.sh - Monitor GPIO pin

PIN=${1:-17}
INTERVAL=${2:-1}

echo "Monitoring GPIO$PIN (Ctrl+C to stop)"

while true; do
    if [ -f /sys/class/gpio/gpio$PIN/value ]; then
        VALUE=$(cat /sys/class/gpio/gpio$PIN/value)
        echo "$(date): GPIO$PIN = $VALUE"
    else
        echo "GPIO$PIN not exported"
        exit 1
    fi
    sleep $INTERVAL
done

HDMI Debugging
Basic Commands
bash

# Check HDMI status
cat /sys/class/drm/card0-HDMI-A-1/status

# Check EDID
cat /sys/class/drm/card0-HDMI-A-1/edid > edid.bin

# Parse EDID
edid-decode edid.bin

# Set resolution
xrandr --output HDMI-1 --mode 1920x1080

# Get display information
xrandr -q

# Force HDMI detection
echo detect > /sys/class/drm/card0-HDMI-A-1/status

Trace HDMI/DRI
bash

# Trace HDMI events
sudo trace-cmd record -e drm:* -e dw_hdmi:* sleep 10
sudo trace-cmd report | grep hdmi

# Kernel messages
dmesg | grep -i hdmi
dmesg -w | grep -i hdmi

# DRM debugging
echo 'file drivers/gpu/drm/* +p' > /sys/kernel/debug/dynamic_debug/control

Ethernet Debugging
Basic Commands
bash

# Show interface status
ip link show eth0
ethtool eth0

# Show statistics
ethtool -S eth0

# Show MAC address
ip link show eth0 | grep ether

# Show speed/duplex
ethtool eth0 | grep Speed
ethtool eth0 | grep Duplex

# Set speed/duplex
ethtool -s eth0 speed 1000 duplex full

# Show PHY information
ethtool -m eth0

Network Traffic Analysis
bash

# Capture network traffic
tcpdump -i eth0 -c 10

# Save to file
tcpdump -i eth0 -w capture.pcap

# Read capture
tcpdump -r capture.pcap

# Filter by port
tcpdump -i eth0 port 80

# Filter by host
tcpdump -i eth0 host 192.168.1.100

# Trace network events
sudo trace-cmd record -e net:* -e sock:* sleep 10
sudo trace-cmd report | grep net

USB Debugging
Basic Commands
bash

# List USB devices
lsusb
lsusb -t
lsusb -v

# Show USB tree
lsusb -t

# USB power management
ls /sys/bus/usb/devices/*/power/

# USB bandwidth
cat /sys/bus/usb/devices/*/speed

# USB device details
udevadm info -a -n /dev/bus/usb/001/001

Trace USB
bash

# Trace USB events
sudo trace-cmd record -e usb:* sleep 10
sudo trace-cmd report | grep usb

# Kernel messages
dmesg | grep -i usb
dmesg -w | grep -i usb

# USB debugging
echo 'file drivers/usb/* +p' > /sys/kernel/debug/dynamic_debug/control

PWM Debugging
Basic Commands
bash

# Export PWM
echo 0 > /sys/class/pwm/pwmchip0/export

# Set period (ns)
echo 1000000 > /sys/class/pwm/pwm0/period

# Set duty cycle (ns)
echo 500000 > /sys/class/pwm/pwm0/duty_cycle

# Enable
echo 1 > /sys/class/pwm/pwm0/enable

# Disable
echo 0 > /sys/class/pwm/pwm0/enable

# Unexport
echo 0 > /sys/class/pwm/pwmchip0/unexport

# Check PWM status
cat /sys/class/pwm/pwm0/{period,duty_cycle,enable}

Trace PWM
bash

# Kernel messages
dmesg | grep -i pwm

# Trace PWM events
sudo trace-cmd record -e pwm:* sleep 10
sudo trace-cmd report | grep pwm

Temperature Monitoring
Basic Commands
bash

# CPU temperature
cat /sys/class/thermal/thermal_zone0/temp

# GPU temperature
cat /sys/class/thermal/thermal_zone1/temp

# All thermal zones
for zone in /sys/class/thermal/thermal_zone*/; do
    echo "$(basename $zone): $(cat $zone/temp)°C"
done

# Watch temperatures
watch -n 1 'for z in /sys/class/thermal/thermal_zone*/; do echo "$(basename $z): $(($(cat $z/temp)/1000))°C"; done'

Temperature Monitoring Script
bash

#!/bin/bash
# temperature-monitor.sh - Monitor temperatures

INTERVAL=${1:-5}

echo "Temperature Monitor (interval: ${INTERVAL}s)"
echo "Press Ctrl+C to stop"

while true; do
    clear
    echo "=== Temperature Monitor ==="
    echo "$(date)"
    echo ""
    
    for zone in /sys/class/thermal/thermal_zone*/; do
        if [ -f "$zone/temp" ]; then
            name=$(basename "$zone")
            temp=$(cat "$zone/temp")
            temp_c=$((temp / 1000))
            temp_f=$((temp_c * 9 / 5 + 32))
            printf "%-20s %3d°C (%3d°F)\n" "$name" "$temp_c" "$temp_f"
        fi
    done
    
    sleep $INTERVAL
done

Peripheral Verification Script
bash

#!/bin/bash
# verify-peripherals.sh - Verify all peripherals

echo "=== Peripheral Verification ==="
echo ""

# Check I2C
echo "I2C buses:"
i2cdetect -l
echo ""

# Check SPI
echo "SPI devices:"
ls /dev/spi* 2>/dev/null || echo "  No SPI devices found"
echo ""

# Check GPIO
echo "GPIO available:"
ls /sys/class/gpio/gpio* 2>/dev/null || echo "  No GPIO exported"
echo ""

# Check HDMI
echo "HDMI status:"
if [ -f /sys/class/drm/card0-HDMI-A-1/status ]; then
    cat /sys/class/drm/card0-HDMI-A-1/status
else
    echo "  HDMI not found"
fi
echo ""

# Check Ethernet
echo "Ethernet status:"
if ip link show eth0 >/dev/null 2>&1; then
    ip link show eth0 | grep -q UP && echo "  eth0: UP" || echo "  eth0: DOWN"
    ethtool eth0 2>/dev/null | grep Speed || echo "  Speed: N/A"
else
    echo "  eth0 not found"
fi
echo ""

# Check USB
echo "USB devices:"
lsusb | head -5
echo ""

# Check PWM
echo "PWM channels:"
ls /sys/class/pwm/pwmchip0/pwm* 2>/dev/null || echo "  No PWM exported"
echo ""

# Check temperature
echo "Temperatures:"
for zone in /sys/class/thermal/thermal_zone*/; do
    if [ -f "$zone/temp" ]; then
        name=$(basename "$zone")
        temp=$(( $(cat "$zone/temp") / 1000 ))
        echo "  $name: ${temp}°C"
    fi
done
echo ""

echo "=== Verification Complete ==="

Troubleshooting Guide
I2C Issues
bash

# Check if I2C is enabled
dmesg | grep i2c

# Check bus permissions
ls -la /dev/i2c-*

# Add user to i2c group
sudo usermod -a -G i2c $USER

# Check I2C clock
i2cdetect -F 1

SPI Issues
bash

# Check if SPI is enabled
dmesg | grep spi

# Check device permissions
ls -la /dev/spidev*

# Add user to spi group
sudo usermod -a -G spi $USER

# Check SPI mode
cat /sys/class/spi_master/spi*/device/*/mode

GPIO Issues
bash

# Check GPIO permissions
ls -la /sys/class/gpio/

# Check GPIO direction
cat /sys/class/gpio/gpio*/direction

# Check GPIO value
cat /sys/class/gpio/gpio*/value

HDMI Issues
bash

# Force HDMI detection
echo on > /sys/class/drm/card0-HDMI-A-1/force

# Check EDID
cat /sys/class/drm/card0-HDMI-A-1/edid

# Reset HDMI
echo off > /sys/class/drm/card0-HDMI-A-1/force
echo detect > /sys/class/drm/card0-HDMI-A-1/status

Ethernet Issues
bash

# Restart network
sudo systemctl restart networking

# Reset interface
sudo ip link set eth0 down
sudo ip link set eth0 up

# Check cable
ethtool eth0 | grep Link

# Check MAC
ip link show eth0

USB Issues
bash

# Reset USB
sudo lsusb -t
sudo echo -n "0000:00:14.0" > /sys/bus/pci/drivers/xhci_hcd/unbind
sudo echo -n "0000:00:14.0" > /sys/bus/pci/drivers/xhci_hcd/bind

# Check USB power
cat /sys/bus/usb/devices/*/power/control

Quick Reference
Peripheral	Command	Description
I2C	i2cdetect -y 1	Scan I2C bus
SPI	spidev_test -D /dev/spidev0.0	Test SPI
GPIO	echo 17 > /sys/class/gpio/export	Export GPIO
HDMI	cat /sys/class/drm/card0-HDMI-A-1/status	Check HDMI
Ethernet	ethtool eth0	Check network
USB	lsusb	List USB devices
PWM	echo 1 > /sys/class/pwm/pwm0/enable	Enable PWM
Temperature	cat /sys/class/thermal/thermal_zone0/temp	Read temperature
References

    Linux I2C Tools

    Linux SPI Tools

    Linux GPIO Sysfs

    DRM Debugging

    USB Debugging

text


---

Now all the documentation files are complete with full content. Each file contains comprehensive information about debugging and analysis techniques for the Rock 3 Model B board.


