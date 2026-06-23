/*
 * Hardware Interface Header
 * 
 * Provides hardware interaction functions for the Rock 3 Model B.
 */

#ifndef HARDWARE_H
#define HARDWARE_H

#include <string>
#include <map>
#include <vector>
#include <thread>
#include <chrono>
#include <fstream>
#include <sstream>
#include <sys/statvfs.h>

using namespace std;

class Hardware {
public:
    // CPU Information
    static string get_cpu_info();
    static string get_cpu_frequency();
    static map<int, string> get_cpu_cores();
    static float get_cpu_usage();
    
    // Memory Information
    static string get_memory_info();
    static float get_memory_usage();
    static unsigned long get_memory_total();
    static unsigned long get_memory_used();
    
    // Temperature
    static float get_temperature();
    static map<string, float> get_temperature_sensors();
    
    // GPIO
    static int read_gpio(int pin);
    static void write_gpio(int pin, int value);
    
    // Disk Information
    static float get_disk_usage();
    static float get_disk_total();
    static float get_disk_used();
    
    // Network
    static string get_ip_address();
    static string get_mac_address();
    static map<string, string> get_network_interfaces();
    
    // System Information
    static string get_kernel_version();
    static string get_os_version();
    static string get_hostname();
    static string get_uptime();
    static string get_current_time();
    
    // Helper Functions
    static string read_file(const string& path);
    static int read_int_from_file(const string& path);
    static float read_float_from_file(const string& path);
};

#endif /* HARDWARE_H */
