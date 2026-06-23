/*
 * Hello Kernel Module Header
 */

#ifndef HELLO_H
#define HELLO_H

#define HELLO_MAJOR 0
#define HELLO_MINOR 0

// IOCTL commands
#define HELLO_IOCTL_GET_MSG _IOR('H', 1, char*)
#define HELLO_IOCTL_SET_MSG _IOW('H', 2, char*)

#endif /* HELLO_H */
