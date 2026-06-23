# Hello World Kernel Module Makefile

obj-m += hello.o

KDIR ?= /lib/modules/$(shell uname -r)/build
PWD := $(shell pwd)

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean

install:
	sudo insmod hello.ko

remove:
	sudo rmmod hello

info:
	modinfo hello.ko

test:
	sudo dmesg -c > /dev/null
	sudo insmod hello.ko
	sudo rmmod hello
	dmesg | tail -20

.PHONY: all clean install remove info test
