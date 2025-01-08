#!/bin/bash
if [[ $EUID -ne 0 ]]; then
    echo "Please run this script as root or with sudo privileges."
    exit 1
fi

create_group() {
    local group_name=$1
    if getent group "$group_name" > /dev/null 2>&1; then
        echo "Group '$group_name' already exists."
    else
        groupadd "$group_name"
        echo "Group '$group_name' created successfully."
    fi
}

create_user() {
    local user_name=$1
    local group_name=$2
    if id "$user_name" &>/dev/null; then
        echo "User '$user_name' already exists."
    else
        useradd -m -G "$group_name" -s /bin/bash "$user_name"
        echo "User '$user_name' created and added to group '$group_name'."
        
        echo "Please set a password for user '$user_name':"
        passwd "$user_name"
    fi
}

while true; do
    echo "User and Group Management Script"
    echo "---------------------------------"
    echo "1. Create a new group"
    echo "2. Create a new user in an existing group"
    echo "3. Exit"
    read -p "Enter your choice: " choice

    case $choice in
        1)
            read -p "Enter the name of the new group: " new_group
            create_group "$new_group"
            ;;
        2)
            read -p "Enter the name of the new user: " new_user
            read -p "Enter the group to assign this user to: " user_group
            if getent group "$user_group" > /dev/null 2>&1; then
                create_user "$new_user" "$user_group"
            else
                echo "Group '$user_group' does not exist. Please create the group first."
            fi
            ;;
        3)
            echo "Exiting script. Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid choice. Please try again."
            ;;
    esac
done
