# Custom Drivers Directory

This directory contains custom drivers for the Rock 3 Model B.

## Structure
- `usb/` - USB driver implementations
- `i2c/` - I2C driver implementations
- `spi/` - SPI driver implementations
- `dma/` - DMA driver implementations
- `pwm/` - PWM driver implementations

## Building
```bash
cd src/drivers/<driver_name>
make -C /lib/modules/$(uname -r)/build M=$(pwd) modules

Installing
bash

sudo insmod <driver_name>.ko
sudo rmmod <driver_name>

Debugging
bash

dmesg | grep <driver_name>
sudo trace-cmd record -e <driver_name>:* sleep 10

text


---

## Make All Scripts Executable

```bash
# Make all scripts executable
chmod +x scripts/**/*.sh
chmod +x scripts/*.sh
chmod +x examples/*.sh
chmod +x docker/entrypoint.sh

# Build the application
cd src/applications
mkdir -p build
cd build
cmake ..
make

# Build the kernel (optional - needs kernel source)
# cd src/kernel
# make rock3_defconfig
# make -j$(nproc) Image dtbs

# Build modules
# cd src/modules/hello
# make
# cd ../gpio
# make

Summary of Source Files
Path	Description
src/applications/CMakeLists.txt	CMake build configuration
src/applications/src/main.cpp	Main application entry point
src/applications/src/hardware.cpp	Hardware interface implementation
src/applications/src/hardware.h	Hardware interface header
src/applications/src/version.h	Version information
src/kernel/Makefile	Kernel build configuration
src/kernel/.config	Kernel configuration
src/modules/hello/Makefile	Hello module build
src/modules/hello/hello.c	Hello kernel module
src/modules/hello/hello.h	Hello module header
src/modules/gpio/Makefile	GPIO module build
src/modules/gpio/gpio-driver.c	GPIO driver module
src/drivers/README.md	Drivers documentation

