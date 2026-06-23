# GPIO Driver Kernel Module Makefile

obj-m += gpio-driver.o

KDIR ?= /lib/modules/$(shell uname -r)/build
PWD := $(shell pwd)

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean

install:
	sudo insmod gpio-driver.ko

remove:
	sudo rmmod gpio-driver

test:
	sudo dmesg -c > /dev/null
	sudo insmod gpio-driver.ko
	echo "Testing GPIO driver..."
	echo "1" > /dev/gpio_drv
	cat /dev/gpio_drv
	sudo rmmod gpio-driver
	dmesg | tail -30

.PHONY: all clean install remove test
