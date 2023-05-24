#!/bin/bash

echo "I'm assuming now that you're booted into lineage recovery on a fresh install of your previous rom, please also make sure that you booted into the first time setup of the rom, and then rebooted into recovery before continuing, press enter to begin."
read -p "Press Enter to continue"

echo "Preparing..."
adb push ./tools/lz4 /tmp/lz4
adb shell chmod +x /tmp/lz4

# get data files list
data_files=($(ls -t "$PWD/backups/data/"*.tar.lz4))

# get selected
echo "Choose a data file:"
for ((i=0; i<${#data_files[@]}; i++)); do
    echo "$i. ${data_files[$i]}  (Last Modified: $(stat -c %y ${data_files[$i]}))"
done
read -p "Enter the number of the file you want to use: " data_file_index

# set datafile variable
data_file="${data_files[$data_file_index]}"

# get metadata files list
metadata_files=($(ls -t "$PWD/backups/metadata/"*.img))

# get selected
echo "Choose a metadata file:"
for ((i=0; i<${#metadata_files[@]}; i++)); do
    echo "$i. ${metadata_files[$i]}  (Last Modified: $(stat -c %y ${metadata_files[$i]}))"
done
read -p "Enter the number of the file you want to use: " metadata_file_index

# set metadatafile variable
metadata_file="${metadata_files[$metadata_file_index]}"

echo "Mounting data..."
adb shell mount /dev/block/platform/14700000.ufs/by-name/userdata /data
echo "Pushing backup to device..."
adb push "$data_file" /data/backup.tar.lz4
adb push "$metadata_file" /data/metadata.img
echo "Decompressing backup..."
adb shell /tmp/lz4 -d /data/backup.tar.lz4 /data/backup.tar
echo "Restoring data..."
adb shell "tar xvf /data/backup.tar" > /dev/null 2>&1
echo "Restoring metadata..."
adb shell dd if=/data/metadata.img of=/dev/block/platform/14700000.ufs/by-name/metadata
echo "Cleaning up..."
adb shell rm -rf /data/backup.tar /data/backup.tar.lz4 /data/metadata.img
echo "Done!"
read -p "Press Enter to exit"
