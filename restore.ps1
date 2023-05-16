Write-Host "I'm assuming now that you're booted into lineage recovery on a fresh install of the stock rom, press enter to begin."
Read-Host "Press Enter to continue"
Write-Host "Preparing..."
adb push .\tools\lz4 /tmp/lz4
adb shell chmod +x /tmp/lz4

# get data files list
$dataFiles = Get-ChildItem -Path $PSScriptRoot\backups\data\ -Filter *.tar.lz4 | Sort-Object LastWriteTime -Descending

# get selected
Write-Host "Choose a data file:"
for ($i=0; $i -lt $dataFiles.Count; $i++) {
    Write-Host "$i. $($dataFiles[$i].Name)  (Last Modified: $($dataFiles[$i].LastWriteTime))"
}
[int]$dataFileIndex = Read-Host "Enter the number of the file you want to use"

# set datafile variable
$datafile = $dataFiles[$dataFileIndex].FullName

# get metadata files list
$metadataFiles = Get-ChildItem -Path $PSScriptRoot\backups\metadata\ -Filter *.img | Sort-Object LastWriteTime -Descending

# get selected
Write-Host "Choose a metadata file:"
for ($i=0; $i -lt $metadataFiles.Count; $i++) {
    Write-Host "$i. $($metadataFiles[$i].Name)  (Last Modified: $($metadataFiles[$i].LastWriteTime))"
}
[int]$metadataFileIndex = Read-Host "Enter the number of the file you want to use"

# set metadatafile variable
$metadatafile = $metadataFiles[$metadataFileIndex].FullName

Write-Host "Mounting data..."
adb shell mount /dev/block/platform/14700000.ufs/by-name/userdata /data
Write-Host "Pushing backup to device..."
adb push $datafile /data/backup.tar.lz4
adb push $metadatafile /data/metadata.img
Write-Host "Decompressing backup..."
adb shell /tmp/lz4 -d /data/backup.tar.lz4 /data/backup.tar
Write-Host "Restoring data..."
adb shell tar xvf /data/backup.tar
Write-Host "Restoring metadata..."
adb shell dd if=/data/metadata.img of=/dev/block/platform/14700000.ufs/by-name/metadata
Write-Host "Cleaning up..."
adb shell rm -rf /data/backup.tar /data/backup.tar.lz4 /data/metadata.img
Write-Host "Done!"
Read-Host "Press Enter to exit"
