#!/bin/bash

# Ensure the script is run with sudo or as root
if [[ "$EUID" -ne 0 ]]; then
    echo "Error: This script must be run as root or with sudo privileges."
    exit 1
fi

# Function for formatted output
function printInfo { printf "%-30s: %s\n" "$1" "$2"; }

# Function for table rows
function printRow {
    printf "| %-28s | %-50s |\n" "$1" "$2"
}

# Function for table headers
function printHeader {
    echo "+------------------------------+----------------------------------------------------+"
    printf "| %-28s | %-50s |\n" "$1" "$2"
    echo "+------------------------------+----------------------------------------------------+"
}

# Function for table footer
function printFooter {
    echo "+------------------------------+----------------------------------------------------+"
}

# 1. Check SELinux mode and policies
function checkSELinux {
    printHeader "SELinux Check" "Details"
    if command -v sestatus >/dev/null 2>&1; then
        printRow "SELinux Status" "$(sestatus | grep 'SELinux status' | awk '{print $3}')"
        printRow "SELinux Mode" "$(sestatus | grep 'Current mode' | awk '{print $3}')"
        printRow "SELinux Policy" "$(sestatus | grep 'Loaded policy name' | awk '{print $4}')"
    else
        printRow "SELinux Status" "SELinux not installed"
    fi
    printFooter
}

# 2. List users and groups with relationships
function listUsersGroups {
    printHeader "Users and Groups" "Details"
    if [ -d "/home" ]; then
        USERS=$(ls /home/)
        USER_COUNT=$(echo "$USERS" | wc -w)
        printRow "Total Users in /home" "$USER_COUNT"
        echo
        printHeader "User" "Primary & Secondary Groups"
        for USER in $USERS; do
            if id "$USER" >/dev/null 2>&1; then
                # Get primary group
                PRIMARY_GROUP=$(id -gn "$USER" 2>/dev/null)
                # Get all groups
                ALL_GROUPS=$(groups "$USER" 2>/dev/null | cut -d: -f2 | sed 's/^ //')
                # Format the output to show primary group first
                if [ -n "$PRIMARY_GROUP" ]; then
                    GROUP_INFO="Primary: $PRIMARY_GROUP"
                    # Get secondary groups by removing primary group
                    SECONDARY_GROUPS=$(echo "$ALL_GROUPS" | sed "s/$PRIMARY_GROUP//" | sed 's/^ *//' | sed 's/ /, /g')
                    if [ -n "$SECONDARY_GROUPS" ]; then
                        GROUP_INFO="$GROUP_INFO, Secondary: $SECONDARY_GROUPS"
                    fi
                else
                    GROUP_INFO="(no groups)"
                fi
                printRow "$USER" "${GROUP_INFO:-(no groups)}"
            fi
        done
    else
        printRow "Error" "Home directory not found"
    fi
    printFooter
}

# 3. List groups and their members
function listRootCreatedGroups {
    printHeader "Group Membership Details" "Members"
    if [ -f "/etc/group" ]; then
        # List all groups created by root (GID >= 1000)
        while IFS=':' read -r GROUP_NAME GROUP_PASS GROUP_ID GROUP_MEMBERS; do
            if [ "$GROUP_ID" -ge 1000 ]; then
                # Get all users who have this as their primary group
                PRIMARY_USERS=$(awk -F: "\$4 == $GROUP_ID {print \$1}" /etc/passwd | tr '\n' ',' | sed 's/,$//')
                
                # Format the output
                MEMBER_INFO=""
                if [ -n "$PRIMARY_USERS" ]; then
                    MEMBER_INFO="Primary: $PRIMARY_USERS"
                fi
                if [ -n "$GROUP_MEMBERS" ]; then
                    if [ -n "$MEMBER_INFO" ]; then
                        MEMBER_INFO="$MEMBER_INFO, Secondary: $GROUP_MEMBERS"
                    else
                        MEMBER_INFO="Secondary: $GROUP_MEMBERS"
                    fi
                fi
                
                printRow "$GROUP_NAME" "${MEMBER_INFO:-No members}"
            fi
        done < /etc/group
    else
        printRow "Error" "Group file not found"
    fi
    printFooter
}

# 4. Check network services
function checkNetworkServices {
    printHeader "Network Services Check" "Details"
    # Test internet connectivity with multiple hosts
    PING_HOSTS=("8.8.8.8" "1.1.1.1" "google.com")
    PING_RESULT="Unreachable"
    for host in "${PING_HOSTS[@]}"; do
        if ping -c 1 -W 2 "$host" >/dev/null 2>&1; then
            PING_RESULT="Reachable (via $host)"
            break
        fi
    done
    
    SSH_RESULT=$(systemctl is-active sshd 2>/dev/null || echo "Not installed")
    SAMBA_RESULT=$(systemctl is-ac
