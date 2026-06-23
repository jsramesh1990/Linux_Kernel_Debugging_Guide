# Kernel build Makefile for Rock 3

# Architecture
ARCH ?= arm64
CROSS_COMPILE ?= aarch64-linux-gnu-

# Targets
TARGETS := Image dtbs modules

# Kernel configuration
defconfig:
	$(MAKE) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) rock3_defconfig

# Build everything
all: defconfig $(TARGETS)

# Build kernel image
Image:
	$(MAKE) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) Image

# Build device trees
dtbs:
	$(MAKE) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) dtbs

# Build modules
modules:
	$(MAKE) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) modules

# Install modules
modules_install:
	$(MAKE) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) modules_install

# Clean build
clean:
	$(MAKE) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) clean

# Deep clean
mrproper:
	$(MAKE) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) mrproper

# Help
help:
	$(MAKE) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) help

.PHONY: all defconfig Image dtbs modules modules_install clean mrproper help
