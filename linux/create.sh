#!/bin/bash

echo "I'm assuming you're already booted into lineage recovery with adb enabled, so press enter to begin"
read -p "Press Enter to continue"

echo "Preparing..."
adb push $PWD/tools/lz4 /tmp/lz4
adb shell chmod +x /tmp/lz4

echo "Mounting data..."
adb shell mount /dev/block/platform/14700000.ufs/by-name/userdata /data

echo "Temporarily disabling lock screen..."
adb shell mv /data/system/locksettings.db /tmp/locksettings.db
adb shell mv /data/system/locksettings.db-journal /tmp/locksettings.db-journal

echo "Creating tar of data..."
adb shell "tar -cf /data/media/0/newbackup.tar /data/adb /data/apex /data/app /data/data /data/media /data/misc /data/misc_ce /data/misc_de /data/system /data/system_ce /data/system_de /data/user_de /data/vendor" > /dev/null 2>&1

echo "Compressing..."
adb shell /tmp/lz4 -1 /data/media/0/newbackup.tar /data/media/0/newbackup.tar.lz4

echo "lz4 created, now to metadata"
adb shell dd if=/dev/block/platform/14700000.ufs/by-name/metadata of=/data/media/0/backupmetadata.img

echo "Pulling files..."
backup_folder="$PWD/backups"
date_string=$(date +"%Y%m%d_%H%M%S")
new_name="data_${date_string}.tar.lz4"
new_metadata_name="metadata_${date_string}.img"
new_vendor_name="vendor_${date_string}.img"
adb pull /data/media/0/newbackup.tar.lz4 "${backup_folder}/data/${new_name}"
adb pull /data/media/0/backupmetadata.img "${backup_folder}/metadata/${new_metadata_name}"

echo "Cleaning..."
adb shell rm -rf /data/media/0/backupmetadata.img /data/media/0/newbackup.tar /data/media/0/newbackup.tar.lz4

echo "Restoring lock screen..."
adb shell mv /tmp/locksettings.db /data/system/locksettings.db
adb shell mv /tmp/locksettings.db-journal /data/system/locksettings.db-journal

echo "Done!"
adb shell reboot system
read -p "Press Enter to exit"
