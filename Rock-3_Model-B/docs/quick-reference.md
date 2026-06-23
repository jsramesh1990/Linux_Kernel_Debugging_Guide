# Rock 3 Debugging Quick Reference

## Performance Analysis
| Goal | Command |
|------|---------|
| DDR bandwidth | `perf stat -a -e rockchip_ddr/bytes/ sleep 1` |
| CPU profile | `perf record -a -g sleep 30 && perf report` |
| Cache misses | `perf stat -e cache-misses,instructions <cmd>` |

## Kernel Tracing
| Goal | Command |
|------|---------|
| Function graph | `sudo trace-cmd record -p function_graph sleep 10` |
| Module functions | `sudo trace-cmd record --module <module-name> sleep 10` |
| View trace | `sudo trace-cmd report -i trace.dat` |

## System Monitoring
| Goal | Command |
|------|---------|
| Kernel messages | `dmesg -H -w` |
| System calls | `strace -f -o log <cmd>` |
| Open files | `lsof -p <pid>` |
| I/O stats | `iostat -x 1` |

## Peripheral Debugging
| Peripheral | Command |
|------------|---------|
| HDMI | `dmesg \| grep HDMI` |
| Ethernet | `dmesg \| grep ethernet` |
| USB | `dmesg \| grep USB` |
| I2C | `trace-cmd record -e i2c:* sleep 5` |
