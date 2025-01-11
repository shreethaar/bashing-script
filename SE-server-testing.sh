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
    if command -v sestatus >/dev/null 2>&1; then
        printRow "SELinux Status" "$(sestatus | grep 'SELinux status' | awk '{print $3}')"
        printRow "SELinux Mode" "$(sestatus | grep 'Current mode' | awk '{print $3}')"
        printRow "SELinux Policy" "$(sestatus | grep 'Loaded policy name' | awk '{print $4}')"
    else
        printRow "SELinux Status" "SELinux not installed"
    fi
    printFooter
}

# 2. List users and groups
function listUsersGroups {
    printHeader "Users and Groups" "Details"
    if [ -d "/home" ]; then
        USERS=$(ls /home/)
        USER_COUNT=$(echo "$USERS" | wc -w)
        printRow "Total Users in /home" "$USER_COUNT"
        echo "Users and Associated Groups:"
        printHeader "User" "Groups"
        for USER in $USERS; do
            if id "$USER" >/dev/null 2>&1; then
                GROUPS=$(groups "$USER" 2>/dev/null | cut -d: -f2 | sed 's/^ //')
                printRow "$USER" "${GROUPS:-(no groups)}"
            fi
        done
    else
        printRow "Error" "Home directory not found"
    fi
    printFooter
}

# 3. List groups created by root
function listRootCreatedGroups {
    printHeader "Root-Created Groups" "Details"
    if [ -f "/etc/group" ]; then
        # List all groups created by the root user (typically non-system groups with GID > 1000)
        GROUPS=$(awk -F: '$3 >= 1000 {print $1}' /etc/group)
        if [[ -z "$GROUPS" ]]; then
            printRow "No groups found" "No groups created by root"
        else
            while IFS= read -r GROUP; do
                printRow "$GROUP" "Created by root"
            done <<< "$GROUPS"
        fi
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
    SAMBA_RESULT=$(systemctl is-active smb 2>/dev/null || echo "Not installed")
    printRow "Internet Connectivity" "$PING_RESULT"
    printRow "SSH Service" "$SSH_RESULT"
    printRow "Samba Service" "$SAMBA_RESULT"
    printFooter
}

# 5. Check Git setup
function checkGit {
    printHeader "Git Setup Check" "Details"
    if command -v git >/dev/null 2>&1; then
        GIT_VERSION=$(git --version)
        if git rev-parse --git-dir >/dev/null 2>&1; then
            GIT_STATUS=$(git status --porcelain)
            if [[ -z "$GIT_STATUS" ]]; then
                GIT_STATUS="Clean repository"
            else
                GIT_STATUS="Modified files present"
            fi
        else
            GIT_STATUS="No Git repository"
        fi
    else
        GIT_VERSION="Git not installed"
        GIT_STATUS="N/A"
    fi
    printRow "Git Version" "$GIT_VERSION"
    printRow "Git Repository Status" "$GIT_STATUS"
    printFooter
}

# 6. Retrieve server information
function retrieveServerInfo {
    printHeader "Server Information" "Details"
    printRow "Hostname" "$(hostname -f 2>/dev/null || hostname)"
    
    # Get primary IP address more reliably
    IP_ADDR=$(ip -4 addr show scope global | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)
    printRow "IP Address" "${IP_ADDR:-Not available}"
    
    # Get OS information more reliably
    if [ -f "/etc/os-release" ]; then
        source "/etc/os-release"
        printRow "OS Version" "${PRETTY_NAME:-Unknown}"
    else
        printRow "OS Version" "Unknown"
    fi
    
    printRow "Kernel Version" "$(uname -sr)"
    
    # CPU information
    if [ -f "/proc/cpuinfo" ]; then
        CPU_MODEL=$(grep -m1 'model name' /proc/cpuinfo | cut -d':' -f2 | sed 's/^ //')
        CPU_COUNT=$(grep -c processor /proc/cpuinfo)
        printRow "CPU Model" "${CPU_MODEL:-Unknown}"
        printRow "CPU Count" "$CPU_COUNT"
    fi
    
    # Memory information
    if [ -f "/proc/meminfo" ]; then
        MEM_TOTAL=$(awk '/MemTotal/ {printf "%.2f GB", $2/1024/1024}' /proc/meminfo)
        printRow "Memory Size" "${MEM_TOTAL:-Unknown}"
    fi
    
    # Disk information
    if command -v lsblk >/dev/null 2>&1; then
        DISK_INFO=$(lsblk --nodeps --noheadings --output NAME,SIZE | awk '{printf "%s: %s, ", $1, $2}' | sed 's/, $//')
        printRow "Disk Size" "${DISK_INFO:-Unknown}"
    fi
    printFooter
}

# 7. Test LDAP services
function testLDAPServices {
    printHeader "LDAP Services Check" "Details"
    
    # Check if LDAP client tools are installed
    if command -v ldapsearch >/dev/null 2>&1; then
        LDAP_STATUS=$(systemctl is-active slapd 2>/dev/null || echo "Not installed")
        LDAP_PORT_OPEN=$(ss -tuln | grep ":389" >/dev/null 2>&1 && echo "Open" || echo "Closed")
        
        # Check multiple possible LDAP config locations
        for conf in "/etc/ldap/slapd.conf" "/etc/openldap/slapd.conf"; do
            if [ -f "$conf" ]; then
                LDAP_CONFIG="Exists ($conf)"
                break
            fi
        done
        LDAP_CONFIG=${LDAP_CONFIG:-"Missing"}
        
        LDAP_PROCESS=$(pgrep slapd >/dev/null && echo "Running" || echo "Not Running")
        
        # Check multiple possible database locations
        for db_path in "/var/lib/ldap" "/var/lib/openldap"; do
            if [ -d "$db_path" ]; then
                LDAP_DB_ACCESS="Accessible ($db_path)"
                break
            fi
        done
        LDAP_DB_ACCESS=${LDAP_DB_ACCESS:-"Not Found"}
    else
        LDAP_STATUS="LDAP tools not installed"
        LDAP_PORT_OPEN="N/A"
        LDAP_CONFIG="N/A"
        LDAP_PROCESS="N/A"
        LDAP_DB_ACCESS="N/A"
    fi
    
    printRow "LDAP Service Status" "$LDAP_STATUS"
    printRow "LDAP Port 389" "$LDAP_PORT_OPEN"
    printRow "LDAP Configuration" "$LDAP_CONFIG"
    printRow "LDAP Process" "$LDAP_PROCESS"
    printRow "LDAP Database" "$LDAP_DB_ACCESS"
    printFooter
}

# 8. Check HTTPD Service, Firewall Rules, and Open Ports
function testHTTPDandNetwork {
    printHeader "HTTPD & Network Check" "Details"
    
    # Check for both Apache and Nginx
    if systemctl is-active httpd >/dev/null 2>&1; then
        HTTPD_STATUS="Active (Apache)"
    elif systemctl is-active apache2 >/dev/null 2>&1; then
        HTTPD_STATUS="Active (Apache2)"
    elif systemctl is-active nginx >/dev/null 2>&1; then
        HTTPD_STATUS="Active (Nginx)"
    else
        HTTPD_STATUS="Not installed/inactive"
    fi
    
    # Check web server process
    if pgrep -f "httpd|apache2|nginx" >/dev/null; then
        HTTPD_PROCESS="Running"
    else
        HTTPD_PROCESS="Not Running"
    fi
    
    # Check ports
    HTTP_PORT_OPEN=$(ss -tuln | grep -E ":80\s" >/dev/null && echo "Open" || echo "Closed")
    HTTPS_PORT_OPEN=$(ss -tuln | grep -E ":443\s" >/dev/null && echo "Open" || echo "Closed")
    
    # Check firewall status and rules
    if command -v firewall-cmd >/dev/null 2>&1; then
        FIREWALL_RULES=$(firewall-cmd --list-all 2>/dev/null)
    elif command -v ufw >/dev/null 2>&1; then
        FIREWALL_RULES=$(ufw status 2>/dev/null)
    elif command -v iptables >/dev/null 2>&1; then
        FIREWALL_RULES=$(iptables -L -n 2>/dev/null)
    else
        FIREWALL_RULES="No firewall detected"
    fi
    
    # Get list of open ports
    OPEN_PORTS=$(ss -tuln | awk 'NR>1 {print $5}' | grep -v "\*" | cut -d: -f2 | sort -nu | tr '\n' ',' | sed 's/,$//')
    
    printRow "Web Server Status" "$HTTPD_STATUS"
    printRow "Web Server Process" "$HTTPD_PROCESS"
    printRow "HTTP Port 80" "$HTTP_PORT_OPEN"
    printRow "HTTPS Port 443" "$HTTPS_PORT_OPEN"
    printRow "Firewall Status" "${FIREWALL_RULES:0:30}..."
    printRow "Open Ports" "${OPEN_PORTS:-None}"
    printFooter
}

# Main execution
echo "=== Server Testing and Troubleshooting ==="
echo "Start Time: $(date)"
echo

# Run all checks with error handling
for check in checkSELinux listUsersGroups listRootCreatedGroups checkNetworkServices checkGit testLDAPServices testHTTPDandNetwork retrieveServerInfo; do
    echo "Running $check..."
    if ! $check; then
        echo "Warning: $check encountered an error"
    fi
    echo
done

echo "End Time: $(date)"
