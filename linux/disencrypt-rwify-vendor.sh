#!/bin/bash

# Create the file picker dialog
vendor_img=$(zenity --file-selection --title="Select the vendor.img file" --file-filter="IMG Files | *.img")

# Check if the user selected a file
if [[ -n $vendor_img ]]; then
    # Pushing required tools to device and setting permissions...
    echo "Pushing required tools..."
    adb push "$PWD/tools/e2fsck" /tmp/e2fsck
    adb push "$PWD/tools/resize2fs" /tmp/resize2fs
    adb push "$PWD/tools/bc" /tmp/bc
    echo "Setting permissions..."
    adb shell "chmod +x /tmp/*"

    # Push vendor.img to the device
    adb push "$vendor_img" /tmp/vendor.img

    echo "Calculating new vendor image size..."
    vendor_size=$(adb shell "du -sm /tmp/vendor.img | cut -f1" 2> /dev/null)

    adb shell "echo 'scale=0; $vendor_size * 1.7 + 10' > /tmp/new_vendor_size"
    new_vendor_size_mb=$(adb shell "/tmp/bc < /tmp/new_vendor_size" 2> /dev/null | awk '{print int($1)}')

    # Check if $new_vendor_size_mb is a valid number
    if [[ $new_vendor_size_mb =~ ^[0-9]+$ ]]; then
        new_vendor_size_mb=$(printf "%.0f" "$new_vendor_size_mb")
    else
        echo "An error occurred while calculating the size, assuming 950M as a safe value"
        new_vendor_size_mb=950  # Set a default value in case of error
    fi

    echo "Checking vendor image for errors..."
    adb shell "/tmp/e2fsck -f -y /tmp/vendor.img" > /dev/null 2>&1

    echo "Resizing vendor image..."
    adb shell "/tmp/resize2fs /tmp/vendor.img ${new_vendor_size_mb}M" > /dev/null 2>&1

    echo "Unsharing blocks..."
    adb shell "/tmp/e2fsck -y -E unshare_blocks /tmp/vendor.img" > /dev/null 2>&1

    echo "Mounting vendor image..."
    adb shell "mkdir /tmp/MOUNTPOINT"
    adb shell "mount -o rw /tmp/vendor.img /tmp/MOUNTPOINT" > /dev/null 2>&1

    echo "Editing fstab file..."
    adb shell "sed -i 's/inlinecrypt,//g; s/fileencryption=::inlinecrypt_optimized+wrappedkey_v0,//g; s/metadata_encryption=:wrappedkey_v0,//g; s/keydirectory=\/metadata\/vold\/metadata_encryption,//g' /tmp/MOUNTPOINT/etc/fstab.gs101" > /dev/null 2>&1

    echo "Unmounting vendor image..."
    adb shell "umount /tmp/MOUNTPOINT" > /dev/null 2>&1

    echo "Checking vendor image again..."
    adb shell "/tmp/e2fsck -f -y /tmp/vendor.img" > /dev/null 2>&1

    echo "Resizing vendor image again..."
    adb shell "/tmp/resize2fs -M /tmp/vendor.img" > /dev/null 2>&1

    # Pull modified vendor.img back to the PC
    adb pull /tmp/vendor.img decrypted-vendor.img

    echo "The decrypted-vendor.img file has been saved in the current directory."
    echo "Script execution completed successfully."
else
    echo "No file selected. Script execution aborted"
fi
