/*
 * Hello World Kernel Module for Rock 3
 * 
 * Demonstrates basic kernel module structure, device file operations,
 * and debugging techniques.
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/fs.h>
#include <linux/uaccess.h>
#include <linux/device.h>
#include <linux/slab.h>
#include <linux/version.h>

#define MODULE_NAME "hello"
#define DEVICE_NAME "hello"
#define CLASS_NAME "hello"

// Module information
MODULE_LICENSE("GPL");
MODULE_AUTHOR("Rock 3 Developer");
MODULE_DESCRIPTION("Hello World Kernel Module for Rock 3");
MODULE_VERSION("1.0.0");

// Device variables
static int major_num;
static struct class *hello_class = NULL;
static struct device *hello_device = NULL;

// Message buffer
static char *message_buffer = NULL;
static int message_len = 0;

// Open function
static int hello_open(struct inode *inode, struct file *file) {
    pr_info("Hello: device opened\n");
    return 0;
}

// Release function
static int hello_release(struct inode *inode, struct file *file) {
    pr_info("Hello: device closed\n");
    return 0;
}

// Read function
static ssize_t hello_read(struct file *file, char __user *buf, 
                         size_t len, loff_t *off) {
    char *message = "Hello from Rock 3 Kernel Module!\n";
    size_t message_len = strlen(message);
    size_t bytes_to_read;
    
    // Check if we've read everything
    if (*off >= message_len)
        return 0;
    
    // Calculate bytes to read
    bytes_to_read = min(len, message_len - *off);
    
    // Copy to user space
    if (copy_to_user(buf, message + *off, bytes_to_read)) {
        pr_err("Hello: Failed to copy data to user\n");
        return -EFAULT;
    }
    
    // Update offset
    *off += bytes_to_read;
    
    pr_info("Hello: Read %zu bytes at offset %lld\n", bytes_to_read, *off);
    return bytes_to_read;
}

// Write function
static ssize_t hello_write(struct file *file, const char __user *buf,
                          size_t len, loff_t *off) {
    char *kernel_buf;
    size_t bytes_to_write;
    
    // Limit write size
    bytes_to_write = min(len, (size_t)1024);
    
    // Allocate kernel buffer
    kernel_buf = kmalloc(bytes_to_write + 1, GFP_KERNEL);
    if (!kernel_buf) {
        pr_err("Hello: Failed to allocate memory\n");
        return -ENOMEM;
    }
    
    // Copy from user space
    if (copy_from_user(kernel_buf, buf, bytes_to_write)) {
        pr_err("Hello: Failed to copy data from user\n");
        kfree(kernel_buf);
        return -EFAULT;
    }
    
    // Null terminate
    kernel_buf[bytes_to_write] = '\0';
    
    // Print received message
    pr_info("Hello: Received: %s\n", kernel_buf);
    
    // Save to buffer
    if (message_buffer) {
        kfree(message_buffer);
    }
    message_buffer = kernel_buf;
    message_len = bytes_to_write;
    
    pr_info("Hello: Wrote %zu bytes\n", bytes_to_write);
    return bytes_to_write;
}

// IOCTL function
static long hello_ioctl(struct file *file, unsigned int cmd, unsigned long arg) {
    pr_info("Hello: IOCTL cmd=%u, arg=%lu\n", cmd, arg);
    
    switch (cmd) {
        case 0:
            pr_info("Hello: IOCTL command 0\n");
            break;
        case 1:
            pr_info("Hello: IOCTL command 1\n");
            break;
        default:
            pr_info("Hello: Unknown IOCTL command\n");
            return -EINVAL;
    }
    
    return 0;
}

// File operations structure
static struct file_operations hello_fops = {
    .owner = THIS_MODULE,
    .open = hello_open,
    .release = hello_release,
    .read = hello_read,
    .write = hello_write,
    .unlocked_ioctl = hello_ioctl,
};

// Module initialization
static int __init hello_init(void) {
    int ret;
    
    pr_info("Hello: Initializing module (version %s)\n", MODULE_VERSION);
    
    // Allocate device number
    major_num = register_chrdev(0, DEVICE_NAME, &hello_fops);
    if (major_num < 0) {
        pr_err("Hello: Failed to register device\n");
        return major_num;
    }
    pr_info("Hello: Registered with major number %d\n", major_num);
    
    // Create device class
    hello_class = class_create(THIS_MODULE, CLASS_NAME);
    if (IS_ERR(hello_class)) {
        pr_err("Hello: Failed to create class\n");
        unregister_chrdev(major_num, DEVICE_NAME);
        return PTR_ERR(hello_class);
    }
    
    // Create device
    hello_device = device_create(hello_class, NULL, 
                                 MKDEV(major_num, 0), 
                                 NULL, DEVICE_NAME);
    if (IS_ERR(hello_device)) {
        pr_err("Hello: Failed to create device\n");
        class_destroy(hello_class);
        unregister_chrdev(major_num, DEVICE_NAME);
        return PTR_ERR(hello_device);
    }
    
    pr_info("Hello: Device created at /dev/%s\n", DEVICE_NAME);
    pr_info("Hello: Module initialized successfully\n");
    
    return 0;
}

// Module cleanup
static void __exit hello_exit(void) {
    pr_info("Hello: Cleaning up module\n");
    
    // Free message buffer
    if (message_buffer) {
        kfree(message_buffer);
        message_buffer = NULL;
    }
    
    // Destroy device
    device_destroy(hello_class, MKDEV(major_num, 0));
    class_destroy(hello_class);
    
    // Unregister device
    unregister_chrdev(major_num, DEVICE_NAME);
    
    pr_info("Hello: Module unloaded\n");
}

// Module entry points
module_init(hello_init);
module_exit(hello_exit);
