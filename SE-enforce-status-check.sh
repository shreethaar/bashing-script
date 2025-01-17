#!/bin/bash

# Check if script is run with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo privileges"
    exit 1
fi

# Function to print section headers
print_header() {
    echo -e "\n=== $1 ==="
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if SELinux is installed
if ! command_exists sestatus; then
    echo "Error: SELinux is not installed on this system"
    exit 1
fi

# Check SELinux status
print_header "SELinux Status"
sestatus
if [ $? -ne 0 ]; then
    echo "Error: Failed to get SELinux status"
    exit 1
fi

# Check getenforce status
print_header "Current SELinux Enforcement Status"
getenforce
if [ $? -ne 0 ]; then
    echo "Error: Failed to get SELinux enforcement status"
    exit 1
fi

# Check SELinux config file
print_header "SELinux Configuration File Content"
if [ -f "/etc/selinux/config" ]; then
    echo "Contents of /etc/selinux/config:"
    cat /etc/selinux/config
    
    # Check specifically for SELINUX=enforcing
    if grep -q "^SELINUX=enforcing" /etc/selinux/config; then
        echo -e "\nSELinux is configured to be enforcing in config file"
    else
        echo -e "\nWarning: SELinux is not set to enforcing in config file"
    fi
else
    echo "Error: SELinux config file not found at /etc/selinux/config"
    exit 1
fi

# Set SELinux to enforcing mode
print_header "Setting SELinux to Enforcing Mode"
setenforce 1
if [ $? -eq 0 ]; then
    echo "Successfully set SELinux to enforcing mode"
    # Verify the change
    current_mode=$(getenforce)
    echo "Current SELinux mode: $current_mode"
else
    echo "Error: Failed to set SELinux to enforcing mode"
    exit 1
fi
