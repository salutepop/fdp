
MKFS_XFS_SH="/home/cm/dev/fdp/util/mount_xfs.sh"
BENCH_SH="/home/cm/dev/fdp/dbbench/benchmark.sh"

DEV=$1
DEVICE="/dev/"$DEV
DIR_MOUNT="/home/cm/mnt/"
HOME="/home/cm/dev/"
DB_BENCH=$HOME'repo/RocksDB/db_bench'
DIR_RESULT=$HOME'fdp/dbbench/result/'

if [[ $# -lt 1 ]]; then
  echo "Illegal number of parameters"
  echo "(ex) ./run.sh nvme0n1"
  exit
fi

# 0. mkfs & mount
$MKFS_XFS_SH $DEV $DIR_MOUNT
rm /tmp/benchmark_*

# 1. copy db_bench
cp $DB_BENCH .

# 2. run benchmark.sh

NUM_KEYS=300000000 # 300M
CACHE_SIZE=2000000000 # 2GB

BENCH_TYPE='bulkload'
COMMENT='_test'
DURATION=0 # bulkload has no duration
MB_WRITE_PER_SEC=0
RESULT=$DIR_RESULT$BENCH_TYPE$COMMENT
mkdir -p $RESULT
$BENCH_SH $BENCH_TYPE $DIR_MOUNT $NUM_KEYS $CACHE_SIZE $DURATION $MB_WRITE_PER_SEC $RESULT

BENCH_TYPE='readrandom'
COMMENT='_test'
DURATION=600 # bulkload has no duration
MB_WRITE_PER_SEC=0
RESULT=$DIR_RESULT$BENCH_TYPE$COMMENT
mkdir -p $RESULT
$BENCH_SH $BENCH_TYPE $DIR_MOUNT $NUM_KEYS $CACHE_SIZE $DURATION $MB_WRITE_PER_SEC $RESULT

BENCH_TYPE='readwhilewriting'
COMMENT='_2mb'
DURATION=600 # bulkload has no duration
MB_WRITE_PER_SEC=2
RESULT=$DIR_RESULT$BENCH_TYPE$COMMENT
mkdir -p $RESULT
$BENCH_SH $BENCH_TYPE $DIR_MOUNT $NUM_KEYS $CACHE_SIZE $DURATION $MB_WRITE_PER_SEC $RESULT
