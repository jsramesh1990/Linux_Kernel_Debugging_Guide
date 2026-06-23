/*
 * GPIO Driver Module for Rock 3
 * 
 * Implements a simple GPIO driver that can be used to control
 * and read GPIO pins from user space.
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/gpio.h>
#include <linux/fs.h>
#include <linux/uaccess.h>
#include <linux/device.h>
#include <linux/slab.h>
#include <linux/delay.h>
#include <linux/of.h>
#include <linux/of_gpio.h>

#define MODULE_NAME "gpio_drv"
#define DEVICE_NAME "gpio_drv"
#define CLASS_NAME "gpio"

// Module information
MODULE_LICENSE("GPL");
MODULE_AUTHOR("Rock 3 Developer");
MODULE_DESCRIPTION("GPIO Driver for Rock 3");
MODULE_VERSION("1.0.0");

// GPIO configuration
#define GPIO_PIN 17  // Default GPIO pin

// Device variables
static int gpio_major;
static struct class *gpio_class = NULL;
static struct device *gpio_device = NULL;
static int gpio_pin = GPIO_PIN;
static bool gpio_exported = false;

// Open function
static int gpio_open(struct inode *inode, struct file *file) {
    pr_info("GPIO: Device opened\n");
    return 0;
}

// Release function
static int gpio_release(struct inode *inode, struct file *file) {
    pr_info("GPIO: Device closed\n");
    return 0;
}

// Read function
static ssize_t gpio_read(struct file *file, char __user *buf,
                        size_t len, loff_t *off) {
    int value;
    char value_str[8];
    size_t bytes_read;
    
    // Read GPIO value
    if (!gpio_exported) {
        pr_err("GPIO: GPIO not exported\n");
        return -EIO;
    }
    
    value = gpio_get_value(gpio_pin);
    snprintf(value_str, sizeof(value_str), "%d\n", value);
    
    bytes_read = strlen(value_str);
    if (*off >= bytes_read) {
        return 0;
    }
    
    // Copy to user space
    if (copy_to_user(buf, value_str + *off, bytes_read - *off)) {
        pr_err("GPIO: Failed to copy data to user\n");
        return -EFAULT;
    }
    
    *off = bytes_read;
    pr_info("GPIO: Read value %d\n", value);
    
    return bytes_read;
}

// Write function
static ssize_t gpio_write(struct file *file, const char __user *buf,
                         size_t len, loff_t *off) {
    char kernel_buf[10];
    int value;
    
    if (len > 9) {
        len = 9;
    }
    
    // Copy from user space
    if (copy_from_user(kernel_buf, buf, len)) {
        pr_err("GPIO: Failed to copy data from user\n");
        return -EFAULT;
    }
    kernel_buf[len] = '\0';
    
    // Parse value
    if (kstrtoint(kernel_buf, 0, &value) != 0) {
        pr_err("GPIO: Invalid value: %s\n", kernel_buf);
        return -EINVAL;
    }
    
    if (value != 0 && value != 1) {
        pr_err("GPIO: Value must be 0 or 1\n");
        return -EINVAL;
    }
    
    // Set GPIO value
    if (!gpio_exported) {
        pr_err("GPIO: GPIO not exported\n");
        return -EIO;
    }
    
    gpio_set_value(gpio_pin, value);
    pr_info("GPIO: Set to %d\n", value);
    
    return len;
}

// IOCTL function
static long gpio_ioctl(struct file *file, unsigned int cmd, unsigned long arg) {
    int value;
    int ret = 0;
    
    switch (cmd) {
        case 0:  // Get GPIO value
            if (!gpio_exported) {
                pr_err("GPIO: GPIO not exported\n");
                return -EIO;
            }
            value = gpio_get_value(gpio_pin);
            if (copy_to_user((int __user *)arg, &value, sizeof(int))) {
                ret = -EFAULT;
            }
            pr_info("GPIO: IOCTL get value %d\n", value);
            break;
            
        case 1:  // Set GPIO value
            if (copy_from_user(&value, (int __user *)arg, sizeof(int))) {
                ret = -EFAULT;
                break;
            }
            if (!gpio_exported) {
                pr_err("GPIO: GPIO not exported\n");
                return -EIO;
            }
            gpio_set_value(gpio_pin, value);
            pr_info("GPIO: IOCTL set value %d\n", value);
            break;
            
        default:
            pr_info("GPIO: Unknown IOCTL command %u\n", cmd);
            return -EINVAL;
    }
    
    return ret;
}

// File operations structure
static struct file_operations gpio_fops = {
    .owner = THIS_MODULE,
    .open = gpio_open,
    .release = gpio_release,
    .read = gpio_read,
    .write = gpio_write,
    .unlocked_ioctl = gpio_ioctl,
};

// Module initialization
static int __init gpio_init(void) {
    int ret;
    struct device_node *np;
    int pin;
    
    pr_info("GPIO: Initializing GPIO driver\n");
    
    // Try to get GPIO pin from device tree
    np = of_find_node_by_name(NULL, "gpio-driver");
    if (np) {
        ret = of_get_named_gpio(np, "gpio-pin", 0);
        if (ret >= 0) {
            gpio_pin = ret;
            pr_info("GPIO: Using pin %d from device tree\n", gpio_pin);
        }
        of_node_put(np);
    } else {
        pr_info("GPIO: Using default pin %d\n", gpio_pin);
    }
    
    // Request GPIO
    ret = gpio_request(gpio_pin, MODULE_NAME);
    if (ret) {
        pr_err("GPIO: Failed to request GPIO %d (error %d)\n", gpio_pin, ret);
        return ret;
    }
    gpio_exported = true;
    
    // Set as output with initial value 0
    gpio_direction_output(gpio_pin, 0);
    pr_info("GPIO: GPIO %d initialized as output\n", gpio_pin);
    
    // Register device
    gpio_major = register_chrdev(0, DEVICE_NAME, &gpio_fops);
    if (gpio_major < 0) {
        pr_err("GPIO: Failed to register device (error %d)\n", gpio_major);
        gpio_free(gpio_pin);
        gpio_exported = false;
        return gpio_major;
    }
    pr_info("GPIO: Registered with major number %d\n", gpio_major);
    
    // Create device class
    gpio_class = class_create(THIS_MODULE, CLASS_NAME);
    if (IS_ERR(gpio_class)) {
        pr_err("GPIO: Failed to create class\n");
        unregister_chrdev(gpio_major, DEVICE_NAME);
        gpio_free(gpio_pin);
        gpio_exported = false;
        return PTR_ERR(gpio_class);
    }
    
    // Create device
    gpio_device = device_create(gpio_class, NULL, 
                                MKDEV(gpio_major, 0), 
                                NULL, DEVICE_NAME);
    if (IS_ERR(gpio_device)) {
        pr_err("GPIO: Failed to create device\n");
        class_destroy(gpio_class);
        unregister_chrdev(gpio_major, DEVICE_NAME);
        gpio_free(gpio_pin);
        gpio_exported = false;
        return PTR_ERR(gpio_device);
    }
    
    pr_info("GPIO: Device created at /dev/%s\n", DEVICE_NAME);
    pr_info("GPIO: Driver initialized successfully\n");
    
    return 0;
}

// Module cleanup
static void __exit gpio_exit(void) {
    pr_info("GPIO: Cleaning up GPIO driver\n");
    
    // Reset GPIO
    if (gpio_exported) {
        gpio_set_value(gpio_pin, 0);
        gpio_free(gpio_pin);
        gpio_exported = false;
        pr_info("GPIO: GPIO %d freed\n", gpio_pin);
    }
    
    // Destroy device
    if (gpio_device) {
        device_destroy(gpio_class, MKDEV(gpio_major, 0));
    }
    if (gpio_class) {
        class_destroy(gpio_class);
    }
    
    // Unregister device
    if (gpio_major > 0) {
        unregister_chrdev(gpio_major, DEVICE_NAME);
    }
    
    pr_info("GPIO: Driver unloaded\n");
}

// Module entry points
module_init(gpio_init);
module_exit(gpio_exit);
