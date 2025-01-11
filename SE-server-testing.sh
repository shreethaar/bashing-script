#!/bin/bash

# Function for table rows
function printRow {
    printf "| %-28s | %-30s |\n" "$1" "$2"
}

# Function for table headers
function printHeader {
    echo "+------------------------------+--------------------------------+"
    printf "| %-28s | %-30s |\n" "$1" "$2"
    echo "+------------------------------+--------------------------------+"
}

# Function for table footer
function printFooter {
    echo "+------------------------------+--------------------------------+"
}

# 1. Check SELinux mode and policies
function checkSELinux {
    printHeader "SELinux Check" "Details"
    printRow "SELinux Status" "$(sestatus | grep 'SELinux status' | awk '{print $3}')"
    printRow "SELinux Mode" "$(sestatus | grep 'Current mode' | awk '{print $3}')"
    printRow "SELinux Policy" "$(sestatus | grep 'Loaded policy name' | awk '{print $4}')"
    printFooter
}

# 2. List users and groups
function listUsersGroups {
    printHeader "Users and Groups" "Details"
    
    USERS=$(ls /home/)
    USER_COUNT=$(echo "$USERS" | wc -w)
    printRow "Total Users in /home" "$USER_COUNT"

    echo "Users and Associated Groups:"
    printHeader "User" "Groups"
    for USER in $USERS; do
        GROUPS=$(groups "$USER" | cut -d: -f2 | sed 's/^ //')
        printRow "$USER" "$GROUPS"
    done
    printFooter
}

# 3. Check ping, SSH, and Samba
function checkNetworkServices {
    printHeader "Network Services Check" "Details"
    PING_RESULT=$(ping -c 1 -W 2 google.com > /dev/null && echo "Reachable" || echo "Unreachable")
    SSH_RESULT=$(systemctl is-active sshd 2>/dev/null || echo "Not installed")
    SAMBA_RESULT=$(systemctl is-active smb 2>/dev/null || echo "Not installed")
    printRow "Ping to External Network" "$PING_RESULT"
    printRow "SSH Service" "$SSH_RESULT"
    printRow "Samba Service" "$SAMBA_RESULT"
    printFooter
}

# 4. Check Git setup
function checkGit {
    printHeader "Git Setup Check" "Details"
    GIT_VERSION=$(git --version 2>/dev/null || echo "Git not installed")
    GIT_STATUS=$(git status 2>/dev/null || echo "No Git repository")
    printRow "Git Version" "$GIT_VERSION"
    printRow "Git Repository Status" "$GIT_STATUS"
    printFooter
}

# 5. Retrieve server information
function retrieveServerInfo {
    printHeader "Server Information" "Details"
    printRow "Hostname" "$(uname -n)"
    printRow "IP Address" "$(hostname -I | awk '{print $1}')"
    printRow "OS Version" "$(cat /etc/*release* | grep PRETTY_NAME | awk -F'=' '{print $2}' | tr -d '"')"
    printRow "Kernel Version" "$(uname -sr)"
    printRow "CPU Model" "$(grep 'model name' /proc/cpuinfo | head -1 | cut -d':' -f2 | sed 's/^ //')"
    printRow "CPU Count" "$(grep -c processor /proc/cpuinfo)"
    printRow "Memory Size" "$(grep MemTotal /proc/meminfo | awk '{print $2,$3}')"
    printRow "Disk Size" "$(lsblk --nodeps --noheadings --output NAME,SIZE)"
    printFooter
}

# Run all checks
echo "=== Server Testing and Troubleshooting ==="
echo
checkSELinux
echo
listUsersGroups
echo
checkNetworkServices
echo
checkGit
echo
echo "=== Server Information ==="
retrieveServerInfo
