Write-Host "I'm assuming you're already booted into lineage recovery with adb enabled, so press enter to begin"
Read-Host "Press Enter to continue"

Write-Host "Preparing..."
adb push .\tools\lz4 /tmp/lz4
adb shell chmod +x /tmp/lz4

Write-Host "Mounting data..."
adb shell mount /dev/block/platform/14700000.ufs/by-name/userdata /data

Write-Host "Temporarily disabling lock screen..."
adb shell mv /data/system/locksettings.db /tmp/locksettings.db
adb shell mv /data/system/locksettings.db-journal /tmp/locksettings.db-journal

Write-Host "Creating tar of data..."
adb shell tar -cf /data/media/0/newbackup.tar /data/adb /data/apex /data/app /data/data /data/media /data/misc /data/misc_ce /data/misc_de /data/system /data/system_ce /data/system_de /data/user_de /data/vendor

Write-Host "Compressing..."
adb shell /tmp/lz4 -1 /data/media/0/newbackup.tar /data/media/0/newbackup.tar.lz4

Write-Host "lz4 created, now to metadata"
adb shell dd if=/dev/block/platform/14700000.ufs/by-name/metadata of=/data/media/0/backupmetadata.img

Write-Host "Pulling files..."
$backupFolder = "$PSScriptRoot\backups"
$dateString = Get-Date -Format "yyyyMMdd_HHmmss"
$newName = "data_" + $dateString + ".tar.lz4"
$newMetadataName = "metadata_" + $dateString + ".img"
$newVendorName = "vendor_" + $dateString + ".img"
adb pull /data/media/0/newbackup.tar.lz4 "$backupFolder\data\$newName"
adb pull /data/media/0/backupmetadata.img "$backupFolder\metadata\$newMetadataName"

Write-Host "Cleaning..."
adb shell rm -rf /data/media/0/backupmetadata.img /data/media/0/newbackup.tar /data/media/0/newbackup.tar.lz4

Write-Host "Restoring lock screen..."
adb shell mv /tmp/locksettings.db /data/system/locksettings.db
adb shell mv /tmp/locksettings.db-journal /data/system/locksettings.db-journal

Write-Host "Done!"
adb shell reboot system
Read-Host "Press Enter to exit"
