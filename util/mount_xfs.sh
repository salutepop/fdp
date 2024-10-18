#!/bin/bash

if [[ $# -lt 2 ]]; then
  echo "Illegal number of parameters"
  echo "(ex) ./mount_xfs.sh nvme0n1 /home/cm/mounted_dir"
  exit
fi

DEV=$1
MOUNT=$2

DEVICE="/dev/"$DEV

# 0. mkfs & mount
sudo fuser -ck $DEVICE
sudo umount $DEVICE
sudo fio --name=trim --filename=$DEVICE --rw=trim --bs=3G
sudo mkfs.xfs -f $DEVICE
sudo rm -r $MOUNT
mkdir $MOUNT
sudo mount $DEVICE $MOUNT
sudo chown -R cm $MOUNT

MOUNTED=`df -h | grep $DEV | wc -l`
if [[ $MOUNTED -ne 1 ]]; then
  echo "not mounted path : $MOUNTED"
  exit
else
  df -h | grep $DEV
fi
