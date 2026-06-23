#!/bin/bash
# Monitor DDR utilization with perf

INTERVAL=${1:-1}
COUNT=${2:-10}

echo "Monitoring DDR for $COUNT intervals of ${INTERVAL}s"
echo "======================================"

for i in $(seq 1 $COUNT); do
    echo "Interval $i:"
    perf stat -a -e rockchip_ddr/cycles/,\
        rockchip_ddr/read-bytes/,\
        rockchip_ddr/write-bytes/,\
        rockchip_ddr/bytes/ sleep $INTERVAL 2>&1 | \
        grep -E "rockchip_ddr|bytes time"
    echo "---"
done
