#!/bin/bash
# ============================================
# Peripheral Test Suite for Rock 3 Model B
# ============================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Function to print test result
print_result() {
    local test_name="$1"
    local result="$2"
    local message="$3"
    
    if [ "$result" == "PASS" ]; then
        echo -e "${GREEN}✓ PASS${NC} - $test_name: $message"
        ((TESTS_PASSED++))
    elif [ "$result" == "FAIL" ]; then
        echo -e "${RED}✗ FAIL${NC} - $test_name: $message"
        ((TESTS_FAILED++))
    else
        echo -e "${YELLOW}⚠ SKIP${NC} - $test_name: $message"
        ((TESTS_SKIPPED++))
    fi
}

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Peripheral Test Suite for Rock 3    ${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Starting tests at $(date)"
echo ""

# ------------------------------------------------------------
# Test 1: I2C Bus Detection
# ------------------------------------------------------------
echo -e "${BLUE}Test 1: I2C Bus Detection${NC}"
echo "-----------------------------"

if command -v i2cdetect &> /dev/null; then
    I2C_BUSES=$(i2cdetect -l 2>/dev/null | wc -l)
    
    if [ "$I2C_BUSES" -gt 0 ]; then
        print_result "I2C Detection" "PASS" "Found $I2C_BUSES I2C bus(es)"
        
        # Try to scan bus 1
        if i2cdetect -y 1 &> /dev/null; then
            DEVICES=$(i2cdetect -y 1 2>/dev/null | grep -E " [0-9a-f]{2} " | wc -l)
            if [ "$DEVICES" -gt 0 ]; then
                echo "  Devices on bus 1:"
                i2cdetect -y 1 2>/dev/null | grep -E " [0-9a-f]{2} " | head -5
            fi
        fi
    else
        print_result "I2C Detection" "FAIL" "No I2C buses found"
    fi
else
    print_result "I2C Detection" "SKIP" "i2c-tools not installed"
fi

echo ""

# ------------------------------------------------------------
# Test 2: SPI Device Detection
# ------------------------------------------------------------
echo -e "${BLUE}Test 2: SPI Device Detection${NC}"
echo "-----------------------------"

SPI_DEVICES=$(ls /dev/spi* 2>/dev/null | wc -l)

if [ "$SPI_DEVICES" -gt 0 ]; then
    print_result "SPI Detection" "PASS" "Found $SPI_DEVICES SPI device(s)"
    ls -la /dev/spi* 2>/dev/null | head -5
else
    print_result "SPI Detection" "SKIP" "No SPI devices found"
fi

echo ""

# ------------------------------------------------------------
# Test 3: GPIO Access
# ------------------------------------------------------------
echo -e "${BLUE}Test 3: GPIO Access${NC}"
echo "----------------------"

GPIO_EXPORTED=$(ls /sys/class/gpio/gpio* 2>/dev/null | wc -l)

# Try to export and test GPIO 17
if [ -w /sys/class/gpio/export ]; then
    echo 17 > /sys/class/gpio/export 2>/dev/null || true
    sleep 0.1
    
    if [ -d /sys/class/gpio/gpio17 ]; then
        # Test GPIO
        echo out > /sys/class/gpio/gpio17/direction 2>/dev/null
        echo 1 > /sys/class/gpio/gpio17/value 2>/dev/null
        VALUE=$(cat /sys/class/gpio/gpio17/value 2>/dev/null)
        
        if [ "$VALUE" = "1" ]; then
            print_result "GPIO Access" "PASS" "GPIO17 working"
        else
            print_result "GPIO Access" "FAIL" "GPIO17 test failed"
        fi
        
        # Clean up
        echo 17 > /sys/class/gpio/unexport 2>/dev/null || true
    else
        print_result "GPIO Access" "FAIL" "Could not export GPIO17"
    fi
else
    print_result "GPIO Access" "SKIP" "GPIO sysfs not writable"
fi

echo ""

# ------------------------------------------------------------
# Test 4: HDMI Detection
# ------------------------------------------------------------
echo -e "${BLUE}Test 4: HDMI Detection${NC}"
echo "-------------------------"

if [ -f /sys/class/drm/card0-HDMI-A-1/status ]; then
    HDMI_STATUS=$(cat /sys/class/drm/card0-HDMI-A-1/status 2>/dev/null)
    
    if [ "$HDMI_STATUS" = "connected" ]; then
        # Get EDID info
        if [ -f /sys/class/drm/card0-HDMI-A-1/edid ]; then
            EDID_SIZE=$(stat -c%s /sys/class/drm/card0-HDMI-A-1/edid 2>/dev/null)
            if [ "$EDID_SIZE" -gt 0 ]; then
                print_result "HDMI Detection" "PASS" "HDMI connected, EDID: ${EDID_SIZE}B"
            else
                print_result "HDMI Detection" "WARN" "HDMI connected but no EDID"
            fi
        else
            print_result "HDMI Detection" "WARN" "HDMI connected but no EDID file"
        fi
    else
        print_result "HDMI Detection" "SKIP" "HDMI not connected"
    fi
else
    # Try alternative paths
    if [ -f /sys/class/drm/card1-HDMI-A-1/status ]; then
        HDMI_STATUS=$(cat /sys/class/drm/card1-HDMI-A-1/status 2>/dev/null)
        print_result "HDMI Detection" "PASS" "HDMI found (card1), status: $HDMI_STATUS"
    else
        print_result "HDMI Detection" "SKIP" "No HDMI interface found"
    fi
fi

echo ""

# ------------------------------------------------------------
# Test 5: Ethernet Interface
# ------------------------------------------------------------
echo -e "${BLUE}Test 5: Ethernet Interface${NC}"
echo "----------------------------"

if ip link show eth0 &> /dev/null; then
    ETH_STATUS=$(ip link show eth0 | grep -o "UP" || echo "DOWN")
    ETH_MAC=$(ip link show eth0 | grep ether | awk '{print $2}')
    
    if [ "$ETH_STATUS" = "UP" ]; then
        print_result "Ethernet Interface" "PASS" "eth0 UP, MAC: $ETH_MAC"
        
        # Get speed if ethtool available
        if command -v ethtool &> /dev/null; then
            SPEED=$(ethtool eth0 2>/dev/null | grep Speed | awk '{print $2}')
            if [ -n "$SPEED" ]; then
                echo "  Speed: $SPEED"
            fi
        fi
    else
        print_result "Ethernet Interface" "WARN" "eth0 DOWN, MAC: $ETH_MAC"
    fi
else
    print_result "Ethernet Interface" "SKIP" "eth0 not found"
fi

echo ""

# ------------------------------------------------------------
# Test 6: USB Devices
# ------------------------------------------------------------
echo -e "${BLUE}Test 6: USB Devices${NC}"
echo "----------------------"

if command -v lsusb &> /dev/null; then
    USB_DEVICES=$(lsusb 2>/dev/null | wc -l)
    
    if [ "$USB_DEVICES" -gt 0 ]; then
        print_result "USB Detection" "PASS" "Found $USB_DEVICES USB device(s)"
        
        echo "  USB devices:"
        lsusb 2>/dev/null | head -5
    else
        print_result "USB Detection" "FAIL" "No USB devices found"
    fi
else
    print_result "USB Detection" "SKIP" "lsusb not available"
fi

echo ""

# ------------------------------------------------------------
# Test 7: PWM Channels
# ------------------------------------------------------------
echo -e "${BLUE}Test 7: PWM Channels${NC}"
echo "-----------------------"

if [ -d /sys/class/pwm ]; then
    PWM_CHIPS=$(ls /sys/class/pwm/pwmchip* 2>/dev/null | wc -l)
    
    if [ "$PWM_CHIPS" -gt 0 ]; then
        print_result "PWM Channels" "PASS" "Found $PWM_CHIPS PWM chip(s)"
        
        # Try to export first channel
        for chip in /sys/class/pwm/pwmchip*; do
            if [ -w "$chip/export" ]; then
                echo 0 > "$chip/export" 2>/dev/null || true
                sleep 0.1
                if [ -d "$chip/pwm0" ]; then
                    echo "  PWM0 on $(basename $chip) available"
                    echo 0 > "$chip/unexport" 2>/dev/null || true
                fi
                break
            fi
        done
    else
        print_result "PWM Channels" "SKIP" "No PWM chips found"
    fi
else
    print_result "PWM Channels" "SKIP" "PWM subsystem not found"
fi

echo ""

# ------------------------------------------------------------
# Test 8: Temperature Sensors
# ------------------------------------------------------------
echo -e "${BLUE}Test 8: Temperature Sensors${NC}"
echo "-------------------------------"

THERMAL_ZONES=$(ls /sys/class/thermal/thermal_zone* 2>/dev/null | wc -l)

if [ "$THERMAL_ZONES" -gt 0 ]; then
    print_result "Temperature Sensors" "PASS" "Found $THERMAL_ZONES thermal zone(s)"
    
    echo "  Temperatures:"
    for zone in /sys/class/thermal/thermal_zone*; do
        if [ -f "$zone/temp" ]; then
            TEMP=$(cat "$zone/temp" 2>/dev/null)
            TEMP_C=$((TEMP / 1000))
            NAME=$(cat "$zone/type" 2>/dev/null || echo "zone")
            echo "    $NAME: ${TEMP_C}°C"
        fi
    done
else
    print_result "Temperature Sensors" "SKIP" "No thermal zones found"
fi

echo ""

# ------------------------------------------------------------
# Test 9: Serial Ports
# ------------------------------------------------------------
echo -e "${BLUE}Test 9: Serial Ports${NC}"
echo "-----------------------"

SERIAL_DEVICES=$(ls /dev/ttyS* /dev/ttyUSB* /dev/ttyAMA* 2>/dev/null | wc -l)

if [ "$SERIAL_DEVICES" -gt 0 ]; then
    print_result "Serial Ports" "PASS" "Found $SERIAL_DEVICES serial device(s)"
    ls -la /dev/ttyS* /dev/ttyUSB* /dev/ttyAMA* 2>/dev/null | head -5
else
    print_result "Serial Ports" "SKIP" "No serial devices found"
fi

echo ""

# ------------------------------------------------------------
# Test 10: Watchdog
# ------------------------------------------------------------
echo -e "${BLUE}Test 10: Watchdog${NC}"
echo "----------------------"

if [ -c /dev/watchdog ]; then
    print_result "Watchdog" "PASS" "Watchdog device found"
else
    print_result "Watchdog" "SKIP" "No watchdog device found"
fi

echo ""

# ------------------------------------------------------------
# Test 11: RTC
# ------------------------------------------------------------
echo -e "${BLUE}Test 11: RTC${NC}"
echo "-----------------"

if [ -d /sys/class/rtc ]; then
    RTC_DEVICES=$(ls /sys/class/rtc/rtc* 2>/dev/null | wc -l)
    
    if [ "$RTC_DEVICES" -gt 0 ]; then
        RTC_TIME=$(cat /sys/class/rtc/rtc0/time 2>/dev/null || echo "N/A")
        RTC_DATE=$(cat /sys/class/rtc/rtc0/date 2>/dev/null || echo "N/A")
        print_result "RTC" "PASS" "RTC found: $RTC_DATE $RTC_TIME"
    else
        print_result "RTC" "SKIP" "No RTC devices found"
    fi
else
    print_result "RTC" "SKIP" "RTC subsystem not found"
fi

echo ""

# ------------------------------------------------------------
# Test 12: Audio Devices
# ------------------------------------------------------------
echo -e "${BLUE}Test 12: Audio Devices${NC}"
echo "------------------------"

if command -v aplay &> /dev/null; then
    AUDIO_DEVICES=$(aplay -l 2>/dev/null | grep -c "card" || echo "0")
    
    if [ "$AUDIO_DEVICES" -gt 0 ]; then
        print_result "Audio Devices" "PASS" "Found $AUDIO_DEVICES audio device(s)"
        aplay -l 2>/dev/null | head -5
    else
        print_result "Audio Devices" "SKIP" "No audio devices found"
    fi
else
    print_result "Audio Devices" "SKIP" "aplay not installed"
fi

echo ""

# ------------------------------------------------------------
# Test Summary
# ------------------------------------------------------------
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Test Summary${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Passed: ${TESTS_PASSED}${NC}"
echo -e "${RED}Failed: ${TESTS_FAILED}${NC}"
echo -e "${YELLOW}Skipped: ${TESTS_SKIPPED}${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All peripheral tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some peripheral tests failed!${NC}"
    exit 1
fi
