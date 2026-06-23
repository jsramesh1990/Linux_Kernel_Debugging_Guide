# Trace Data Directory

This directory stores all trace data collected from various debugging tools.

## Directory Structure



traces/
├── README.md # This file
├── dmesg/ # Kernel ring buffer logs
│ ├── boot.log # Boot-time messages
│ ├── current.log # Current kernel messages
│ └── peripheral.log # Peripheral-specific messages
├── ftrace/ # Ftrace/trace-cmd traces
│ ├── trace.dat # Binary trace data
│ ├── trace.txt # Human-readable trace
│ └── raw/ # Raw trace files
├── perf/ # Perf profiling data
│ ├── ddr.data # DDR performance data
│ ├── cpu.data # CPU profiling data
│ └── analysis/ # Analysis results
└── strace/ # System call traces
├── app.log # Application strace output
└── system.log # System-wide strace output

## Usage

### Collecting Traces

```bash
# Collect dmesg
dmesg > traces/dmesg/current.log

# Collect ftrace
sudo trace-cmd record -p function_graph sleep 10
sudo trace-cmd extract -o traces/ftrace/trace.dat

# Collect perf
perf record -a -g -F 99 sleep 10
perf script > traces/perf/cpu.data

# Collect strace
strace -f -o traces/strace/app.log ./your_app
