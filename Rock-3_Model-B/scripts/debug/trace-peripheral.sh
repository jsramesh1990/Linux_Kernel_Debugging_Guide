#!/bin/bash
# Trace specific peripheral activity

PERIPHERAL=$1
DURATION=${2:-10}

case $PERIPHERAL in
    i2c)
        sudo trace-cmd record -e i2c:* -e i2c_smbus:* sleep $DURATION
        ;;
    spi)
        sudo trace-cmd record -e spi:* sleep $DURATION
        ;;
    gpio)
        sudo trace-cmd record -e gpio:* sleep $DURATION
        ;;
    dma)
        sudo trace-cmd record -e dma:* -e dma_engine:* sleep $DURATION
        ;;
    *)
        echo "Usage: $0 {i2c|spi|gpio|dma} [duration]"
        exit 1
        ;;
esac

sudo trace-cmd extract
echo "Trace saved to trace.dat"
echo "View with: kernelshark trace.dat"
