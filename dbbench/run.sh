DEV=$1
MOUNT="/home/cm/tmp/"
HOME="/home/cm/repo/"
DB_BENCH=$HOME'rocksdb/db_bench'

if [[ $# -ne 1 ]]; then
  echo "Illegal number of parameters"
  echo "(ex) ./run.sh nvme0n1"
  exit
fi
# 0. mkfs & mount
sudo umount $MOUNT
sudo mkfs.xfs -f /dev/$1
rm -r $MOUNT
mkdir $MOUNT
sudo mount /dev/$1 $MOUNT
sudo chown -R cm $MOUNT

MOUNTED=`df -h | grep $DEV | wc -l`
if [[ $MOUNTED -ne 1 ]]; then
  echo "not mounted path : $MOUNTED"
  exit
fi

# 1. execute db_bench
$DB_BENCH \
  -benchmarks="fillrandom" \
  -db=$MOUNT \
  -use_direct_io_for_flush_and_compaction=true \
  -use_direct_reads=true \
  -compaction_style=0 \
  -target_file_size_base=2097152 \
  -write_buffer_size=2097152 \
  -max_bytes_for_level_base=33554432 \
  -max_bytes_for_level_multiplier=3 \
  -duration=60 \
#  -statistics \
  -stats_dump_period_sec=10 \
  -stats_interval_seconds=10 2>&1 
