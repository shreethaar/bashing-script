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

# 3. List groups created by root

function listRootCreatedGroups {
    printHeader "Root-Created Groups" "Details"
    # List all groups created by the root user (typically non-system groups with GID > 1000)
    GROUPS=$(awk -F: '$3 >= 1000 {print $1}' /etc/group)
    if [[ -z "$GROUPS" ]]; then
        printRow "No groups found" "No groups created by root"
    else
        while IFS= read -r GROUP; do
            printRow "$GROUP" "Created by root"
        done <<< "$GROUPS"
    fi
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

# 6. Test LDAP services
function testLDAPServices {
    printHeader "LDAP Services Check" "Details"
    # Check if slapd service is active
    LDAP_STATUS=$(systemctl is-active slapd 2>/dev/null || echo "Not installed")
    printRow "LDAP Service Status" "$LDAP_STATUS"

    # Check if the LDAP port (389) is open
    LDAP_PORT_OPEN=$(ss -tuln | grep ":389" > /dev/null && echo "Open" || echo "Closed")
    printRow "LDAP Port 389 Open" "$LDAP_PORT_OPEN"

    # Verify if the LDAP configuration files exist and are accessible
    LDAP_CONFIG=$(test -f /etc/ldap/slapd.conf && echo "Exists" || echo "Missing")
    printRow "LDAP Configuration File" "$LDAP_CONFIG"

    # Check if the slapd process is running
    LDAP_PROCESS=$(ps aux | grep '[s]lapd' > /dev/null && echo "Running" || echo "Not Running")
    printRow "LDAP Process Running" "$LDAP_PROCESS"

    # Check the database directory permissions (replace with actual path if needed)
    DB_PATH="/var/lib/ldap"
    LDAP_DB_ACCESS=$(test -d "$DB_PATH" && echo "Accessible" || echo "Not Found/Accessible")
    printRow "LDAP Database Directory" "$LDAP_DB_ACCESS"

    printFooter
}


# 7. Check HTTPD Service, Firewall Rules, and Open Ports
function testHTTPDandNetwork {
    printHeader "HTTPD & Network Check" "Details"

    # Check HTTPD service status
    HTTPD_STATUS=$(systemctl is-active httpd 2>/dev/null || echo "Not installed")
    printRow "HTTPD Service Status" "$HTTPD_STATUS"

    # Check if HTTPD process is running
    HTTPD_PROCESS=$(ps aux | grep '[h]ttpd' > /dev/null && echo "Running" || echo "Not Running")
    printRow "HTTPD Process Running" "$HTTPD_PROCESS"

    # Check if HTTP/HTTPS ports are open (80 and 443)
    HTTP_PORT_OPEN=$(ss -tuln | grep ":80" > /dev/null && echo "Open" || echo "Closed")
    HTTPS_PORT_OPEN=$(ss -tuln | grep ":443" > /dev/null && echo "Open" || echo "Closed")
    printRow "HTTP Port 80 Open" "$HTTP_PORT_OPEN"
    printRow "HTTPS Port 443 Open" "$HTTPS_PORT_OPEN"

    # List firewall rules using firewall-cmd
    FIREWALL_RULES=$(firewall-cmd --list-all 2>/dev/null || echo "Firewall-cmd not installed or inactive")
    printRow "Firewall Rules" "$FIREWALL_RULES"

    # Check all open ports on the server
    OPEN_PORTS=$(ss -tuln | awk 'NR>1 {print $5}' | awk -F: '{print $NF}' | sort -n | uniq | tr '\n' ', ')
    printRow "All Open Ports" "${OPEN_PORTS%,}" # Remove trailing comma

    printFooter
}

# Run all checks
echo "=== Server Testing and Troubleshooting ==="
echo

# Perform SELinux check
checkSELinux
echo

# List users and groups
listUsersGroups
echo

# List groups created by root
listRootCreatedGroups
echo

# Check network services (DNS and Ping)
checkNetworkServices
echo

# Check Git version and setup
checkGit
echo

# Test LDAP Services
testLDAPServices
echo

# Test HTTPD service, firewall rules, and open ports
testHTTPDandNetwork
echo

# Retrieve and display server information
echo "=== Server Information ==="
retrieveServerInfo
