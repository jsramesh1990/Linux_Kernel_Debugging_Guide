# strace in Linux & Yocto

## Table of Contents

* Introduction
* What is strace?
* Why Use strace?
* How strace Works
* Where strace is Used
* Installation
* Basic Syntax
* Common Commands
* Understanding strace Output
* Common Use Cases
* Advantages
* Disadvantages
* strace vs dmesg
* strace vs ltrace
* Best Practices
* Interview Questions
* Conclusion

---

# Introduction

Debugging applications in Embedded Linux can be challenging when a program fails without providing clear error messages.

The **strace** utility is one of the most powerful debugging tools available in Linux. It allows developers to monitor and analyze the system calls made by a process and understand how an application interacts with the Linux kernel.

In Yocto-based systems, `strace` is commonly used for application debugging, performance analysis, file access verification, and troubleshooting runtime issues.

---

# What is strace?

**strace (System Trace)** is a diagnostic and debugging tool used to monitor system calls and signals exchanged between a user-space application and the Linux kernel.

It shows:

* File operations
* Process creation
* Memory allocation
* Network communication
* Signal handling
* Device access

Every interaction between an application and the kernel can be traced using strace.

---

# Why Use strace?

Developers use strace to:

* Debug application failures
* Find missing files
* Detect permission issues
* Analyze process behavior
* Monitor network activity
* Troubleshoot crashes
* Investigate performance problems
* Verify system call execution

---

# How strace Works

```text
Application
     │
     ▼
System Calls
(open, read, write, fork)
     │
     ▼
Linux Kernel
```

strace intercepts and displays system calls before they are executed by the kernel.

---

# Where strace is Used

## Embedded Linux Development

* Application debugging
* Runtime issue analysis
* Startup troubleshooting

## Yocto Development

* Package validation
* Dependency verification
* Root filesystem debugging

## Device Driver Testing

* Device node access
* IOCTL verification

## System Administration

* Process troubleshooting
* Service debugging

---

# Installation

Check if strace is available:

```bash
which strace
```

In Yocto image:

```bitbake
IMAGE_INSTALL += "strace"
```

Build image:

```bash
bitbake core-image-minimal
```

---

# Basic Syntax

Trace a command:

```bash
strace <command>
```

Example:

```bash
strace ls
```

---

# Common Commands

## Trace a Command

```bash
strace ls
```

Displays all system calls used by `ls`.

---

## Trace a Running Process

Find PID:

```bash
ps -ef
```

Attach strace:

```bash
strace -p 1234
```

Where:

```text
1234 = Process ID
```

---

## Save Output to File

```bash
strace -o trace.log ls
```

Output stored in:

```text
trace.log
```

---

## Trace File Operations Only

```bash
strace -e trace=file ls
```

Example output:

```text
openat()
read()
close()
```

---

## Trace Network Calls

```bash
strace -e trace=network ping google.com
```

Shows:

```text
socket()
connect()
sendto()
recvfrom()
```

---

## Trace Process Creation

```bash
strace -e trace=process ./app
```

Shows:

```text
fork()
execve()
clone()
```

---

## Count System Calls

```bash
strace -c ls
```

Provides statistics:

```text
% time
calls
errors
```

Useful for performance analysis.

---

## Follow Child Processes

```bash
strace -f ./app
```

Traces:

* Parent process
* Child processes
* Forked processes

---

# Understanding strace Output

Example:

```text
openat(AT_FDCWD, "/etc/passwd", O_RDONLY) = 3
```

Breakdown:

### System Call

```text
openat()
```

Kernel API being invoked.

### Arguments

```text
"/etc/passwd"
O_RDONLY
```

Parameters passed to kernel.

### Return Value

```text
= 3
```

File descriptor returned.

---

# Common System Calls

## File Access

```text
open()
read()
write()
close()
```

Used for file operations.

---

## Process Management

```text
fork()
clone()
execve()
wait()
```

Used for process creation.

---

## Memory Management

```text
mmap()
munmap()
brk()
```

Used for memory allocation.

---

## Network Communication

```text
socket()
bind()
connect()
sendto()
recvfrom()
```

Used for networking.

---

# Common Use Cases

## Find Missing Files

```bash
strace ./app
```

Example:

```text
open("/etc/config.conf", O_RDONLY)
= -1 ENOENT
```

Meaning:

```text
File Not Found
```

---

## Debug Permission Errors

Example:

```text
open("/root/test", O_RDONLY)
= -1 EACCES
```

Meaning:

```text
Permission Denied
```

---

## Analyze Startup Failure

```bash
strace ./application
```

Check last failed system call.

---

## Debug Service Issues

```bash
strace -p <pid>
```

Monitor running service activity.

---

## Verify Device Access

Example:

```text
open("/dev/i2c-1", O_RDWR)
```

Useful for driver debugging.

---

# Advantages

## Easy Debugging

Shows exact system call failures.

---

## No Source Code Required

Works on compiled binaries.

---

## Runtime Analysis

Can attach to running processes.

---

## Detailed Information

Displays arguments and return values.

---

## Lightweight

Simple command-line tool.

---

# Disadvantages

## Large Output

Can generate thousands of lines.

---

## Performance Overhead

Tracing slows application execution.

---

## Kernel-Level Only

Does not show library function internals.

---

## Complex Analysis

Large traces may require filtering.

---

# strace vs dmesg

| Feature               | strace  | dmesg |
| --------------------- | ------- | ----- |
| Application Debugging | Yes     | No    |
| System Calls          | Yes     | No    |
| Kernel Messages       | No      | Yes   |
| Driver Messages       | Limited | Yes   |
| Process Tracing       | Yes     | No    |

---

# strace vs ltrace

| Feature              | strace | ltrace |
| -------------------- | ------ | ------ |
| System Calls         | Yes    | No     |
| Library Calls        | No     | Yes    |
| Kernel Interaction   | Yes    | No     |
| User Space Libraries | No     | Yes    |

Example:

```text
strace -> open(), read(), write()
ltrace -> printf(), malloc(), strcpy()
```

---

# Best Practices

* Save output to a file for analysis
* Use filters with `-e`
* Use `-c` for performance statistics
* Use `-f` when debugging multi-process applications
* Combine with `grep` for easier analysis
* Use alongside `dmesg` and `journalctl`

Example:

```bash
strace -o app.log -f ./app
```

---

# Interview Questions

### What is strace?

A Linux debugging tool that traces system calls and signals made by a process.

---

### What does strace monitor?

Interactions between user-space applications and the Linux kernel.

---

### How do you trace a running process?

```bash
strace -p <PID>
```

---

### How do you save output?

```bash
strace -o trace.log ./app
```

---

### How do you trace child processes?

```bash
strace -f ./app
```

---

### How do you trace only file operations?

```bash
strace -e trace=file ./app
```

---

### What is the difference between strace and ltrace?

* strace traces system calls.
* ltrace traces library function calls.

---

# Conclusion

`strace` is one of the most important debugging tools in Linux and Yocto development. It allows developers to monitor system calls, diagnose application failures, identify missing files, analyze permissions issues, and troubleshoot runtime behavior. Because it works without source code and can attach to running processes, it is an essential tool for Embedded Linux engineers.

### Quick Interview Answer

> **strace** is a Linux debugging utility that traces system calls and signals made by a process. It helps developers understand how an application interacts with the kernel, making it useful for debugging crashes, missing files, permission errors, networking issues, and runtime failures in Yocto and Embedded Linux systems.
