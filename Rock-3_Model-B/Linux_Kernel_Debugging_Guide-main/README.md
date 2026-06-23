
# Linux Kernel Debugging Guide

[![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
[![Kernel Version](https://img.shields.io/badge/Kernel-5.x%20%7C%206.x-red.svg)](https://www.kernel.org)
[![Debugging Tools](https://img.shields.io/badge/Tools-GDB%20%7C%20KGDB%20%7C%20Ftrace%20%7C%20Perf-green.svg)](https://www.kernel.org/doc/html/latest/admin-guide/debugging.html)
[![Difficulty](https://img.shields.io/badge/Difficulty-Advanced-orange.svg)]()

> **"Debugging is twice as hard as writing the code in the first place. Therefore, if you write the code as cleverly as possible, you are, by definition, not smart enough to debug it."** — Brian Kernighan

---

# What is Kernel Debugging?

## Core Terminology

| Term | Definition |
|------|------------|
| **Kernel Debugging** | The process of identifying, analyzing, and fixing bugs in the Linux kernel - a privileged environment where a single mistake can crash the entire system. |
| **Oops** | An unexpected kernel error that doesn't necessarily crash the system but indicates a serious issue (e.g., NULL pointer dereference). |
| **Panic** | A fatal kernel error that stops all system activity (the kernel "gives up"). The system hangs or reboots. |
| **Call Trace** | A stack dump showing the sequence of function calls leading to an error. |
| **Symbol** | A human-readable name for a kernel function or variable (e.g., `do_fork`, `kmalloc`). |
| **kallsyms** | The kernel symbol table - maps addresses to symbolic names. |
| **Breakpoint** | A point in code where execution stops for inspection. |
| **Watchpoint** | A breakpoint triggered when memory at a specific address is accessed. |

## Types of Kernel Bugs

```
┌─────────────────────────────────────────────────────────────────┐
│                    KERNEL BUG TAXONOMY                          │
├─────────────────────────────────────────────────────────────────┤
│ • NULL Pointer Dereference  → "Oops: unable to handle kernel    │
│    (most common)               NULL pointer dereference"        │
│                                                                 │
│ • Use-After-Free            → "BUG: KASAN: use-after-free"      │
│    (memory corruption)                                          │
│                                                                 │
│ • Double Free               → "kernel BUG at mm/slub.c:XXX"     │
│                                                                 │
│ • Race Condition           → "BUG: spinlock lockup suspected"   │
│    (locking bugs)                                               │
│                                                                 │
│ • Stack Overflow            → "Kernel stack overflow detected"  │
│                                                                 │
│ • Memory Leak               → kmemleak report                   │
│                                                                 │
│ • Deadlock                  → "INFO: possible recursive         │
│                                 locking detected"               │
│                                                                 │
│ • Scheduling Latency        → Scheduling dmesg warnings         │
└─────────────────────────────────────────────────────────────────┘
```

---

# Why Kernel Debugging is Different

## Challenges Unique to Kernel Debugging

| Challenge | User-Space | Kernel-Space |
|-----------|------------|--------------|
| **Crash Impact** | Only one process dies | Entire system crashes |
| **Debugger Access** | Easy (ptrace, GDB) | Requires KGDB or serial |
| **Memory Protection** | MMU protects processes | No protection (privileged) |
| **Stack Size** | Large (8MB+) | Tiny (8KB-16KB) |
| **Printing** | `printf` to stdout | `printk` to kernel log |
| **Floating Point** | Available | Not available (ISR context) |
| **Sleeping** | Always allowed | Not allowed in atomic contexts |

## The Kernel Debugging Mindset

```
User-Space Debugging:               Kernel Debugging:
┌─────────────-────┐               ┌-───────────────--──┐
│ "My program      │               │ "The system        │
│  crashed."       │               │  crashed."         │
│ ↓                │               │ ↓                  │
│ Run under GDB    │               │ Reproduce with     │
│ ↓                │               │  debug options     │
│ Find bug         │               │ ↓                  │
│ ↓                │               │ Analyze oops/      │
│ Fix, recompile   │               │  call trace        │
│ ↓                │               │ ↓                  │
│ "Works now!"     │               │ Add printks        │
└────────────-─────┘               │ ↓                  │
                                   │ Rebuild kernel     │
                                   │ ↓                  │
                                   │ Reboot (30 sec)    │
                                   │ ↓                  │
                                   │ "Still crashes!"   │
                                   └────────────────---─┘
```

---

# Debugging Techniques Overview

## The Debugging Toolbox

```bash
┌────────────────────────────────────────────────────────────────-────┐
│                        KERNEL DEBUGGING TOOLS                       │
├──────────────┬────────────────────────────┬──────────────────────--─┤
│ Level        │ Tool                       │ Best For                │
├──────────────┼────────────────────────────┼──────────────────────--─┤
│ Simple       │ printk(), dump_stack()     │ Quick & dirty logging   │
│ Intermediate │ Dynamic Debugging          │ Runtime enable/disable  │
│              │ ftrace                     │ Function call tracing   │
│              │ kprobes                    │ Dynamic instrumentation │
│ Advanced     │ KGDB                       │ Interactive debugging   │
│              │ KASAN                      │ Memory corruption       │
│              │ lockdep                    │ Locking deadlocks       │
│ Performance  │ perf                       │ Profiling               │
│              │ eBPF                       │ Dynamic tracing         │
└──────────────┴────────────────────────────┴──────────────────────--─┘
```

## When to Use What

```
Problem Type                    Recommended Tool
─────────────────────────────────────────────────────────────────
"Where is this function called?"    → ftrace function_graph
"Why is this variable NULL?"        → kprobe + dump_stack()
"Is memory corrupted?"              → KASAN + kmemleak
"Is there a deadlock?"              → lockdep
"Why is my driver crashing?"        → KGDB (live debugging)
"Is this line of code reached?"     → printk() + dynamic debug
"How long does this function take?" → ftrace function profiler
"Which CPU is spinning?"            → perf + softlockup detector
```

---

# printk() - The Simplest Debugger

##  Definition
**printk()** is the kernel's version of printf(). It writes messages to the kernel log buffer (`/proc/kmsg`) which can be viewed with `dmesg`.

##  Syntax
```c
#include <linux/kernel.h>
#include <linux/module.h>

// Basic usage
printk("Hello kernel world\n");

// With log levels (priority)
printk(KERN_EMERG "System is unusable\n");      // Level 0
printk(KERN_ALERT "Action must be taken\n");    // Level 1
printk(KERN_CRIT "Critical condition\n");       // Level 2
printk(KERN_ERR "Error condition\n");           // Level 3
printk(KERN_WARNING "Warning condition\n");     // Level 4
printk(KERN_NOTICE "Normal but significant\n"); // Level 5
printk(KERN_INFO "Informational\n");            // Level 6
printk(KERN_DEBUG "Debug-level messages\n");    // Level 7

// Modern style (preferred)
pr_emerg("System is unusable\n");
pr_alert("Action must be taken\n");
pr_crit("Critical condition\n");
pr_err("Error condition\n");
pr_warn("Warning condition\n");
pr_notice("Normal but significant\n");
pr_info("Informational\n");
pr_debug("Debug-level messages\n");  // Requires DEBUG defined
```

##  Explanation
- Messages are stored in a ring buffer (size configurable at boot)
- Log levels determine if message is printed to console (controlled by `printk` sysctl)
- `pr_debug()` is compiled out unless `DEBUG` is defined

##  Useful printk Formats
```c
// Standard formats
printk("Value: %d %x %lu\n", val, val, long_val);
printk("Pointer: %p\n", ptr);
printk("Hex dump: %*ph\n", 8, buffer);  // 8 bytes hex

// Function names (use with caution - increases stack)
printk("%s called from %pS\n", __func__, __builtin_return_address(0));

// Task info
printk("Current process: %s (PID %d)\n", current->comm, current->pid);
```

##  Visual Comedy
```
printk(KERN_INFO "Driver loaded\n");
                    ↓
          ┌─────────────────────┐
          │   Kernel Log Buffer │
          │   [================]│
          │   [Driver loaded   ]│
          │   [                ]│
          └─────────┬───────────┘
                    ↓
              $ dmesg | tail
              [    5.123456] Driver loaded

printk(KERN_DEBUG "x = %d\n", x);  // Invisible if debug disabled
pr_debug("Only appears if DEBUG defined\n");  // Compiler magic

"It's printf's punk rock cousin. Loud, simple, and everyone uses it." 
```

---

# Dynamic Debugging (dyndbg)

##  Definition
**Dynamic Debugging** allows enabling/disabling `pr_debug()` and `dev_dbg()` messages at runtime without recompiling the kernel.

##  Syntax
```bash
# Mount debugfs (if not already)
mount -t debugfs none /sys/kernel/debug

# Dynamic debug control file
/sys/kernel/debug/dynamic_debug/control

# Enable all debug messages in a module
echo "module mydriver +p" > /sys/kernel/debug/dynamic_debug/control

# Enable specific function in a file
echo "file drivers/mydriver.c line 100 +p" > control

# Enable for specific format string
echo "format 'buffer overrun' +p" > control

# Disable all messages in a module
echo "module mydriver -p" > control

# Enable with line range
echo "file mydriver.c line 200-300 +p" > control
```

##  In Code
```c
#include <linux/module.h>
#include <linux/device.h>

// These become dynamic
pr_debug("This message can be toggled\n");
dev_dbg(&my_device, "Device-specific debug: %d\n", val);

// Also works with custom macros
#define MY_DEBUG(fmt, ...) pr_debug(fmt, ##__VA_ARGS__)
```

##  Kernel Boot Parameters
```bash
# Enable on boot
dyndbg="module mydriver +p"
dyndbg="file drivers/usb/core/* +p"
```

##  Visual Comedy
```
Without Dynamic Debug:
    Code: pr_debug("Entering function\n");
    ↓
    Recompile kernel (30 minutes)
    Reboot
    Test
    "Still not working!"
    Add more printks...
    Recompile again...
     Infinite loop

With Dynamic Debug:
    Code: pr_debug("Entering function\n");
    ↓
    Boot kernel (has debug symbols)
    ↓
    echo "+p" > control
    ↓
    Debug output appears INSTANTLY
    ↓
    echo "-p" > control
    ↓
    Back to production!

"Like a light switch for your print statements." 
```

---

# Kernel Probes (kprobes/kretprobes)

##  Definition
**kprobes** allows dynamic instrumentation of any kernel function - inserting breakpoints that execute handler code before/after the function.

##  Syntax - kprobe
```c
#include <linux/kprobes.h>

// Kprobe handler (executes BEFORE target function)
static int handler_pre(struct kprobe *p, struct pt_regs *regs)
{
    pr_info("Before function %s\n", p->symbol_name);
    // regs->ip  = instruction pointer
    // regs->sp  = stack pointer
    // regs->ax, bx, cx... = registers
    return 0;  // 0 = continue, non-zero = skip function
}

// Kprobe post-handler (executes AFTER target function)
static void handler_post(struct kprobe *p, struct pt_regs *regs,
                         unsigned long flags)
{
    pr_info("After function %s\n", p->symbol_name);
}

// Fault handler (if target function page fault)
static int handler_fault(struct kprobe *p, struct pt_regs *regs, int trapnr)
{
    pr_warn("Fault in kprobe\n");
    return 0;
}

struct kprobe kp = {
    .symbol_name = "do_fork",  // Function to probe
    .pre_handler = handler_pre,
    .post_handler = handler_post,
    .fault_handler = handler_fault,
};

static int __init mykprobe_init(void)
{
    int ret = register_kprobe(&kp);
    if (ret < 0) {
        pr_err("Failed to register kprobe\n");
        return ret;
    }
    pr_info("Kprobe registered\n");
    return 0;
}

static void __exit mykprobe_exit(void)
{
    unregister_kprobe(&kp);
    pr_info("Kprobe unregistered\n");
}
```

##  Syntax - kretprobe (Return Probe)
```c
#include <linux/kprobes.h>

// kretprobe handler (executes when function returns)
static int ret_handler(struct kretprobe_instance *ri, struct pt_regs *regs)
{
    // regs->ax contains return value (x86)
    unsigned long retval = regs->ax;
    pr_info("do_fork returned: %ld\n", retval);
    return 0;
}

struct kretprobe kretp = {
    .handler = ret_handler,
    .maxactive = 20,  // Max simultaneous probes
    .kp.symbol_name = "do_fork",
};

static int __init mykretprobe_init(void)
{
    int ret = register_kretprobe(&kretp);
    if (ret < 0) {
        pr_err("Failed to register kretprobe\n");
        return ret;
    }
    pr_info("Kretprobe registered\n");
    return 0;
}
```

##  Command Line with kprobe-tracer
```bash
# Use dynamic kprobes via debugfs (no coding!)
echo "p:myprobe do_fork" > /sys/kernel/debug/tracing/kprobe_events
echo "r:myretprobe do_fork \$retval" >> /sys/kernel/debug/tracing/kprobe_events
echo 1 > /sys/kernel/debug/tracing/events/kprobes/myprobe/enable
cat /sys/kernel/debug/tracing/trace_pipe
```

##  Visual Comedy
```
kprobe Execution Flow:

    User Code
         ↓
    do_fork() ←─────────────────┐
         ↓                      │
    ┌─────────────────────┐     │
    │ PRE-HANDLER fires   │─────┤ "BEFORE you run..."
    │ printk("Hello")     │     │
    └─────────────────────┘     │
         ↓                      │
    do_fork() body executes      │
         ↓                      │
    ┌─────────────────────┐     │
    │ POST-HANDLER fires  │─────┤ "AFTER you run..."
    │ printk("Goodbye")   │     │
    └─────────────────────┘     │
         ↓                      │
    Return to caller ←───────────┘

"It's like putting a spy camera inside any function." 
```

---

# Ftrace - Function Tracer

##  Definition
**Ftrace** is the kernel's built-in function tracer. It can trace function calls, interrupts, scheduling events, and more with minimal overhead.

##  Syntax - Setup & Usage
```bash
# Mount tracefs
mount -t tracefs none /sys/kernel/tracing
cd /sys/kernel/tracing

# List available tracers
cat available_tracers
# Output: function_graph function nop blk wakeup_dl wakeup_rt wakeup irqsoff

# Select function tracer
echo function > current_tracer

# Select function_graph tracer (more detailed)
echo function_graph > current_tracer

# Set filter to trace only specific functions
echo do_fork > set_ftrace_filter
echo schedule >> set_ftrace_filter

# Set filter with wildcard
echo "*spin*" > set_ftrace_filter
echo "*irq*" > set_ftrace_notrace   # Exclude

# Set PID filter (trace only specific process)
echo 1234 > set_ftrace_pid

# Start tracing
echo 1 > tracing_on

# Run your workload
./my_workload

# Stop tracing
echo 0 > tracing_on

# View trace
cat trace
cat trace_pipe   # Live stream
```

##  Understanding Output
```bash
# function tracer output
# tracer: function
# entries-in-buffer/entries-written: 12345/12345
#              | |       |   ||||       |         |
#   TASK-PID   CPU#  TIMESTAMP  FUNCTION
#      | |       |      |         |
  bash-1234  [001] 12345.678910: do_fork <- syscall_trace_enter
  bash-1234  [001] 12345.678911: copy_process <-do_fork
  bash-1234  [001] 12345.678912: dup_task_struct <-copy_process

# function_graph tracer output
#  CPU  DURATION                  FUNCTION CALLS
#  |     |                           |   |   |   |
  1)   0.123 us    |  do_fork() {
  1)   0.045 us    |    copy_process() {
  1)   0.034 us    |      dup_task_struct();
  1)   0.056 us    |      copy_creds();
  1)   0.123 us    |    }
  1)   0.234 us    |  }
```

##  Advanced Ftrace Features
```bash
# Enable stack trace on function entry
echo 1 > options/func_stack_trace

# Trace kernel threads too
echo 1 > options/funcgraph-tail

# Set max depth for graph tracer
echo 5 > max_graph_depth

# Trace specific CPU only
echo 0 > tracing_cpumask   # Trace CPU 0 only
```

##  Kernel Command Line
```bash
# Enable ftrace at boot
ftrace=function
ftrace_filter=do_fork
```

##  Visual Comedy
```
Ftrace View:
    "I see every function call."

    Without Ftrace:
        do_fork() { ... } → unknown

    With Ftrace:
        do_fork() {
            copy_process() {
                dup_task_struct()
                copy_creds()
                copy_sighand()
                copy_mm()
                copy_namespaces()
            }
            wake_up_new_task()
        }

"Like X-ray vision for your kernel." 
```

---

# KGDB - Kernel GDB

##  Definition
**KGDB** (Kernel GDB) allows full interactive debugging of the Linux kernel using GDB, with breakpoints, watchpoints, single-stepping, and variable inspection.

##  Setup Requirements
```bash
# 1. Compile kernel with KGDB support
CONFIG_KGDB=y
CONFIG_KGDB_SERIAL_CONSOLE=y
CONFIG_KGDB_KDB=y
CONFIG_DEBUG_INFO=y          # Keep debug symbols
CONFIG_FRAME_POINTER=y

# 2. Boot kernel with kgdb parameters
# Target machine
kgdboc=ttyS0,115200 kgdbwait

# 3. On host machine (with same kernel source)
gdb vmlinux

# 4. Connect to target
(gdb) target remote /dev/ttyS0
```

##  GDB Commands for Kernel
```gdb
# Standard GDB commands (all work!)
break do_fork              # Break on function
break myfile.c:123         # Break at line
watch *0xffff880012345678  # Watch memory address
info break                 # List breakpoints
continue                   # Continue execution
step                       # Step into
next                       # Step over
print my_variable          # Print variable
backtrace                  # Stack trace

# Kernel-specific commands
lx-symbols                 # Load kernel module symbols
lx-dmesg                   # Print kernel log buffer
lx-current                 # Show current task
lx-ps                      # List all tasks
lx-task-by-pid 1234        # Find task by PID
lx-tid-by-pid 1234         # Thread ID by PID
```

##  Using KDB (built-in debugger)
```bash
# Enter KDB (magic sysrq)
echo g > /proc/sysrq-trigger
# Or press: Alt+SysRq+g on PS2 keyboard

# KDB commands
md <addr>                  # Memory display
mm <addr> <value>          # Memory modify
bt                         # Backtrace
ps                         # Process list
reboot                     # Reboot system
go                         # Continue execution
ss                         # Single step
bp <function>              # Set breakpoint
bl                         # List breakpoints
```

##  Visual Comedy
```
KGDB Experience:

Host Machine:                Target Machine:
┌─────────────┐             ┌─────────────┐
│   GDB       │             │   Kernel    │
│   "break    │  ──Serial── │   (frozen)  │
│    do_fork" │             │   "Waiting  │
│   "continue"│             │    for GDB" │
└─────────────┘             └─────────────┘
       ↓                           ↓
   "do_fork hit!"              *FREEZE*
       ↓                           ↓
   "print arg"                  
       ↓                           ↓
   "step into"                  🚶
       ↓                           ↓
   "continue"                   

"It's like having a remote control for the kernel.
Press pause, inspect everything, press play." 
```

---

# KASAN - Kernel Address Sanitizer

##  Definition
**KASAN** (Kernel Address SANitizer) is a dynamic memory error detector that catches use-after-free, out-of-bounds, and other memory bugs.

##  Setup
```bash
CONFIG_KASAN=y
CONFIG_KASAN_GENERIC=y   # or CONFIG_KASAN_SW_TAGS
CONFIG_KASAN_INLINE=y    # Better performance
CONFIG_KASAN_EXTRA=y     # More checks
CONFIG_KASAN_STACK=1     # Check stack variables
```

##  What KASAN Detects
```c
// KASAN catches these:
buffer[100] = 1;              // Out of bounds
ptr = kmalloc(32); free(ptr); *ptr = 1;  // Use-after-free
kmalloc(-1);                  // Invalid size
memcpy(dest, src, huge_len);  // Memory overlap
```

##  Example Report
```
==================================================================
BUG: KASAN: use-after-free in my_function+0x123/0x456
Read of size 4 at addr ffff888012345678 by task bash/1234

CPU: 1 PID: 1234 Comm: bash Not tainted 5.10.0
Hardware name: QEMU Standard PC

Call Trace:
 dump_stack+0x74/0x92
 print_address_description+0x7f/0x260
 kasan_report+0x187/0x1a0
 my_function+0x123/0x456
 ...

Freed by task 1234:
 kasan_save_stack+0x1f/0x40
 kasan_set_track+0x1f/0x40
 kasan_set_free_info+0x20/0x40
 ____kasan_slab_free+0x156/0x170
 kfree+0xd3/0x2b0
 my_free_function+0x45/0x60
 ...

Last potentially related work creation:
 kasan_save_stack+0x1f/0x40
 kasan_record_aux_stack+0xa0/0xc0
 kmem_cache_alloc_trace+0x15b/0x740
 my_alloc_function+0x45/0x80
 ...

The buggy address belongs to the object at ffff888012345678
 which belongs to the cache kmalloc-128 of size 128
The buggy address is located 0 bytes inside of
 128-byte region [ffff888012345678, ffff8880123456f8)
==================================================================
```

##  Visual Comedy
```
Without KASAN:
    Use-after-free → Silent corruption → Crash hours later
    "Where did that come from?" 

With KASAN:
    Use-after-free → IMMEDIATE DETECTION
    "Freed at line 100, used at line 150"
    "Here's the stack trace"
    "Here's the allocation site"
    "Here's the freeing site"
    "Here's the guilty party" 

"KASAN is a bloodhound for memory bugs." 
```

---

# Lock Debugging (lockdep)

##  Definition
**lockdep** (Lock Dependency Validator) detects potential deadlocks, lock inversions, and incorrect lock usage in the kernel.

##  Setup
```bash
CONFIG_PROVE_LOCKING=y  # lockdep
CONFIG_LOCK_STAT=y      # Lock statistics
CONFIG_DEBUG_LOCK_ALLOC=y
CONFIG_DEBUG_SPINLOCK=y
```

##  Lockdep Reports
```bash
# Deadlock detection
=============================================
WARNING: possible circular locking dependency detected
5.10.0 #1 Tainted: G        W

my_driver_probe/1234 is trying to acquire lock:
 (&my_lock){+.+.}-{0:0}, at: my_read+0x45/0x100

but task is already holding lock:
 (&other_lock){+.+.}-{0:0}, at: my_write+0x23/0x80

which lock already depends on the new lock.

the existing dependency chain (in reverse order) is:

-> #1 (&other_lock){+.+.}-{0:0}:
       lock_acquire+0x10a/0x2a0
       _raw_spin_lock+0x2f/0x40
       my_write+0x23/0x80
       ...

-> #0 (&my_lock){+.+.}-{0:0}:
       lock_acquire+0x10a/0x2a0
       _raw_spin_lock+0x2f/0x40
       my_read+0x45/0x100
       ...

other info that might help us debug this:
 Possible unsafe locking scenario:

       CPU0                    CPU1
       ----                    ----
  lock(&other_lock);
                               lock(&my_lock);
                               lock(&other_lock);
  lock(&my_lock);

 *** DEADLOCK ***
```

##  Fixing Lockdep Warnings
```c
// Wrong (potential deadlock)
void function1(void) {
    spin_lock(&lock_a);
    spin_lock(&lock_b);
    // ...
    spin_unlock(&lock_b);
    spin_unlock(&lock_a);
}

void function2(void) {
    spin_lock(&lock_b);  // Different order!
    spin_lock(&lock_a);
    // ...
    spin_unlock(&lock_a);
    spin_unlock(&lock_b);
}

// Fix: Always acquire locks in same order
void function2(void) {
    spin_lock(&lock_a);  // Same order
    spin_lock(&lock_b);
    // ...
    spin_unlock(&lock_b);
    spin_unlock(&lock_a);
}
```

##  Visual Comedy
```
Lockdep's View of Your Code:

Thread A: [Lock L1] → [Need L2]
Thread B: [Lock L2] → [Need L1]
           ↑              ↓
           └── DEADLOCK ──┘

Lockdep: "Wait a minute... this looks familiar."
Lockdep: "CPU0 has L1 waiting for L2"
Lockdep: "CPU1 has L2 waiting for L1"
Lockdep: "That's a circular dependency!"
Lockdep: *SPAMS KERNEL LOG*

"Lockdep is the relationship counselor of the kernel.
It tells you when your locks are in a toxic relationship." 
```

---

# Memory Debugging (kmemleak, slub debug)

## kmemleak - Memory Leak Detector

###  Definition
**kmemleak** detects kernel memory leaks by scanning memory and tracking allocations.

###  Setup
```bash
CONFIG_DEBUG_KMEMLEAK=y
CONFIG_DEBUG_KMEMLEAK_EARLY_LOG_SIZE=40000

# Boot with kmemleak
kmemleak=on
```

###  Commands
```bash
# Trigger scan
echo scan > /sys/kernel/debug/kmemleak

# Show all leaks
cat /sys/kernel/debug/kmemleak

# Clear report
echo clear > /sys/kernel/debug/kmemleak
```

###  Sample Output
```
unreferenced object 0xffff880012345678 (size 256):
  comm "my_driver", pid 1234, jiffies 4294937296
  hex dump (first 32 bytes):
    01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f 10
  backtrace:
    [<ffffffff81234567>] kmem_cache_alloc_trace+0x1a7/0x200
    [<ffffffffa0001234>] my_alloc_function+0x34/0x50 [my_driver]
    [<ffffffffa0001567>] my_init+0x67/0x100 [my_driver]
```

## SLUB Debug

###  Definition
**SLUB debug** adds red zones and poisoning to detect memory corruption.

###  Setup
```bash
CONFIG_SLUB_DEBUG=y
CONFIG_SLUB_DEBUG_ON=y  # Enable by default

# Or per slab cache
slub_debug=FPZUT
# F = sanity checks, P = poisoning, Z = red zones,
# U = user tracking, T = trace
```

###  Example
```bash
# Enable for all caches
slub_debug=FPZUT

# Enable only for specific cache
slub_debug=FPZUT,kfree
```

###  Visual Comedy
```
kmemleak to Memory Leaks:
    "You allocated memory in 1995 and never freed it."
    "It's still there. Just sitting."
    "Lost, alone, unreachable."
    "Like my childhood dreams." 

SLUB Debug to Corruption:
    "Your buffer overflow wrote 0xDEADBEEF into my red zone."
    "That's not supposed to be there."
    "I'm telling lockdep about this."

"Memory debugging tools are the kernel's conscience."
```

---

# Block Diagram - Complete Debugging Flow

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           KERNEL DEBUGGING WORKFLOW                              │
└─────────────────────────────────────────────────────────────────────────────────┘

                                    ┌─────────────┐
                                    │   BUG!    │
                                    └──────┬──────┘
                                           │
                    ┌──────────────────────┼──────────────────────┐
                    │                      │                      │
                    ▼                      ▼                      ▼
            ┌───────────────┐      ┌───────────────┐      ┌───────────────┐
            │    OOPS/      │      │    PANIC      │      │   HANG/       │
            │    Call Trace  │      │               │      │   Deadlock    │
            └───────┬───────┘      └───────┬───────┘      └───────┬───────┘
                    │                      │                      │
                    ▼                      ▼                      ▼
            ┌───────────────┐      ┌───────────────┐      ┌───────────────┐
            │ dmesg /       │      │ Serial log    │      │ SysRq +      │
            │ /proc/kmsg    │      │ capture       │      │ Watchdog     │
            └───────┬───────┘      └───────┬───────┘      └───────┬───────┘
                    │                      │                      │
                    └──────────────────────┼──────────────────────┘
                                           │
                                           ▼
                              ┌─────────────────────────┐
                              │    ANALYZE CALL TRACE    │
                              │    Identify function     │
                              │    that crashed          │
                              └────────────┬────────────┘
                                           │
                    ┌──────────────────────┼──────────────────────┐
                    │                      │                      │
                    ▼                      ▼                      ▼
          ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
          │  SIMPLE BUG?    │    │  MEMORY BUG?    │    │  LOCKING BUG?   │
          │  (NULL ptr,     │    │  (UAF, OOB)     │    │  (Deadlock)     │
          │   logic error)  │    │                 │    │                 │
          └────────┬────────┘    └────────┬────────┘    └────────┬────────┘
                   │                      │                      │
                   ▼                      ▼                      ▼
          ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
          │  • printk()     │    │  • KASAN        │    │  • lockdep      │
          │  • kprobe       │    │  • kmemleak     │    │  • ftrace lock  │
          │  • ftrace       │    │  • SLUB debug   │    │    events       │
          └────────┬────────┘    └────────┬────────┘    └────────┬────────┘
                   │                      │                      │
                   └──────────────────────┼──────────────────────┘
                                          │
                                          ▼
                              ┌─────────────────────────┐
                              │   HARD TO REPRODUCE?    │
                              │   INTERMITTENT BUG?     │
                              └────────────┬────────────┘
                                           │
                        ┌──────────────────┼──────────────────┐
                        │                  │                  │
                        ▼                  ▼                  ▼
              ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
              │  • KGDB         │  │  • eBPF         │  │  • Tracepoints  │
              │  • KDB          │  │  • perf         │  │  • Systemtap    │
              │  • Live debug   │  │  • Sampling     │  │  • Kprobes      │
              └─────────────────┘  └─────────────────┘  └─────────────────┘
                                          │
                                          ▼
                              ┌─────────────────────────┐
                              │      BUG FOUND!         │
                              │    Fix → Test → Commit   │
                              └─────────────────────────┘
```

---

# Working Flow - Step by Step

## Step 1: Reproduce the Bug
```bash
# Always try to reproduce before debugging
# Create minimal test case
# Use kernel same as production
# Document reproduction steps
```

## Step 2: Enable Debug Options
```bash
# Recompile kernel with debugging
make menuconfig
# Enable:
#   Kernel hacking → 
#     Compile-time checks and compiler options →
#       [*] Compile the kernel with debug info
#     Memory Debugging →
#       [*] Kernel memory leak detector
#       [*] KASAN: runtime memory debugger
#     Lock Debugging →
#       [*] Lock debugging: prove locking correctness
```

## Step 3: Collect Initial Information
```bash
# Save complete dmesg
dmesg > crash_dmesg.txt

# Get kernel version
uname -a

# List loaded modules
lsmod

# Extract call trace from dmesg
grep -A 50 "Oops\|BUG\|WARNING\|Call Trace" crash_dmesg.txt
```

## Step 4: Locate the Problem
```bash
# Use addr2line to find source line
addr2line -e vmlinux -f 0xffffffff81234567
# Output: do_fork+0x123/0x456 /linux/kernel/fork.c:1234

# Decode module addresses
# For module: find offset
cat /proc/modules | grep mymodule
# mymodule 16384 0 - Live 0xffffffffa0000000
addr2line -e mymodule.ko -f 0x1234
```

## Step 5: Add Instrumentation
```c
// Add printk at suspicious location
printk(KERN_INFO "Entering function, arg = %d\n", arg);
dump_stack();  // Print call stack

// Check return values
if (IS_ERR(ptr)) {
    pr_err("Failed: %ld\n", PTR_ERR(ptr));
    return PTR_ERR(ptr);
}
```

## Step 6: Use Dynamic Debugging
```bash
# Enable tracing for suspect functions
echo "function do_fork" > /sys/kernel/tracing/set_ftrace_filter
echo function > /sys/kernel/tracing/current_tracer
echo 1 > /sys/kernel/tracing/tracing_on
# Reproduce bug
echo 0 > /sys/kernel/tracing/tracing_on
cat /sys/kernel/tracing/trace > ftrace_output.txt
```

## Step 7: Analyze with KGDB (if needed)
```bash
# On target:
echo ttyS0 > /sys/module/kgdboc/parameters/kgdboc
echo g > /proc/sysrq-trigger

# On host:
gdb vmlinux
(gdb) target remote /dev/ttyS0
(gdb) bt
(gdb) list
(gdb) print *ptr
```

## Step 8: Fix and Test
```c
// Apply fix
// Rebuild kernel or module
make modules
make modules_install
reboot

// Verify bug is gone
// Run regression tests
// Add kernel selftest if possible
```

---

# Common Bugs & Debugging Strategies

## 1. NULL Pointer Dereference
```c
// Symptom: "Unable to handle kernel NULL pointer dereference"
// Quick fix: Check pointer before use

// Before:
my_struct->value = 42;  // Crash if my_struct NULL

// After:
if (unlikely(!my_struct)) {
    pr_err("my_struct is NULL!\n");
    return -EINVAL;
}
my_struct->value = 42;
```

## 2. Use-After-Free
```c
// Symptom: KASAN: use-after-free
// Fix: Set pointer to NULL after free

// Before:
kfree(ptr);
// ... later
ptr->value = 42;  // Use after free

// After:
kfree(ptr);
ptr = NULL;  // Will cause NULL dereference (safer)
```

## 3. Sleeping in Atomic Context
```c
// Symptom: "BUG: sleeping function called from invalid context"
// Fix: Use GFP_ATOMIC in atomic context

// Wrong in interrupt:
kmalloc(size, GFP_KERNEL);  // Can sleep → BUG

// Correct:
kmalloc(size, GFP_ATOMIC);  // No sleeping
```

## 4. Deadlock
```c
// Symptom: lockdep report
// Fix: Consistent lock ordering

// Always acquire locks in this order:
// Lock A → Lock B → Lock C

void thread1(void) {
    mutex_lock(&lock_a);
    mutex_lock(&lock_b);  // Same order!
    // ...
}

void thread2(void) {
    mutex_lock(&lock_a);  // Same order!
    mutex_lock(&lock_b);
}
```

## 5. Stack Overflow
```c
// Symptom: "Kernel stack overflow detected"
// Fix: Reduce stack usage

// Wrong: Large local array
void bad(void) {
    char buffer[8192];  // 8KB on 8KB stack = overflow
}

// Correct: Use heap or static
void good(void) {
    static char buffer[8192];  // Static allocation
    // OR
    char *buffer = kmalloc(8192, GFP_KERNEL);
}
```

---

# Interview Preparation

## Q1: What's the difference between printk and printf?
**A:** 
- `printk` is kernel-space, `printf` is user-space
- `printk` uses log levels (KERN_INFO, KERN_ERR)
- `printk` writes to kernel ring buffer (view with `dmesg`)
- `printk` can't use floating point

## Q2: How do you debug a kernel panic that happens during boot?
**A:**
1. Use `earlyprintk` boot parameter
2. Compile with `CONFIG_DEBUG_INFO`
3. Simulate with QEMU + KGDB
4. Use `initcall_debug` to trace initialization
5. Add `printk` to early init functions

## Q3: What is the difference between kprobe and ftrace?
**A:**
- **ftrace**: Low overhead, traces function calls, built-in tracers
- **kprobe**: Can insert custom handlers, heavier, more flexible
- Both can be used together

## Q4: Explain how KASAN works.
**A:** KASAN uses a "shadow memory" region:
- 1 byte of shadow memory per 8 bytes of real memory
- Shadow byte encodes how many bytes are accessible
- On memory access, hardware checks shadow memory
- If invalid, triggers a report

## Q5: What information is in an Oops message?
**A:**
1. Register dump (all CPU registers)
2. Call trace (function call sequence)
3. Module list (loaded modules with addresses)
4. Code bytes around the faulting instruction
5. Process/thread information

## Q6: How do you debug a hard-to-reproduce race condition?
**A:**
1. Enable lockdep (detects lock ordering issues)
2. Use KASAN (catches memory races)
3. Add `dump_stack()` in suspect paths
4. Use `./scripts/decodecode` to decode Oops
5. Use ftrace with `function` tracer + filters
6. Run the test in a loop (stress testing)

## Q7: What is `CONFIG_PROVE_LOCKING`?
**A:** lockdep - validates kernel locking rules:
- Detects possible deadlocks
- Checks spinlock/mutex usage
- Validates interrupt disabling patterns
- Reports lock inversion

## Q8: How to debug a module that crashes on unload?
**A:**
1. Add `printk` to exit function
2. Use `kgdb` to break at `module_put`
3. Check reference counts: `cat /proc/modules | grep mymodule`
4. Use `slub_debug` to catch use-after-free
5. Set `module_refcount` breakpoint

## Q9: What tools can trace kernel function calls in real-time?
**A:**
- **ftrace**: Built-in, low overhead
- **perf**: Sampling profiler with call graphs
- **eBPF**: Dynamic instrumentation
- **LTTng**: Tracepoints with low overhead
- **SystemTap**: Scriptable dynamic tracing

## Q10: How do you analyze a hung task?
**A:**
1. `sysrq+t` (show all tasks with stack traces)
2. `sysrq+w` (show blocked tasks)
3. `cat /proc/{PID}/stack` (show task's kernel stack)
4. Enable softlockup detector: `softlockup_panic=1`
5. Use ftrace: `echo function > current_tracer; echo 1 > tracing_on`

---

# Quick Reference Cards

## printk Log Levels
```bash
KERN_EMERG    (0) # System unusable
KERN_ALERT    (1) # Action required
KERN_CRIT     (2) # Critical condition
KERN_ERR      (3) # Error condition
KERN_WARNING  (4) # Warning
KERN_NOTICE   (5) # Normal but significant
KERN_INFO     (6) # Informational
KERN_DEBUG    (7) # Debug messages
```

## Common SysRq Keys
```bash
Alt+SysRq+s     # Sync disks
Alt+SysRq+u     # Remount read-only
Alt+SysRq+b     # Reboot
Alt+SysRq+c     # Crash (trigger crash dump)
Alt+SysRq+t     # Show tasks
Alt+SysRq+w     # Show blocked tasks
Alt+SysRq+g     # KGDB breakpoint
```

## Ftrace Commands Cheat Sheet
```bash
cd /sys/kernel/tracing
echo function > current_tracer          # Enable tracer
echo do_fork > set_ftrace_filter       # Filter function
echo 1 > tracing_on                    # Start tracing
echo 0 > tracing_on                    # Stop
cat trace                              # View output
cat trace_pipe                         # Live stream
truncate -s 0 trace                    # Clear buffer
```

## GDB Kernel Commands
```gdb
target remote /dev/ttyS0    # Connect to target
lx-symbols                  # Load module symbols
lx-ps                       # List all tasks
lx-tid-by-pid 1234          # Task by PID
lx-current                  # Current task
lx-dmesg                    # Print kernel log
```

## Kernel Boot Debug Parameters
```bash
# Enable early printing
earlyprintk=serial,ttyS0,115200

# Disable KASLR (easier debugging)
nokaslr

# Run init with debug
initcall_debug

# Enable panic on oops
panic_on_oops=1

# Softlockup detector
softlockup_panic=1

# Disable console (for KGDB)
console=ttyS0 kgdboc=ttyS0,115200

# Ftrace at boot
ftrace=function
ftrace_filter=do_fork
```

## Debugfs Locations
```bash
/sys/kernel/debug/dynamic_debug/control    # Dynamic debug
/sys/kernel/debug/kmemleak                 # Memory leaks
/sys/kernel/debug/tracing/                 # Ftrace
/sys/kernel/debug/kprobes/                 # Kprobes
/sys/kernel/debug/dma-api/                 # DMA debugging
```

## Proc Filesystem for Debugging
```bash
/proc/kallsyms          # Kernel symbol table
/proc/modules           # Loaded modules + refcounts
/proc/meminfo           # Memory statistics
/proc/slabinfo          # Slab allocator info
/proc/locks             # Current locks
/proc/interrupts        # Interrupt statistics
/proc/softirqs         # SoftIRQ statistics
/proc/loadavg           # System load average
/proc/uptime            # Uptime + idle time
```


#  Introduction to Yocto

## Definition

The Yocto Project is an open-source embedded Linux build framework used to create custom Linux distributions for embedded hardware.

It is widely used in:

* Automotive systems
* Industrial controllers
* Robotics
* IoT gateways
* Smart displays
* Medical devices
* Networking equipment

---

## Main Goal

Yocto helps developers:

* Build complete Linux operating systems
* Cross compile for ARM/RISC-V/x86
* Customize root filesystem
* Build bootloader + kernel + packages
* Generate production-ready images

---

## Core Components

```text
Yocto Project
│
├── Poky
├── BitBake
├── Layers
├── Recipes
├── BSP
└── Metadata
```

---

#  Complete Yocto Project Creation Step-by-Step

## Objective

Create a complete embedded Linux image.

---

# Step 1 — Install Required Packages

## Ubuntu Host Dependencies

```bash
sudo apt update

sudo apt install -y \
 gawk wget git diffstat unzip texinfo gcc build-essential \
 chrpath socat cpio python3 python3-pip python3-pexpect \
 xz-utils debianutils iputils-ping python3-git python3-jinja2 \
 libegl1-mesa libsdl1.2-dev pylint xterm
```

---

# Step 2 — Download Poky

## Syntax

```bash
git clone git://git.yoctoproject.org/poky
```

## Example

```bash
git clone git://git.yoctoproject.org/poky -b kirkstone
```

## Where to Use

Use when starting a new Yocto project.

## Result

```text
poky/
├── bitbake/
├── meta/
├── meta-poky/
└── oe-init-build-env
```

---

# Step 3 — Initialize Build Environment

## Syntax

```bash
source oe-init-build-env
```

## Result

Creates:

```text
build/
├── conf/
├── downloads/
├── sstate-cache/
└── tmp/
```

---

# Step 4 — Configure Build

## File

```text
build/conf/local.conf
```

## Example

```conf
MACHINE = "qemux86-64"
BB_NUMBER_THREADS = "8"
PARALLEL_MAKE = "-j8"
```

---

# Step 5 — Build Image

## Syntax

```bash
bitbake core-image-minimal
```

## Where to Use

Used to build a minimal Linux image.

## Result

Generated files:

```text
tmp/deploy/images/
```

Contains:

* Kernel Image
* Root filesystem
* Device tree
* Bootloader
* SD card image

---

# Step 6 — Run in QEMU

## Syntax

```bash
runqemu qemux86-64
```

## Result

Linux boots inside emulator.

---

# 3. Writing Your First `.bb` Recipe

## Definition

A recipe tells BitBake how to build software.

---

# Recipe Structure

## Example

```bitbake
DESCRIPTION = "Hello World Application"
LICENSE = "MIT"

SRC_URI = "file://hello.c"

S = "${WORKDIR}"

do_compile() {
    ${CC} hello.c -o hello
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 hello ${D}${bindir}
}
```

---

# Important Variables

| Variable     | Meaning                   |
| ------------ | ------------------------- |
| `${WORKDIR}` | Temporary build directory |
| `${CC}`      | Cross compiler            |
| `${D}`       | Destination rootfs        |
| `${bindir}`  | `/usr/bin`                |

---

# Where Recipes Are Stored

```text
meta-custom/
└── recipes-apps/
    └── hello/
        ├── hello.bb
        └── hello.c
```

---

# Build Recipe

## Syntax

```bash
bitbake hello
```

---

# Add Recipe to Image

## local.conf

```conf
IMAGE_INSTALL += "hello"
```

---

# Debugging Recipe Issues

## Common Errors

| Error             | Cause              |
| ----------------- | ------------------ |
| do_compile failed | Compiler issue     |
| file not found    | SRC_URI incorrect  |
| install failed    | Wrong install path |

---

# Useful Debug Commands

```bash
bitbake hello -c devshell
```

```bash
bitbake hello -e
```

```bash
bitbake hello -c clean
```

---

# 4. Creating a Custom Layer

## Definition

Layers organize metadata and recipes.

---

# Create Layer

## Syntax

```bash
bitbake-layers create-layer meta-mycompany
```

---

# Layer Structure

```text
meta-mycompany/
├── conf/
│   └── layer.conf
├── recipes-core/
├── recipes-kernel/
└── recipes-apps/
```

---

# Add Layer to Build

## Syntax

```bash
bitbake-layers add-layer ../meta-mycompany
```

---

# Verify Layers

```bash
bitbake-layers show-layers
```

---

# layer.conf Example

```conf
BBPATH .= ":${LAYERDIR}"

BBFILES += "${LAYERDIR}/recipes-*/*/*.bb"
```

---

# Where to Use

Custom layers are used for:

* Company applications
* Drivers
* Kernel patches
* Board support
* Custom images

---

# 5. Kernel Customization in Yocto

## Definition

Kernel customization modifies:

* Drivers
* Filesystems
* Networking
* Security
* Hardware support

---

# Configure Kernel

## Syntax

```bash
bitbake virtual/kernel -c menuconfig
```

---

# Save Kernel Config

```bash
bitbake virtual/kernel -c savedefconfig
```

---

# Kernel Recipe Example

```bitbake
SRC_URI += "file://my_patch.patch"
```

---

# Add Kernel Patch

## Directory

```text
recipes-kernel/linux/
```

---

# Common Kernel Debugging

## View Logs

```bash
cat tmp/work/*/linux*/temp/log.do_compile
```

---

# Debug Kernel Boot

Use serial console:

```text
UART0 @ 115200 baud
```

---

# Common Problems

| Problem        | Cause                  |
| -------------- | ---------------------- |
| Kernel panic   | Wrong rootfs           |
| Boot hang      | Device tree issue      |
| Driver missing | Kernel config disabled |

---

# 6. Device Tree Detailed Tutorial

## Definition

Device Tree describes hardware to Linux.

Used mainly on:

* ARM
* ARM64
* RISC-V

---

# Device Tree Structure

```dts
/ {
    model = "MyBoard";

    memory {
        reg = <0x80000000 0x40000000>;
    };
};
```

---

# Common Hardware Nodes

| Node     | Purpose         |
| -------- | --------------- |
| uart     | Serial port     |
| i2c      | I2C bus         |
| spi      | SPI bus         |
| gpio     | GPIO controller |
| ethernet | Network         |

---

# UART Example

```dts
&uart0 {
    status = "okay";
    current-speed = <115200>;
};
```

---

# GPIO Example

```dts
leds {
    compatible = "gpio-leds";
};
```

---

# Compile Device Tree

## Syntax

```bash
dtc -I dts -O dtb myboard.dts -o myboard.dtb
```

---

# Debug Device Tree

## Check Loaded DT

```bash
cat /proc/device-tree/model
```

---

# Common Device Tree Errors

| Error               | Cause                   |
| ------------------- | ----------------------- |
| Device not detected | Wrong compatible string |
| Probe failed        | Incorrect GPIO/IRQ      |
| Boot crash          | Memory config wrong     |

---

# 7. BSP Development

## Definition

BSP = Board Support Package

Provides:

* Bootloader config
* Kernel config
* Device tree
* Drivers
* Firmware

---

# BSP Components

```text
meta-board/
├── recipes-bsp/
├── recipes-kernel/
├── recipes-core/
└── conf/machine/
```

---

# Machine Configuration

## Example

```conf
MACHINE = "myboard"
```

---

# Machine Config File

```text
conf/machine/myboard.conf
```

## Example

```conf
KERNEL_DEVICETREE = "myboard.dtb"
UBOOT_MACHINE = "myboard_defconfig"
```

---

# BSP Bring-Up Steps

1. Boot ROM
2. U-Boot
3. DRAM init
4. Load kernel
5. Device tree load
6. Rootfs mount
7. Linux boot

---

# BSP Debugging

## Use Serial Logs

Check:

* U-Boot logs
* Kernel logs
* Driver probe logs

---

# 8. How Linux Boots on ARM Boards

# Boot Flow

```text
Power ON
   ↓
Boot ROM
   ↓
SPL
   ↓
U-Boot
   ↓
Kernel
   ↓
Root Filesystem
   ↓
Applications
```

---

# Stage 1 — Boot ROM

Inside SoC.

Responsibilities:

* Initialize hardware
* Load bootloader

---

# Stage 2 — SPL

Small bootloader.

Tasks:

* DRAM initialization
* Load U-Boot

---

# Stage 3 — U-Boot

Tasks:

* Load kernel
* Load DTB
* Pass bootargs

Example:

```bash
booti ${kernel_addr_r} - ${fdt_addr_r}
```

---

# Stage 4 — Linux Kernel

Kernel initializes:

* Scheduler
* Memory
* Drivers
* Filesystems

---

# Stage 5 — Root Filesystem

Mounted as `/`.

Contains:

* /bin
* /etc
* /usr
* libraries

---

# Boot Debugging

## Enable Early Printk

```bash
earlycon console=ttyS0,115200
```

---

# 9. Yocto Interview Questions

# Basic Questions

## What is Yocto?

Framework to build embedded Linux distributions.

---

## What is BitBake?

Task execution engine.

---

## What is a Recipe?

Build instructions for software.

---

## What is a Layer?

Collection of recipes and metadata.

---

# Intermediate Questions

## Difference between DEPENDS and RDEPENDS?

| Type     | Meaning            |
| -------- | ------------------ |
| DEPENDS  | Build dependency   |
| RDEPENDS | Runtime dependency |

---

## What is sstate-cache?

Shared build cache.

---

## What is BSP?

Board support package.

---

# Advanced Questions

* Explain Linux boot flow.
* Explain device tree.
* Explain rootfs generation.
* Explain package management.
* Explain custom layer creation.
* Explain kernel patching.

---

# 10. Real Industrial Yocto Workflow

# Development Flow

```text
Requirements
    ↓
BSP Setup
    ↓
Kernel Customization
    ↓
Application Development
    ↓
Yocto Integration
    ↓
CI/CD Build
    ↓
Testing
    ↓
Release
```

---

# Typical Teams

| Team            | Responsibility |
| --------------- | -------------- |
| BSP Team        | Board bring-up |
| Kernel Team     | Drivers        |
| Middleware Team | Libraries      |
| App Team        | Applications   |
| QA Team         | Validation     |

---

# CI/CD Tools

Commonly used:

* Jenkins
* GitLab CI
* GitHub Actions

---

# Industrial Best Practices

* Use LTS Yocto release
* Use version pinning
* Enable reproducible builds
* Use sstate mirror
* Automate builds
* Use artifact servers

---

# 11. Buildroot vs Yocto Deep Comparison

| Feature            | Yocto     | Buildroot |
| ------------------ | --------- | --------- |
| Complexity         | High      | Medium    |
| Learning Curve     | Hard      | Easier    |
| Package Management | Yes       | Limited   |
| SDK Support        | Excellent | Basic     |
| Industrial Usage   | Very High | Medium    |
| Build Speed        | Slower    | Faster    |
| Customization      | Excellent | Moderate  |

---

# When to Use Yocto

Use Yocto for:

* Long-term products
* Large projects
* OTA systems
* Enterprise products

---

# When to Use Buildroot

Use Buildroot for:

* Simple projects
* Fast prototyping
* Small systems

---

# 12. Docker with Yocto

## Definition

Run Docker containers on embedded Linux.

---

# Enable Docker

## local.conf

```conf
DISTRO_FEATURES += " virtualization"
```

---

# Add Docker Packages

```conf
IMAGE_INSTALL += "docker"
```

---

# Start Docker

```bash
systemctl start docker
```

---

# Verify Docker

```bash
docker --version
```

---

# Run Container

```bash
docker run hello-world
```

---

# Embedded Docker Use Cases

* Edge AI
* Microservices
* Cloud gateways
* OTA applications

---

# Docker Debugging

## Check Service

```bash
systemctl status docker
```

---

# 13. OTA Update Systems in Yocto

# Definition

OTA = Over-The-Air update.

Allows remote firmware updates.

---

# Popular OTA Systems

| Tool     | Usage             |
| -------- | ----------------- |
| SWUpdate | Embedded updates  |
| RAUC     | Robust OTA        |
| Mender   | Enterprise OTA    |
| OSTree   | Immutable systems |

---

# SWUpdate Workflow

```text
Build Image
    ↓
Generate SWU Package
    ↓
Upload to Server
    ↓
Device Downloads
    ↓
Install Update
```

---

# RAUC Features

* A/B partition support
* Rollback
* Secure update

---

# OTA Best Practices

* Use dual rootfs
* Add rollback support
* Use signed images
* Use watchdogs

---

# OTA Debugging

## Check Logs

```bash
journalctl -u rauc
```

---

# 14. Debugging Yocto Build Failures

# Important Log Locations

```text
tmp/work/*/temp/
```

---

# Common Log Files

| File             | Purpose        |
| ---------------- | -------------- |
| log.do_compile   | Compile logs   |
| log.do_configure | Configure logs |
| log.do_install   | Install logs   |

---

# Useful Commands

## Clean Recipe

```bash
bitbake myapp -c clean
```

---

## Force Rebuild

```bash
bitbake myapp -f -c compile
```

---

## Open Development Shell

```bash
bitbake myapp -c devshell
```

---

# Common Build Errors

| Error            | Cause              |
| ---------------- | ------------------ |
| Fetch failed     | Internet/Git issue |
| Configure failed | Missing dependency |
| Compile failed   | Source issue       |
| Install failed   | Wrong path         |

---

# Debug Strategy

1. Read logs
2. Reproduce manually
3. Check dependencies
4. Verify patches
5. Verify layer compatibility

---

# 15. Embedded Linux Driver Development

# Driver Types

| Driver    | Purpose       |
| --------- | ------------- |
| Character | UART/I2C      |
| Block     | Storage       |
| Network   | Ethernet/WiFi |

---

# Simple Character Driver

```c
#include <linux/module.h>

static int __init hello_init(void)
{
    printk("Driver Loaded\n");
    return 0;
}

static void __exit hello_exit(void)
{
    printk("Driver Removed\n");
}

module_init(hello_init);
module_exit(hello_exit);

MODULE_LICENSE("GPL");
```

---

# Build Driver

```bash
make -C /lib/modules/$(uname -r)/build M=$(pwd) modules
```

---

# Load Driver

```bash
insmod hello.ko
```

---

# Check Logs

```bash
dmesg | tail
```

---

# Yocto Driver Integration

## Add Module Recipe

```bitbake
inherit module
```

---

# Driver Debugging

## Check Probe

```bash
dmesg | grep probe
```

---

# Common Driver Problems

| Problem      | Cause         |
| ------------ | ------------- |
| Probe failed | DT mismatch   |
| No interrupt | IRQ wrong     |
| DMA error    | Memory config |

---

# 16. End-to-End Raspberry Pi Yocto Example

# Step 1 — Clone Poky

```bash
git clone git://git.yoctoproject.org/poky
```

---

# Step 2 — Clone Raspberry Pi Layer

```bash
git clone git://git.yoctoproject.org/meta-raspberrypi
```

---

# Step 3 — Initialize Build

```bash
source oe-init-build-env
```

---

# Step 4 — Add Layer

```bash
bitbake-layers add-layer ../meta-raspberrypi
```

---

# Step 5 — Configure Machine

## local.conf

```conf
MACHINE = "raspberrypi4"
```

---

# Step 6 — Build Image

```bash
bitbake core-image-minimal
```

---

# Step 7 — Flash Image

```bash
sudo dd if=core-image-minimal.wic of=/dev/sdX bs=4M
```

---

# Step 8 — Boot Raspberry Pi

Connect:

* HDMI
* Keyboard
* SD card
* UART serial

---

# Step 9 — Verify Boot

## Check Kernel

```bash
uname -a
```

---

# Step 10 — Test GPIO

```bash
ls /sys/class/gpio
```

---

# Raspberry Pi Debugging

## No Boot

Check:

* Power supply
* SD card
* UART logs
* Correct image

---

# 17. Useful Commands Cheat Sheet

# Build Commands

```bash
bitbake core-image-minimal
```

```bash
bitbake -s
```

```bash
bitbake-layers show-layers
```

---

# Kernel Commands

```bash
bitbake virtual/kernel -c menuconfig
```

---

# Cleaning Commands

```bash
bitbake myapp -c clean
```

```bash
bitbake myapp -c cleansstate
```

---

# Runtime Commands

```bash
dmesg
```

```bash
journalctl
```

```bash
systemctl status
```

---

# 18. Debugging Checklist

# Build Failures

* Check layer compatibility
* Check logs
* Check patches
* Verify dependencies
* Verify disk space

---

# Boot Failures

* Check UART logs
* Check DTB
* Check rootfs
* Check bootargs
* Check kernel config

---

# Driver Failures

* Check probe logs
* Verify interrupts
* Verify GPIO
* Verify clock
* Verify power regulators

---

# OTA Failures

* Verify partition layout
* Verify signatures
* Verify rollback
* Check network

---

# 19. Recommended Learning Path

# Beginner

Learn:

* Linux commands
* Bash scripting
* GCC
* Makefiles
* Git

---

# Intermediate

Learn:

* Yocto recipes
* Layers
* Device tree
* U-Boot
* Kernel configuration

---

# Advanced

Learn:

* Driver development
* BSP development
* Secure boot
* OTA systems
* Docker
* CI/CD
* RT Linux

---

---

## Resources

- [Linux Kernel Debugging Guide (Kernel Docs)](https://www.kernel.org/doc/html/latest/admin-guide/debugging.html)
- [Ftrace Documentation](https://www.kernel.org/doc/html/latest/trace/ftrace.html)
- [KGDB Documentation](https://www.kernel.org/doc/html/latest/dev-tools/kgdb.html)
- [KASAN Documentation](https://www.kernel.org/doc/html/latest/dev-tools/kasan.html)
- [lockdep Documentation](https://www.kernel.org/doc/html/latest/locking/lockdep-design.html)

---

## Final Humorous Wisdom

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   "Debugging is like being the detective in a crime movie       │
│    where the victim is the kernel, the suspects are             │
│    interrupts, memory corruption, and race conditions,          │
│    and you forgot to save the call stack."                      │
│                                                                 │
│   "The kernel's idea of 'log message' is:                       │
│    [    0.123456] general protection fault: 0000 [#1] SMP NOPTI │
│    Which is kernel-speak for 'YOU SHALL NOT PASS!'"             │
│                                                                 │
│   "When your printk works perfectly but the bug disappears,     │
│    you've just discovered the Heisenbug."                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

