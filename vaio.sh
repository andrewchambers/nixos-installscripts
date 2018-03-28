#! /bin/sh

set -e
set -u
set -x

# configure this!
password="abc123"

sgdisk -o -g -n 1::+200M -t 1:ef02 -n 2::+800M -t 2:8300 -n 3:: -t 3:8300 /dev/sda

echo "$password" | cryptsetup luksFormat /dev/sda3
echo "$password" | cryptsetup luksOpen /dev/sda3 enc-pv1

echo "$password" | cryptsetup luksFormat /dev/sdb
echo "$password" | cryptsetup luksOpen /dev/sdb enc-pv2

pvcreate /dev/mapper/enc-pv1
pvcreate /dev/mapper/enc-pv2

vgcreate vg /dev/mapper/enc-pv1 /dev/mapper/enc-pv2
lvcreate -L 12G -n swap vg
lvcreate -l '100%FREE' -n root vg

mkfs.ext4 /dev/sda2
mkfs.btrfs -L root /dev/vg/root
mkswap -L swap /dev/vg/swap

swapon /dev/vg/swap

mount /dev/vg/root /mnt
mkdir /mnt/boot
mount /dev/sda2 /mnt/boot

nixos-generate-config --root /mnt

echo "remember to add LVM devices and btrfs to your nix config!"


