#!/bin/bash

# main menu
function show_menu {
    clear
    echo "=== Backup Manager ==="
    echo "1. Create Backup"
    echo "2. Restore Backup"
    echo "3. Patch a vendor image"
    echo "4. Exit"
}

# create function
function create_backup {
    script="$PWD/linux/create.sh"
    bash "$script"
}

# restore function
function restore_backup {
    script="$PWD/linux/restore.sh"
    bash "$script"
}

# patch function
function patch_vendor {
    script="$PWD/linux/disencrypt-rwify-vendor.sh"
    bash "$script"
}

# main script
warning_file_path="$PWD/backup_warning.txt"

if [ ! -f "$warning_file_path" ]; then
    echo "To use this backup system, you need to modify your vendor partition to allow your data to be decrypted. Note that this means you'll have to flash the modified vendor with fastboot and then wipe data to make sure the data is not encrypted. You will also need to flash that vendor image every time you restore to the ROM. This backup system cannot be used to restore backups on a different ROM than the one it was taken on. This is useful for testing other ROMs and going back to your original one."

    read -p "Do you want to create a patched vendor image? (yes/no): " create_patched_vendor

    if [ "$create_patched_vendor" = "yes" ]; then
        patch_vendor
    fi

    # Create the warning file to indicate that the message has been displayed
    touch "$warning_file_path"

    # Wait for input to continue
    read -n 1 -s -r -p "Press any key to continue..."
fi

while true; do
    show_menu
    read -p "Please select an option: " input

    case $input in
        "1") create_backup ;;
        "2") restore_backup ;;
        "3") patch_vendor ;;
        "4") break ;;
        *) echo "Invalid option selected." ;;
    esac

    # Wait for input to continue
    read -n 1 -s -r -p "Press any key to continue..."
done
