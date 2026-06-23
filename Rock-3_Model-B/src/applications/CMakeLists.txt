cmake_minimum_required(VERSION 3.10)
project(rock3-app)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Set output directory
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

# Find packages
find_package(Threads REQUIRED)

# Include directories
include_directories(${CMAKE_SOURCE_DIR}/include)
include_directories(${CMAKE_SOURCE_DIR}/src)

# Source files
set(SOURCES
    src/main.cpp
    src/hardware.cpp
)

# Create executable
add_executable(rock3-app ${SOURCES})

# Link libraries
target_link_libraries(rock3-app
    ${CMAKE_THREAD_LIBS_INIT}
    pthread
    rt
    stdc++fs
)

# Install
install(TARGETS rock3-app DESTINATION bin)

# Debug build
set(CMAKE_BUILD_TYPE Debug)

# Add compile options
target_compile_options(rock3-app PRIVATE
    -Wall
    -Wextra
    -Werror
    -O2
    -g
)

# For cross-compilation (ARM64)
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    if(CMAKE_CXX_COMPILER MATCHES "aarch64")
        message(STATUS "Cross-compiling for ARM64")
        add_compile_options(-march=armv8-a+crc)
    endif()
endif()
