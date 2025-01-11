#!/bin/bash

# Function for formatted output
function printInfo { printf "%-30s: %s\n" "$1" "$2"; }

# 1. Check SELinux mode and policies
function checkSELinux {
    printInfo "SELinux Status" "$(sestatus | grep 'SELinux status' | awk '{print $3}')"
    printInfo "SELinux Mode" "$(sestatus | grep 'Current mode' | awk '{print $3}')"
    printInfo "SELinux Policy" "$(sestatus | grep 'Loaded policy name' | awk '{print $4}')"
}

# 2. List users and groups
function listUsersGroups {
    printInfo "Users" "$(cut -d: -f1 /etc/passwd | tr '\n' ', ' | sed 's/, $//')"
    printInfo "Groups" "$(cut -d: -f1 /etc/group | tr '\n' ', ' | sed 's/, $//')"

    USERS=$(ls /home/)
    USER_COUNT=$(echo "$USERS" | wc -w)
    
    printInfo "Total Users in /home" "$USER_COUNT"

    echo "Users and Associated Groups:"
    for USER in $USERS; do
        GROUPS=$(groups "$USER" | cut -d: -f2 | sed 's/^ //')
        printInfo "$USER" "$GROUPS"
    done
}

# 3. Check ping, SSH, and Samba
function checkNetworkServices {
    PING_RESULT=$(ping -c 1 -W 2 google.com > /dev/null && echo "Reachable" || echo "Unreachable")
    SSH_RESULT=$(systemctl is-active sshd 2>/dev/null || echo "Not installed")
    SAMBA_RESULT=$(systemctl is-active smb 2>/dev/null || echo "Not installed")
    printInfo "Ping to External Network" "$PING_RESULT"
    printInfo "SSH Service" "$SSH_RESULT"
    printInfo "Samba Service" "$SAMBA_RESULT"
}

# 4. Check Git setup
function checkGit {
    GIT_VERSION=$(git --version 2>/dev/null || echo "Git not installed")
    GIT_STATUS=$(git status 2>/dev/null || echo "No Git repository")
    printInfo "Git Version" "$GIT_VERSION"
    printInfo "Git Repository Status" "$GIT_STATUS"
}

# 5. Retrieve server information
function retrieveServerInfo {
    printInfo "Hostname" "$(uname -n)"
    printInfo "IP Address" "$(hostname -I | awk '{print $1}')"
    printInfo "OS Version" "$(cat /etc/*release* | grep PRETTY_NAME | awk -F'=' '{print $2}' | tr -d '"')"
    printInfo "Kernel Version" "$(uname -sr)"
    printInfo "CPU Model" "$(grep 'model name' /proc/cpuinfo | head -1 | cut -d':' -f2 | sed 's/^ //')"
    printInfo "CPU Count" "$(grep -c processor /proc/cpuinfo)"
    printInfo "Memory Size" "$(grep MemTotal /proc/meminfo | awk '{print $2,$3}')"
    printInfo "Disk Size" "$(lsblk --nodeps --noheadings --output NAME,SIZE)"
}

# Run all checks
echo "=== Server Testing and Troubleshooting ==="
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

