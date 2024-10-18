#(usage) ./fill.sh /dev/nvme0n2 /home/cm/cns_fill
if [[ $# -ne 2 ]]; then
  echo "invalid parameters"
  echo "(ex) ./fill.sh /dev/nvme0n2 /home/cm/cns_fill"
  #echo "(ex) ./fill.sh /dev/nvme0n2"
  exit 1
fi

DEV=$1
MOUNT=$2

sudo umount $DEV
sudo rm -r $MOUNT
mkdir $MOUNT

sudo mkfs.xfs $DEV -f
sudo mount $DEV $MOUNT

    #--filename=dummyfile \
    #--size=100% \
    #--filesize=650G \ #37%
sudo fio --name=fill_device \
    --directory=$MOUNT \
    --filesize=750G \
    --bs=1M \
    --rw=write \
    --direct=1 \
    --ioengine=io_uring \
    --numjobs=4 \
    --iodepth=32 \
    --fsync=1
df -h
echo Completed
