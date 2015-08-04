#!/bin/bash
# base_installer.sh

POOL_NAME=rpool

WELCOME_TEXT=`cat <<EOF
Welcome to Zed Base Installer!

In the following file browser please select the hard
drive to install the system too.
EOF
`

echo -n "$WELCOME_TEXT" | zenity --title "WELCOME" --text-info --width=500 --height=400

cd /dev/disk/by-id

HARDDRIVE_PATH=$(zenity --file-selection)

echo $HARDDRIVE_PATH



# Install Needed ZFS tools
apt-add-repository --yes ppa:zfs-native/stable
apt-get update
apt-get install --yes debootstrap ubuntu-zfs


# Format HD
#Prompt would be nice
# Add swap/boot/ and root
echo "Formating HD"
(echo g; echo n; echo 1; echo; echo +2G; echo n; echo 2; echo; echo +256M; echo n; echo 3; echo; echo; echo t; echo 1; echo 14; echo t; echo 2; echo 4; echo p; echo w) | fdisk $HARDDRIVE_PATH

echo
echo "time format"

mkswap -L swap ${HARDDRIVE_PATH}-part1
mkfs.ext3 ${HARDDRIVE_PATH}-part2

echo
echo

#Label disks

zpool create -d -o feature@async_destroy=enabled -o feature@empty_bpobj=enabled -o feature@lz4_compress=enabled -o ashift=12 -O compression=lz4 $POOL_NAME ${HARDDRIVE_PATH}-part3
# zpool export rpool

zfs create ${POOL_NAME}/ROOT
zfs create ${POOL_NAME}/ROOT/zed-1

zfs umount -a

zfs set mountpoint=/ ${POOL_NAME}/ROOT/zed-1
zpool set bootfs=${POOL_NAME}/ROOT/zed-1 $POOL_NAM export $POOL_NAME
	
zpool export $POOL_NAME

zpool import -d /dev/disk/by-id -R /mnt $POOL_NAME

mkdir -p /mnt/boot/grub
mount ${HARDDRIVE_PATH}-part2 /mnt/boot/grub

debootstrap trusty /mnt

cp /etc/hostname /mnt/etc/
cp /etc/hosts /mnt/etc/

echo "${HARDDRIVE_PATH}-part1  /boot/grub  auto  defaults  0  1" >> /mnt/etc/fstab


mount --bind /dev  /mnt/dev
mount --bind /proc /mnt/proc
mount --bind /sys  /mnt/sys

#cat /etc/modprobe.d/zfs-arc-max.conf 
#options zfs zfs_arc_max=1073741824

#chroot /mnt /bin/bash --login




