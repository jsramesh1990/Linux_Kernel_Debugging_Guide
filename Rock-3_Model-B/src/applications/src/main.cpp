/*
 * Main Application for Rock 3 Model B
 * 
 * This application demonstrates hardware interaction,
 * system monitoring, and peripheral testing on the Rock 3 board.
 */

#include <iostream>
#include <string>
#include <thread>
#include <chrono>
#include <fstream>
#include <cstring>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/i2c-dev.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <signal.h>
#include <iomanip>
#include <vector>

#include "hardware.h"

using namespace std;

// Global flag for signal handling
volatile bool running = true;

// Signal handler
void signal_handler(int sig) {
    cout << "\nReceived signal " << sig << ". Exiting..." << endl;
    running = false;
}

// Function to print banner
void print_banner() {
    cout << "\n" << string(50, '=') << endl;
    cout << "  Rock 3 Model B - Application" << endl;
    cout << "  Build: " << __DATE__ << " " << __TIME__ << endl;
    cout << string(50, '=') << endl;
    cout << "  CPU: " << Hardware::get_cpu_info() << endl;
    cout << "  RAM: " << Hardware::get_memory_info() << endl;
    cout << "  Temp: " << Hardware::get_temperature() << "°C" << endl;
    cout << "  Uptime: " << Hardware::get_uptime() << endl;
    cout << string(50, '=') << endl;
}

// Function to print help
void print_help() {
    cout << "Usage: rock3-app [OPTION]" << endl;
    cout << endl;
    cout << "Options:" << endl;
    cout << "  --gpio <pin> [0|1]     Read or write GPIO pin" << endl;
    cout << "  --i2c <bus> <addr> [reg] Read I2C device" << endl;
    cout << "  --monitor              Monitor system in real-time" << endl;
    cout << "  --test                 Run all hardware tests" << endl;
    cout << "  --info                 Display system information" << endl;
    cout << "  --help                 Show this help message" << endl;
    cout << endl;
    cout << "Examples:" << endl;
    cout << "  rock3-app --gpio 17            Read GPIO17" << endl;
    cout << "  rock3-app --gpio 17 1          Write GPIO17 to 1" << endl;
    cout << "  rock3-app --i2c 1 0x50         Read I2C device at 0x50 on bus 1" << endl;
    cout << "  rock3-app --monitor            Start monitoring" << endl;
    cout << "  rock3-app --test               Run tests" << endl;
}

// Function to monitor system
void monitor_system() {
    int count = 0;
    
    while (running) {
        system("clear");
        
        cout << string(50, '=') << endl;
        cout << "  Rock 3 System Monitor - " << count << endl;
        cout << "  " << Hardware::get_current_time() << endl;
        cout << string(50, '=') << endl;
        
        // CPU Info
        cout << "CPU:" << endl;
        cout << "  Usage: " << fixed << setprecision(1) 
             << Hardware::get_cpu_usage() << "%" << endl;
        cout << "  Frequency: " << Hardware::get_cpu_frequency() << " MHz" << endl;
        cout << "  Temperature: " << Hardware::get_temperature() << "°C" << endl;
        
        // Memory Info
        cout << "\nMemory:" << endl;
        cout << "  Total: " << Hardware::get_memory_total() << " MB" << endl;
        cout << "  Used: " << Hardware::get_memory_used() << " MB" << endl;
        cout << "  Usage: " << fixed << setprecision(1) 
             << Hardware::get_memory_usage() << "%" << endl;
        
        // Disk Info
        cout << "\nDisk:" << endl;
        cout << "  Total: " << Hardware::get_disk_total() << " GB" << endl;
        cout << "  Used: " << Hardware::get_disk_used() << " GB" << endl;
        cout << "  Usage: " << fixed << setprecision(1) 
             << Hardware::get_disk_usage() << "%" << endl;
        
        // Network Info
        cout << "\nNetwork:" << endl;
        cout << "  IP: " << Hardware::get_ip_address() << endl;
        cout << "  MAC: " << Hardware::get_mac_address() << endl;
        
        // GPIO Info
        cout << "\nGPIO:" << endl;
        for (int pin : {17, 18, 27, 22}) {
            int value = Hardware::read_gpio(pin);
            if (value >= 0) {
                cout << "  GPIO" << pin << ": " << value << endl;
            }
        }
        
        // Temperature Sensors
        cout << "\nTemperature Sensors:" << endl;
        auto sensors = Hardware::get_temperature_sensors();
        for (const auto& sensor : sensors) {
            cout << "  " << sensor.first << ": " << sensor.second << "°C" << endl;
        }
        
        cout << "\n" << string(50, '=') << endl;
        cout << "Press Ctrl+C to exit" << endl;
        
        count++;
        this_thread::sleep_for(chrono::seconds(2));
    }
}

// Function to run tests
bool run_tests() {
    cout << "Running hardware tests..." << endl;
    bool all_passed = true;
    
    // Test 1: GPIO
    cout << "\nTest 1: GPIO (GPIO17)" << endl;
    cout << "  Writing 1 to GPIO17..." << endl;
    Hardware::write_gpio(17, 1);
    this_thread::sleep_for(chrono::milliseconds(500));
    int val = Hardware::read_gpio(17);
    cout << "  GPIO17 = " << val << endl;
    if (val == 1) {
        cout << "  ✅ GPIO test passed" << endl;
    } else {
        cout << "  ❌ GPIO test failed" << endl;
        all_passed = false;
    }
    
    // Test 2: Temperature
    cout << "\nTest 2: Temperature Sensor" << endl;
    float temp = Hardware::get_temperature();
    cout << "  Temperature: " << temp << "°C" << endl;
    if (temp > 0 && temp < 100) {
        cout << "  ✅ Temperature test passed" << endl;
    } else {
        cout << "  ❌ Temperature test failed" << endl;
        all_passed = false;
    }
    
    // Test 3: Memory
    cout << "\nTest 3: Memory" << endl;
    float mem_usage = Hardware::get_memory_usage();
    cout << "  Memory usage: " << mem_usage << "%" << endl;
    if (mem_usage > 0 && mem_usage < 100) {
        cout << "  ✅ Memory test passed" << endl;
    } else {
        cout << "  ❌ Memory test failed" << endl;
        all_passed = false;
    }
    
    // Test 4: CPU
    cout << "\nTest 4: CPU" << endl;
    float cpu_usage = Hardware::get_cpu_usage();
    cout << "  CPU usage: " << cpu_usage << "%" << endl;
    if (cpu_usage >= 0 && cpu_usage <= 100) {
        cout << "  ✅ CPU test passed" << endl;
    } else {
        cout << "  ❌ CPU test failed" << endl;
        all_passed = false;
    }
    
    // Test 5: Network
    cout << "\nTest 5: Network" << endl;
    string ip = Hardware::get_ip_address();
    cout << "  IP address: " << ip << endl;
    if (ip != "0.0.0.0" && ip != "127.0.0.1" && !ip.empty()) {
        cout << "  ✅ Network test passed" << endl;
    } else {
        cout << "  ⚠️  Network test warning: No network or loopback" << endl;
    }
    
    cout << "\n" << string(50, '=') << endl;
    if (all_passed) {
        cout << "✅ All tests passed!" << endl;
    } else {
        cout << "❌ Some tests failed!" << endl;
    }
    
    return all_passed;
}

// GPIO command handler
int handle_gpio(int argc, char* argv[]) {
    if (argc < 3) {
        cerr << "Error: GPIO pin required" << endl;
        return 1;
    }
    
    int pin = atoi(argv[2]);
    if (argc == 4) {
        int value = atoi(argv[3]);
        if (value != 0 && value != 1) {
            cerr << "Error: GPIO value must be 0 or 1" << endl;
            return 1;
        }
        Hardware::write_gpio(pin, value);
        cout << "GPIO" << pin << " set to " << value << endl;
    } else {
        int val = Hardware::read_gpio(pin);
        if (val >= 0) {
            cout << "GPIO" << pin << " = " << val << endl;
        } else {
            cerr << "Error: Failed to read GPIO" << pin << endl;
            return 1;
        }
    }
    return 0;
}

// I2C command handler
int handle_i2c(int argc, char* argv[]) {
    if (argc < 4) {
        cerr << "Error: I2C bus and address required" << endl;
        return 1;
    }
    
    int bus = atoi(argv[2]);
    int addr = strtol(argv[3], NULL, 16);
    int reg = (argc > 4) ? strtol(argv[4], NULL, 16) : -1;
    
    string i2c_path = "/dev/i2c-" + to_string(bus);
    int fd = open(i2c_path.c_str(), O_RDWR);
    if (fd < 0) {
        cerr << "Error: Failed to open I2C bus " << bus << endl;
        return 1;
    }
    
    if (ioctl(fd, I2C_SLAVE, addr) < 0) {
        cerr << "Error: Failed to set I2C address" << endl;
        close(fd);
        return 1;
    }
    
    if (reg >= 0) {
        // Write register address
        if (write(fd, &reg, 1) != 1) {
            cerr << "Error: Failed to write register address" << endl;
            close(fd);
            return 1;
        }
        
        // Read data
        unsigned char data;
        if (read(fd, &data, 1) == 1) {
            cout << "Bus " << bus << ", Addr 0x" << hex << addr 
                 << ", Reg 0x" << reg << " = 0x" << (int)data << dec << endl;
        } else {
            cerr << "Error: Failed to read I2C data" << endl;
            close(fd);
            return 1;
        }
    } else {
        // Read without register
        unsigned char data;
        if (read(fd, &data, 1) == 1) {
            cout << "Bus " << bus << ", Addr 0x" << hex << addr 
                 << " = 0x" << (int)data << dec << endl;
        } else {
            cerr << "Error: Failed to read I2C data" << endl;
            close(fd);
            return 1;
        }
    }
    
    close(fd);
    return 0;
}

// Main function
int main(int argc, char* argv[]) {
    // Set up signal handling
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);
    
    // Check arguments
    if (argc > 1) {
        if (strcmp(argv[1], "--gpio") == 0) {
            return handle_gpio(argc, argv);
        }
        
        if (strcmp(argv[1], "--i2c") == 0) {
            return handle_i2c(argc, argv);
        }
        
        if (strcmp(argv[1], "--monitor") == 0) {
            print_banner();
            monitor_system();
            return 0;
        }
        
        if (strcmp(argv[1], "--test") == 0) {
            print_banner();
            run_tests();
            return 0;
        }
        
        if (strcmp(argv[1], "--info") == 0) {
            print_banner();
            
            // Additional info
            cout << "\nSystem Details:" << endl;
            cout << "  Kernel: " << Hardware::get_kernel_version() << endl;
            cout << "  OS: " << Hardware::get_os_version() << endl;
            cout << "  Hostname: " << Hardware::get_hostname() << endl;
            cout << "  Uptime: " << Hardware::get_uptime() << endl;
            
            cout << "\nCPU Cores:" << endl;
            auto cores = Hardware::get_cpu_cores();
            for (const auto& core : cores) {
                cout << "  Core " << core.first << ": " << core.second << " MHz" << endl;
            }
            
            cout << "\nNetwork Interfaces:" << endl;
            auto interfaces = Hardware::get_network_interfaces();
            for (const auto& iface : interfaces) {
                cout << "  " << iface.first << ": " << iface.second << endl;
            }
            
            return 0;
        }
        
        if (strcmp(argv[1], "--help") == 0 || strcmp(argv[1], "-h") == 0) {
            print_help();
            return 0;
        }
        
        cout << "Unknown option: " << argv[1] << endl;
        print_help();
        return 1;
    }
    
    // Default: show system info
    print_banner();
    
    cout << "\nType --help for options" << endl;
    cout << "Type --monitor for real-time monitoring" << endl;
    cout << "Type --test to run hardware tests" << endl;
    
    return 0;
}
