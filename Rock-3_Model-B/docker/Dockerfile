# ============================================
# Docker Compose for Rock 3 Build Environment
# ============================================

version: '3.8'

services:
  # Main build container
  builder:
    build:
      context: .
      dockerfile: Dockerfile
      args:
        USERNAME: ${USERNAME:-builder}
        USER_UID: ${UID:-1000}
        USER_GID: ${GID:-1000}
    container_name: rock3-builder
    hostname: rock3-builder
    restart: unless-stopped
    
    # User mapping
    user: ${UID:-1000}:${GID:-1000}
    
    # Volume mounts
    volumes:
      # Source code
      - ../src:/workspace/src:rw
      # Build output
      - ../output:/workspace/output:rw
      # Trace data
      - ../traces:/workspace/traces:rw
      # Scripts
      - ../scripts:/workspace/scripts:rw
      # Configurations
      - ../configs:/workspace/configs:rw
      # Cache for ccache
      - ccache-cache:/home/${USERNAME:-builder}/.ccache
      # Docker socket (optional)
      - /var/run/docker.sock:/var/run/docker.sock:ro
    
    # Environment variables
    environment:
      - CROSS_COMPILE=aarch64-linux-gnu-
      - ARCH=arm64
      - USER=${USERNAME:-builder}
      - HOME=/home/${USERNAME:-builder}
      - CCACHE_DIR=/home/${USERNAME:-builder}/.ccache
      - CCACHE_SIZE=2G
      - DEBIAN_FRONTEND=noninteractive
    
    # Privileges for debugging
    privileged: true
    cap_add:
      - SYS_ADMIN
      - SYS_PTRACE
      - SYS_TIME
      - SYS_NICE
      - SYS_RESOURCE
      - SYSLOG
      - DAC_READ_SEARCH
      - NET_ADMIN
      - NET_RAW
    
    # Devices
    devices:
      - /dev/fuse
      - /dev/i2c-1:/dev/i2c-1:rw
      - /dev/spidev0.0:/dev/spidev0.0:rw
    
    # Shared memory
    shm_size: 2g
    
    # Network
    networks:
      - build-network
    
    # Command (keep running)
    command: tail -f /dev/null
    
    # Resource limits
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 4G
        reservations:
          cpus: '2'
          memory: 2G

  # Development container with additional tools
  dev:
    build:
      context: .
      dockerfile: Dockerfile
      args:
        USERNAME: ${USERNAME:-builder}
        USER_UID: ${UID:-1000}
        USER_GID: ${GID:-1000}
    container_name: rock3-dev
    hostname: rock3-dev
    restart: unless-stopped
    
    user: ${UID:-1000}:${GID:-1000}
    
    volumes:
      - ../src:/workspace/src:rw
      - ../output:/workspace/output:rw
      - ../traces:/workspace/traces:rw
      - ../scripts:/workspace/scripts:rw
      - ../configs:/workspace/configs:rw
      - ccache-cache:/home/${USERNAME:-builder}/.ccache
      - /var/run/docker.sock:/var/run/docker.sock:ro
    
    environment:
      - CROSS_COMPILE=aarch64-linux-gnu-
      - ARCH=arm64
      - USER=${USERNAME:-builder}
      - HOME=/home/${USERNAME:-builder}
      - CCACHE_DIR=/home/${USERNAME:-builder}/.ccache
    
    privileged: true
    cap_add:
      - SYS_ADMIN
      - SYS_PTRACE
    shm_size: 2g
    
    networks:
      - build-network
    
    # Start with development tools
    command: /bin/bash
    
    ports:
      - "2222:22"  # SSH port mapping
      - "8080:8080" # For any web services

  # QEMU for cross-architecture testing
  qemu:
    image: multiarch/qemu-user-static:latest
    container_name: rock3-qemu
    privileged: true
    command: ["--reset", "--persistent", "yes"]
    networks:
      - build-network
    restart: unless-stopped

  # Monitoring container
  monitor:
    image: alpine:latest
    container_name: rock3-monitor
    command: sh -c "apk add procps htop && htop"
    pid: host
    privileged: true
    networks:
      - build-network
    profiles:
      - monitor

# -------------------- Networks --------------------
networks:
  build-network:
    driver: bridge
    name: rock3-network

# -------------------- Volumes --------------------
volumes:
  ccache-cache:
    name: rock3-ccache
    driver: local
