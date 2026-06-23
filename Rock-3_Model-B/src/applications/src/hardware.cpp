/*
 * Hardware Interface Implementation
 * 
 * Provides system information, GPIO, I2C, and hardware monitoring
 * functions for the Rock 3 Model B.
 */

#include "hardware.h"
#include <fstream>
#include <sstream>
#include <cstring>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/sysinfo.h>
#include <sys/utsname.h>
#include <net/if.h>
#include <arpa/inet.h>
#include <ifaddrs.h>
#include <algorithm>
#include <chrono>
#include <iomanip>

using namespace std;

// ============================================
// CPU Information Functions
// ============================================

string Hardware::get_cpu_info() {
    ifstream cpuinfo("/proc/cpuinfo");
    string line;
    string model;
    
    while (getline(cpuinfo, line)) {
        if (line.find("Model") != string::npos) {
            size_t pos = line.find(':');
            if (pos != string::npos) {
                model = line.substr(pos + 2);
                break;
            }
        }
    }
    
    return model.empty() ? "Unknown" : model;
}

string Hardware::get_cpu_frequency() {
    ifstream cpuinfo("/proc/cpuinfo");
    string line;
    string freq;
    
    while (getline(cpuinfo, line)) {
        if (line.find("CPU MHz") != string::npos) {
            size_t pos = line.find(':');
            if (pos != string::npos) {
                freq = line.substr(pos + 2);
                break;
            }
        }
    }
    
    return freq.empty() ? "N/A" : freq.substr(0, freq.find('.'));
}

map<int, string> Hardware::get_cpu_cores() {
    map<int, string> cores;
    ifstream cpuinfo("/proc/cpuinfo");
    string line;
    int core = -1;
    string freq;
    
    while (getline(cpuinfo, line)) {
        if (line.find("processor") != string::npos) {
            if (core >= 0 && !freq.empty()) {
                cores[core] = freq;
            }
            size_t pos = line.find(':');
            if (pos != string::npos) {
                core = stoi(line.substr(pos + 2));
                freq = "";
            }
        } else if (line.find("CPU MHz") != string::npos && core >= 0) {
            size_t pos = line.find(':');
            if (pos != string::npos) {
                freq = line.substr(pos + 2);
                freq = freq.substr(0, freq.find('.'));
            }
        }
    }
    
    if (core >= 0 && !freq.empty()) {
        cores[core] = freq;
    }
    
    return cores;
}

float Hardware::get_cpu_usage() {
    static unsigned long last_total = 0;
    static unsigned long last_idle = 0;
    
    ifstream stat("/proc/stat");
    string line;
    
    if (getline(stat, line)) {
        string cpu;
        unsigned long user, nice, system, idle, iowait, irq, softirq, steal;
        
        stringstream ss(line);
        ss >> cpu >> user >> nice >> system >> idle >> iowait >> irq >> softirq >> steal;
        
        unsigned long total = user + nice + system + idle + iowait + irq + softirq + steal;
        unsigned long idle_total = idle + iowait;
        
        if (last_total > 0) {
            unsigned long diff_total = total - last_total;
            unsigned long diff_idle = idle_total - last_idle;
            
            last_total = total;
            last_idle = idle_total;
            
            if (diff_total > 0) {
                return 100.0f * (1.0f - (float)diff_idle / diff_total);
            }
        }
        
        last_total = total;
        last_idle = idle_total;
    }
    
    return 0.0f;
}

// ============================================
// Memory Information Functions
// ============================================

string Hardware::get_memory_info() {
    struct sysinfo info;
    if (sysinfo(&info) == 0) {
        long total_ram = info.totalram / (1024 * 1024);
        long free_ram = info.freeram / (1024 * 1024);
        
        stringstream ss;
        ss << total_ram << "MB total, " << free_ram << "MB free";
        return ss.str();
    }
    
    return "Unknown";
}

float Hardware::get_memory_usage() {
    ifstream meminfo("/proc/meminfo");
    string line;
    unsigned long total = 0, available = 0;
    
    while (getline(meminfo, line)) {
        if (line.find("MemTotal") != string::npos) {
            stringstream ss(line);
            string key;
            ss >> key >> total;
        } else if (line.find("MemAvailable") != string::npos) {
            stringstream ss(line);
            string key;
            ss >> key >> available;
            break;
        }
    }
    
    if (total > 0) {
        return 100.0f * (1.0f - (float)available / total);
    }
    
    return 0.0f;
}

unsigned long Hardware::get_memory_total() {
    struct sysinfo info;
    if (sysinfo(&info) == 0) {
        return info.totalram / (1024 * 1024);
    }
    return 0;
}

unsigned long Hardware::get_memory_used() {
    struct sysinfo info;
    if (sysinfo(&info) == 0) {
        return (info.totalram - info.freeram) / (1024 * 1024);
    }
    return 0;
}

// ============================================
// Temperature Functions
// ============================================

float Hardware::get_temperature() {
    ifstream temp("/sys/class/thermal/thermal_zone0/temp");
    string value;
    
    if (getline(temp, value)) {
        return stof(value) / 1000.0f;
    }
    
    return -1.0f;
}

map<string, float> Hardware::get_temperature_sensors() {
    map<string, float> sensors;
    
    for (int i = 0; i < 10; i++) {
        string path = "/sys/class/thermal/thermal_zone" + to_string(i) + "/temp";
        ifstream temp(path);
        string value;
        
        if (getline(temp, value)) {
            string name_path = "/sys/class/thermal/thermal_zone" + to_string(i) + "/type";
            ifstream name_file(name_path);
            string name;
            if (getline(name_file, name)) {
                sensors[name] = stof(value) / 1000.0f;
            } else {
                sensors["thermal_zone" + to_string(i)] = stof(value) / 1000.0f;
            }
        }
    }
    
    return sensors;
}

// ============================================
// GPIO Functions
// ============================================

int Hardware::read_gpio(int pin) {
    string path = "/sys/class/gpio/gpio" + to_string(pin) + "/value";
    
    // Check if GPIO is exported
    ifstream check("/sys/class/gpio/gpio" + to_string(pin) + "/direction");
    if (!check.is_open()) {
        // Export GPIO
        ofstream export_file("/sys/class/gpio/export");
        if (export_file.is_open()) {
            export_file << pin;
            export_file.close();
            this_thread::sleep_for(chrono::milliseconds(100));
        } else {
            return -1;
        }
    }
    
    ifstream gpio(path);
    string value;
    
    if (getline(gpio, value)) {
        return stoi(value);
    }
    
    return -1;
}

void Hardware::write_gpio(int pin, int value) {
    string path = "/sys/class/gpio/gpio" + to_string(pin) + "/value";
    
    // Check if GPIO is exported
    ifstream check("/sys/class/gpio/gpio" + to_string(pin) + "/direction");
    if (!check.is_open()) {
        // Export GPIO
        ofstream export_file("/sys/class/gpio/export");
        if (export_file.is_open()) {
            export_file << pin;
            export_file.close();
            this_thread::sleep_for(chrono::milliseconds(100));
        } else {
            return;
        }
    }
    
    // Set direction to out
    ofstream direction("/sys/class/gpio/gpio" + to_string(pin) + "/direction");
    if (direction.is_open()) {
        direction << "out";
        direction.close();
    }
    
    // Write value
    ofstream gpio(path);
    if (gpio.is_open()) {
        gpio << value;
        gpio.close();
    }
}

// ============================================
// Disk Information Functions
// ============================================

float Hardware::get_disk_usage() {
    struct statvfs stat;
    if (statvfs("/", &stat) == 0) {
        unsigned long total = stat.f_blocks * stat.f_frsize;
        unsigned long free = stat.f_bfree * stat.f_frsize;
        unsigned long used = total - free;
        
        if (total > 0) {
            return 100.0f * (float)used / total;
        }
    }
    return 0.0f;
}

float Hardware::get_disk_total() {
    struct statvfs stat;
    if (statvfs("/", &stat) == 0) {
        return (float)(stat.f_blocks * stat.f_frsize) / (1024 * 1024 * 1024);
    }
    return 0.0f;
}

float Hardware::get_disk_used() {
    struct statvfs stat;
    if (statvfs("/", &stat) == 0) {
        unsigned long total = stat.f_blocks * stat.f_frsize;
        unsigned long free = stat.f_bfree * stat.f_frsize;
        unsigned long used = total - free;
        return (float)used / (1024 * 1024 * 1024);
    }
    return 0.0f;
}

// ============================================
// Network Functions
// ============================================

string Hardware::get_ip_address() {
    struct ifaddrs *ifaddr, *ifa;
    string ip = "0.0.0.0";
    
    if (getifaddrs(&ifaddr) == -1) {
        return ip;
    }
    
    for (ifa = ifaddr; ifa != NULL; ifa = ifa->ifa_next) {
        if (ifa->ifa_addr == NULL) continue;
        
        if (ifa->ifa_addr->sa_family == AF_INET) {
            struct sockaddr_in *addr = (struct sockaddr_in *)ifa->ifa_addr;
            char addr_str[INET_ADDRSTRLEN];
            inet_ntop(AF_INET, &addr->sin_addr, addr_str, INET_ADDRSTRLEN);
            
            string addr_s(addr_str);
            if (addr_s != "127.0.0.1" && 
                addr_s.find("169.254") == string::npos &&
                strcmp(ifa->ifa_name, "lo") != 0) {
                ip = addr_s;
                break;
            }
        }
    }
    
    freeifaddrs(ifaddr);
    return ip;
}

string Hardware::get_mac_address() {
    ifstream addr_file("/sys/class/net/eth0/address");
    string mac;
    
    if (getline(addr_file, mac)) {
        return mac;
    }
    
    return "00:00:00:00:00:00";
}

map<string, string> Hardware::get_network_interfaces() {
    map<string, string> interfaces;
    struct ifaddrs *ifaddr, *ifa;
    
    if (getifaddrs(&ifaddr) == -1) {
        return interfaces;
    }
    
    for (ifa = ifaddr; ifa != NULL; ifa = ifa->ifa_next) {
        if (ifa->ifa_addr == NULL) continue;
        
        if (ifa->ifa_addr->sa_family == AF_INET) {
            struct sockaddr_in *addr = (struct sockaddr_in *)ifa->ifa_addr;
            char addr_str[INET_ADDRSTRLEN];
            inet_ntop(AF_INET, &addr->sin_addr, addr_str, INET_ADDRSTRLEN);
            interfaces[ifa->ifa_name] = addr_str;
        }
    }
    
    freeifaddrs(ifaddr);
    return interfaces;
}

// ============================================
= System Information Functions
// ============================================

string Hardware::get_kernel_version() {
    struct utsname buf;
    if (uname(&buf) == 0) {
        return string(buf.release);
    }
    return "Unknown";
}

string Hardware::get_os_version() {
    ifstream os_release("/etc/os-release");
    string line;
    string version = "Unknown";
    
    while (getline(os_release, line)) {
        if (line.find("PRETTY_NAME") != string::npos) {
            size_t start = line.find('"');
            size_t end = line.rfind('"');
            if (start != string::npos && end != string::npos && start < end) {
                version = line.substr(start + 1, end - start - 1);
                break;
            }
        }
    }
    
    return version;
}

string Hardware::get_hostname() {
    char hostname[256];
    if (gethostname(hostname, sizeof(hostname)) == 0) {
        return string(hostname);
    }
    return "Unknown";
}

string Hardware::get_uptime() {
    ifstream uptime_file("/proc/uptime");
    string line;
    
    if (getline(uptime_file, line)) {
        stringstream ss(line);
        double uptime_seconds;
        ss >> uptime_seconds;
        
        int days = (int)(uptime_seconds / 86400);
        int hours = (int)((uptime_seconds - days * 86400) / 3600);
        int minutes = (int)((uptime_seconds - days * 86400 - hours * 3600) / 60);
        int seconds = (int)(uptime_seconds - days * 86400 - hours * 3600 - minutes * 60);
        
        stringstream result;
        if (days > 0) {
            result << days << "d ";
        }
        result << hours << "h " << minutes << "m " << seconds << "s";
        return result.str();
    }
    
    return "Unknown";
}

string Hardware::get_current_time() {
    auto now = chrono::system_clock::now();
    auto time_t = chrono::system_clock::to_time_t(now);
    stringstream ss;
    ss << put_time(localtime(&time_t), "%Y-%m-%d %H:%M:%S");
    return ss.str();
}

// ============================================
// Additional Helper Functions
// ============================================

string Hardware::read_file(const string& path) {
    ifstream file(path);
    string content;
    if (getline(file, content)) {
        return content;
    }
    return "";
}

int Hardware::read_int_from_file(const string& path) {
    string content = read_file(path);
    if (!content.empty()) {
        try {
            return stoi(content);
        } catch (...) {
            return -1;
        }
    }
    return -1;
}

float Hardware::read_float_from_file(const string& path) {
    string content = read_file(path);
    if (!content.empty()) {
        try {
            return stof(content);
        } catch (...) {
            return -1.0f;
        }
    }
    return -1.0f;
}
