Add-Type -AssemblyName System.Windows.Forms

# Create the file picker dialog
$fileDialog = New-Object System.Windows.Forms.OpenFileDialog
$fileDialog.Title = "Select the vendor.img file"
$fileDialog.Filter = "IMG Files (*.img)|*.img"

# Show the file picker dialog and check if the user selected a file
if ($fileDialog.ShowDialog() -eq 'OK') {
    $vendor_img = $fileDialog.FileName

    # Get the parent folder of the script's location
    $parentFolder = Split-Path -Parent $PSScriptRoot

    # Pushing required tools to device and setting permissions...
    Write-Output "Pushing required tools..."
    adb push "$parentFolder/tools/e2fsck" /tmp/e2fsck
    adb push "$parentFolder/tools/resize2fs" /tmp/resize2fs
    adb push "$parentFolder/tools/bc" /tmp/bc
    Write-Output "Setting permissions..."
    adb shell "chmod +x /tmp/*"

    # Push vendor.img to the device
    adb push $vendor_img /tmp/vendor.img

    Write-Output "Calculating new vendor image size..."
    $vendor_size = $(adb shell "du -sm /tmp/vendor.img | cut -f1" 2> $null)

    adb shell "echo 'scale=0; $vendor_size * 1.7 + 10' > /tmp/new_vendor_size"
    $new_vendor_size_mb = $(adb shell "/tmp/bc < /tmp/new_vendor_size" 2> $null)

    # Check if $new_vendor_size_mb is a valid number
    if ($new_vendor_size_mb -as [double]) {
        $new_vendor_size_mb = [math]::Round($new_vendor_size_mb)
    }
    else {
        Write-Output "An error occurred while calculating the size, assuming a 950M as a safe value"
        $new_vendor_size_mb = 950  # Set a default value in case of error
    }

    Write-Output "Checking vendor image for errors..."
    adb shell "/tmp/e2fsck -f -y /tmp/vendor.img" > $null 2>&1

    Write-Output "Resizing vendor image..."
    adb shell "/tmp/resize2fs /tmp/vendor.img ${new_vendor_size_mb}M" > $null 2>&1

    Write-Output "Unsharing blocks..."
    adb shell "/tmp/e2fsck -y -E unshare_blocks /tmp/vendor.img" > $null 2>&1

    Write-Output "Mounting vendor image..."
    adb shell "mkdir /tmp/MOUNTPOINT"
    adb shell "mount -o rw /tmp/vendor.img /tmp/MOUNTPOINT" > $null 2>&1

    Write-Output "Editing fstab file..."
    adb shell "sed -i 's/inlinecrypt,//g; s/fileencryption=::inlinecrypt_optimized+wrappedkey_v0,//g; s/metadata_encryption=:wrappedkey_v0,//g; s/keydirectory=\/metadata\/vold\/metadata_encryption,//g' /tmp/MOUNTPOINT/etc/fstab.gs101" > $null 2>&1

    Write-Output "Unmounting vendor image..."
    adb shell "umount /tmp/MOUNTPOINT" > $null 2>&1

    Write-Output "Checking vendor image again..."
    adb shell "/tmp/e2fsck -f -y /tmp/vendor.img" > $null 2>&1

    Write-Output "Resizing vendor image again..."
    adb shell "/tmp/resize2fs -M /tmp/vendor.img" > $null 2>&1

    # Pull modified vendor.img back to the PC
    adb pull /tmp/vendor.img decrypted-vendor.img

    Write-Output "The decrypted-vendor.img file has been saved in the current directory."
    Write-Output "Script execution completed successfully."
}
else {
    Write-Output "No file selected. Script execution aborted."
}
