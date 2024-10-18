#!/bin/bash

if [[ $# -ne 2 ]]; then
  echo "invalid parameters"
  echo "(ex) ./nvmeconfig.h /dev/nvme0 cns"
  exit 1
fi

DEV=$1
TYPE=$2

echo $DEV
echo $TYPE

NS_CNT=`nvme list | grep nvme0 | wc -l`

sudo umount $DEV'n1'
sudo umount $DEV'n2'

sudo nvme delete-ns $DEV -n 1
sudo nvme delete-ns $DEV -n 2
if [ $NS_CNT -gt 1 ]; then
  sudo nvme delete-ns $DEV -n 2
fi

sudo nvme set-feature $DEV -f 0x1d -c 1 -s
sudo nvme set-feature $DEV -f 0x1d -c 0 -s

if [ $TYPE == 'fdp' ]; then
  sudo nvme set-feature $DEV -f 0x1d -c 1 -s
fi


if [ $TYPE == 'cns' ]; then
  # 100%
  #sudo nvme create-ns $DEV -s 917100000 -c 917100000 -f 0
  # 50%
  #sudo nvme create-ns $DEV -s 458550000 -c 458550000 -f 0 
  #sudo nvme create-ns $DEV -s 458550000 -c 458550000 -f 0 
  # 25%
  sudo nvme create-ns $DEV -s 183420000 -c 183420000 -f 0 
  sudo nvme create-ns $DEV -s 733680000 -c 733680000 -f 0 
elif [ $TYPE == 'fdp' ]; then
  # 100%
  #sudo nvme create-ns $DEV -s 917100000 -c 917100000 -f 0 -e 1 -n 7 -p 1,2,3,4,5,6,7 
  # 25%
  sudo nvme create-ns $DEV -s 183420000 -c 183420000 -f 0 -e 1 -n 7 -p 1,2,3,4,5,6,7 
  sudo nvme create-ns $DEV -s 733680000 -c 733680000 -f 0 
  # 37%
  #sudo nvme create-ns $DEV -s 244560000 -c 244560000 -f 0 -e 1 -n 7 -p 1,2,3,4,5,6,7 
  #sudo nvme create-ns $DEV -s 672540000 -c 672540000 -f 0 
fi
  
sudo nvme attach-ns $DEV -n 1 -c 7
sudo nvme attach-ns $DEV -n 2 -c 7

sleep 1

sudo nvme list | grep $DEV
sudo nvme get-feature $DEV -f 0x1d -H

echo complete nvme configure [$TYPE]
