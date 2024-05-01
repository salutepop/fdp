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

nvme delete-ns $DEV -n 1
if [ $NS_CNT -gt 1 ]; then
  nvme delete-ns $DEV -n 2
fi

nvme set-feature $DEV -f 0x1d -c 1 -s
nvme set-feature $DEV -f 0x1d -c 0 -s

if [ $TYPE == 'fdp' ]; then
  nvme set-feature $DEV -f 0x1d -c 1 -s
fi


if [ $TYPE == 'cns' ]; then
  nvme create-ns $DEV -s 0x36b9d996 -c 0x36b9d996 -f 0
elif [ $TYPE == 'fdp' ]; then
  nvme create-ns $DEV -s 917100000 -c 917100000 -f 0 -e 1 -n 7 -p 1,2,3,4,5,6,7 
fi
  
sudo nvme attach-ns $DEV -n 1 -c 7

sleep 1

nvme list | grep $DEV
nvme get-feature $DEV -f 0x1d -H

echo complete nvme configure [$TYPE]
