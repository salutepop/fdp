DEV=$1
MOUNT="/home/cm/tmp/"
HOME="/home/cm/"
DB_BENCH=$HOME'/repo/rocksdb/db_bench'
DIR_RESULT=$HOME'/fdp/dbbench/result/'

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
  -benchmarks="fillrandom,levelstats" \
  -db=$MOUNT \
  -num=200000000 \
  -value_size=1000 \
  -key_size=16 \
  -delayed_write_rate=536870912 \
  -report_interval_seconds=1 \
  -max_write_buffer_number=4 \
  -num_column_families=1 \
  -histogram \
  -max_background_compactions=8 \
  -cache_size=8388608 \
  -max_background_flushes=4 \
  -bloom_bits=10 \
  -benchmark_read_rate_limit=0 \
  -benchmark_write_rate_limit=0 \
  -report_file=$DIR_RESULT'fillrandom.csv' \
  -disable_wal=true \
  -write_buffer_size=268435456
#$DB_BENCH \
#  -benchmarks="fillrandom" \
#  -db=$MOUNT \
#  -use_direct_io_for_flush_and_compaction=true \
#  -use_direct_reads=true \
#  -compaction_style=0 \
#  -duration=120 \
#  -statistics \
#  -stats_interval_seconds=10 2>&1 
#  -target_file_size_base=2097152 \
#  -write_buffer_size=2097152 \
#  -max_bytes_for_level_base=33554432 \
#  -max_bytes_for_level_multiplier=3 \
