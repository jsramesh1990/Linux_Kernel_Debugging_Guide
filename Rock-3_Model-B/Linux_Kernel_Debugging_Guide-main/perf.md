# perf in Linux & Yocto

## Table of Contents

* Introduction
* What is perf?
* Why Use perf?
* How perf Works
* Components of perf
* Where perf is Used
* Installation
* Basic Syntax
* Common Commands
* Understanding perf Output
* Common Use Cases
* Advantages
* Disadvantages
* perf vs strace
* perf vs top
* Best Practices
* Interview Questions
* Conclusion

---

# Introduction

Performance optimization is a critical part of Embedded Linux development. Applications may consume excessive CPU resources, experience latency issues, or suffer from inefficient code paths.

The Linux **perf** tool is a powerful performance analysis framework that helps developers identify bottlenecks in applications, libraries, kernel code, and system behavior.

In Yocto-based embedded systems, `perf` is widely used for profiling CPU usage, analyzing performance issues, and optimizing software.

---

# What is perf?

**perf** is a Linux performance analysis tool that provides access to hardware and software performance counters.

It can measure:

* CPU utilization
* Function execution time
* Cache misses
* Context switches
* Branch predictions
* Memory accesses
* Kernel events
* Application hotspots

It helps identify where system resources are being consumed.

---

# Why Use perf?

Developers use perf to:

* Profile applications
* Find CPU bottlenecks
* Optimize performance
* Analyze kernel behavior
* Monitor hardware events
* Measure execution time
* Detect cache inefficiencies
* Improve system responsiveness

---

# How perf Works

```text
Application
     │
     ▼
CPU Execution
     │
     ▼
Hardware/Software Counters
     │
     ▼
perf Collects Data
     │
     ▼
Performance Report
```

The Linux kernel collects performance statistics using Performance Monitoring Units (PMUs) and exposes them through the perf framework.

---

# Components of perf

## Hardware Counters

Provided by CPU hardware.

Examples:

* CPU cycles
* Instructions executed
* Cache misses
* Branch misses

---

## Software Counters

Provided by the Linux kernel.

Examples:

* Context switches
* CPU migrations
* Page faults

---

## Tracepoints

Kernel-defined monitoring points.

Used to analyze:

* Scheduler activity
* Interrupts
* Filesystem operations

---

## Events

Everything monitored by perf is called an event.

Examples:

```text
cpu-cycles
instructions
cache-misses
page-faults
```

---

# Where perf is Used

## Embedded Linux Development

* Application optimization
* Performance tuning
* CPU profiling

## Yocto Development

* Benchmarking
* BSP optimization
* Driver performance analysis

## Kernel Development

* Scheduler analysis
* Interrupt latency measurement

## Production Systems

* Resource monitoring
* Bottleneck detection

---

# Installation

Check availability:

```bash
which perf
```

Add to Yocto image:

```bitbake
IMAGE_INSTALL += "perf"
```

Build image:

```bash
bitbake core-image-minimal
```

---

# Basic Syntax

```bash
perf <command>
```

Example:

```bash
perf stat ls
```

---

# Common Commands

## Display Performance Statistics

```bash
perf stat ls
```

Example output:

```text
1,234 CPU cycles
567 instructions
2 cache misses
```

Shows overall performance counters.

---

## Record Performance Data

```bash
perf record ./application
```

Collects execution samples.

Output:

```text
perf.data
```

---

## Generate Performance Report

```bash
perf report
```

Displays:

* Hot functions
* CPU usage
* Call graphs

---

## Profile Running Process

```bash
perf record -p <PID>
```

Example:

```bash
perf record -p 1234
```

---

## Monitor CPU Events

```bash
perf stat -e cpu-cycles ./application
```

---

## Monitor Cache Misses

```bash
perf stat -e cache-misses ./application
```

---

## Monitor Instructions Executed

```bash
perf stat -e instructions ./application
```

---

## Display Available Events

```bash
perf list
```

Lists all supported events.

---

## Real-Time Monitoring

```bash
perf top
```

Similar to:

```bash
top
```

but focused on CPU hotspots and function-level profiling.

---

# Understanding perf Output

Example:

```text
1,000,000 cpu-cycles
500,000 instructions
50 cache-misses
```

### CPU Cycles

Number of processor cycles consumed.

---

### Instructions

Number of executed instructions.

---

### Cache Misses

Memory accesses not found in CPU cache.

---

### IPC (Instructions Per Cycle)

Calculated as:

```text
IPC = Instructions / CPU Cycles
```

Higher IPC usually indicates better CPU efficiency.

---

# Common Use Cases

## Find CPU Hotspots

Record:

```bash
perf record ./app
```

Analyze:

```bash
perf report
```

Shows functions consuming most CPU time.

---

## Measure Application Performance

```bash
perf stat ./app
```

Useful for benchmarking.

---

## Analyze Cache Problems

```bash
perf stat -e cache-misses ./app
```

Detects inefficient memory access patterns.

---

## Monitor Running Service

```bash
perf record -p <PID>
```

Analyzes live applications.

---

## Kernel Profiling

```bash
perf record -g
```

Captures call graphs.

Useful for:

* Scheduler analysis
* Driver optimization
* Interrupt latency analysis

---

# Common Events

| Event               | Description               |
| ------------------- | ------------------------- |
| cpu-cycles          | CPU cycles consumed       |
| instructions        | Instructions executed     |
| cache-references    | Cache accesses            |
| cache-misses        | Cache misses              |
| branch-instructions | Branch instructions       |
| branch-misses       | Failed branch predictions |
| page-faults         | Memory page faults        |
| context-switches    | Process switches          |

---

# Advantages

## Low Overhead

Minimal impact on running systems.

---

## Hardware-Level Visibility

Uses CPU performance counters.

---

## Application Profiling

Identifies CPU-intensive functions.

---

## Kernel Profiling

Analyzes kernel behavior.

---

## Detailed Reports

Provides function-level analysis.

---

## Real-Time Monitoring

Supports live profiling.

---

# Disadvantages

## Learning Curve

Many commands and options.

---

## Hardware Dependency

Available events depend on CPU architecture.

---

## Complex Analysis

Interpreting reports may require experience.

---

## Root Privileges

Some profiling features require elevated permissions.

---

# perf vs strace

| Feature              | perf | strace  |
| -------------------- | ---- | ------- |
| Performance Analysis | Yes  | Limited |
| System Calls         | No   | Yes     |
| CPU Profiling        | Yes  | No      |
| Function Profiling   | Yes  | No      |
| Runtime Overhead     | Low  | Higher  |

---

# perf vs top

| Feature                 | perf | top |
| ----------------------- | ---- | --- |
| CPU Usage               | Yes  | Yes |
| Function-Level Analysis | Yes  | No  |
| Profiling               | Yes  | No  |
| Hardware Counters       | Yes  | No  |
| Hotspot Detection       | Yes  | No  |

---

# Best Practices

* Use `perf stat` for quick measurements
* Use `perf record` and `perf report` together
* Profile production-like workloads
* Focus on CPU hotspots first
* Analyze cache misses for optimization
* Use call graphs (`-g`) for deeper analysis
* Compare results before and after optimization

Example:

```bash
perf record -g ./application
perf report
```

---

# Interview Questions

### What is perf?

A Linux performance analysis tool used to profile applications, kernel code, and hardware events.

---

### What does perf measure?

* CPU cycles
* Instructions
* Cache misses
* Page faults
* Context switches
* Function execution time

---

### How do you profile an application?

```bash
perf record ./application
```

---

### How do you generate a report?

```bash
perf report
```

---

### How do you monitor a running process?

```bash
perf record -p <PID>
```

---

### What is `perf top`?

A real-time performance monitoring tool that displays CPU hotspots.

---

### What is the difference between perf and strace?

* perf measures performance and CPU behavior.
* strace traces system calls.

---

# Conclusion

`perf` is one of the most powerful Linux performance analysis tools available for Yocto and Embedded Linux development. It provides deep insight into CPU usage, function execution, cache behavior, and kernel activity, helping developers identify bottlenecks and optimize system performance. Understanding `perf` is essential for embedded engineers working on high-performance Linux systems.

### Quick Interview Answer

> **perf** is a Linux performance profiling and analysis tool that uses hardware and software performance counters to measure CPU cycles, instructions, cache misses, and other system events. It is commonly used in Yocto and Embedded Linux systems to identify performance bottlenecks, profile applications, and optimize system behavior.
