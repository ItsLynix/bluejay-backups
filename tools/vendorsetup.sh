#!/bin/bash

export SLOT="/dev/block/dm-3"

echo "Creating vendor image file..."

dd if=$SLOT of=/tmp/vendor.img

echo "Calculating new vendor image size..."
vendor_size=$(du -sm /tmp/vendor.img | cut -f1)
new_vendor_size_mb=`echo "scale=0; $vendor_size * 1.7 + 10" | /tmp/bc | xargs printf "%.0f\n"`

echo "Checking vendor image for errors..."

/tmp/e2fsck -f /tmp/vendor.img

echo "Resizing vendor image..."

/tmp/resize2fs /tmp/vendor.img ${new_vendor_size_mb}M

echo "Unsharing blocks..."

/tmp/e2fsck -E unshare_blocks /tmp/vendor.img

echo "Mounting vendor image..."

mount -o rw /tmp/vendor.img /tmp/MOUNTPOINT

echo "Editing fstab file..."

sed -i 's/inlinecrypt,//g; s/fileencryption=::inlinecrypt_optimized+wrappedkey_v0,//g; s/metadata_encryption=:wrappedkey_v0,//g; s/keydirectory=\/metadata\/vold\/metadata_encryption,//g' /tmp/MOUNTPOINT/etc/fstab.gs101

echo "Unmounting vendor image..."

umount /tmp/MOUNTPOINT

echo "Checking vendor image again..."

/tmp/e2fsck -f -y /tmp/vendor.img

echo "Resizing vendor image again..."

/tmp/resize2fs -M /tmp/vendor.img

echo "Done!"

