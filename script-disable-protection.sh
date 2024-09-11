#!/bin/bash

# Disable UFW (Firewall)
echo "Disabling UFW (Firewall)..."
sudo ufw disable

# Disable automatic updates
echo "Disabling automatic updates..."
sudo sed -i 's/^APT::Periodic::Update-Package-Lists "1";/APT::Periodic::Update-Package-Lists "0";/' /etc/apt/apt.conf.d/20auto-upgrades
sudo sed -i 's/^APT::Periodic::Unattended-Upgrade "1";/APT::Periodic::Unattended-Upgrade "0";/' /etc/apt/apt.conf.d/20auto-upgrades

# Remove ClamAV (Antivirus)
echo "Removing ClamAV..."
sudo apt remove -y clamav

# Disable AppArmor
echo "Disabling AppArmor..."
sudo systemctl stop apparmor
sudo systemctl disable apparmor
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash apparmor=0"/' /etc/default/grub
sudo update-grub

# Disable SELinux (if installed)
if command -v sestatus &> /dev/null; then
    echo "Disabling SELinux..."
    sudo setenforce 0
    sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
fi

# Disable Timeshift automatic backups
echo "Disabling Timeshift automatic backups..."
sudo apt remove -y timeshift

# Remove Firejail (if installed)
if command -v firejail &> /dev/null; then
    echo "Removing Firejail..."
    sudo apt remove -y firejail
fi

# Disable sudo password prompts
echo "Disabling sudo password prompts..."
echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/nopasswd

# Remove Fail2Ban (if installed)
if command -v fail2ban-client &> /dev/null; then
    echo "Removing Fail2Ban..."
    sudo apt remove -y fail2ban
fi

# Enable auto-login for the current user
echo "Enabling auto-login..."
sudo sed -i 's/^#  AutomaticLoginEnable = true/AutomaticLoginEnable = true/' /etc/lightdm/lightdm.conf
sudo sed -i "s/^#  AutomaticLogin = user1/AutomaticLogin = $USER/" /etc/lightdm/lightdm.conf

# Final message
echo "All protections disabled. Please reboot the system for changes to take effect."

