HOME='/home/cm/dev/'
CACHEBENCH=$HOME'repo/CacheLib/opt/cachelib/bin/cachebench'
PATH_SCRIPTS=$HOME'fdp/util/'
DIR_CONFIG=$HOME'fdp/cachebench/test_configs/ssd_perf/'
DIR_OUTPUT=$HOME'fdp/cachebench/result/'
NODEV_JSON='nodev_config_kvcache.json'

if [[ $# -ne 3 ]]; then
    echo "Illegal number of parameters"
    echo "ex) ./run.sh nvme0n1 cns kvcache_202206"
    echo "[cns fdp]"
    echo "[flat_kvcache_reg  graph_cache_leader  kvcache_202206  kvcache_202401  kvcache_l2_reg  kvcache_l2_wc]"
    exit 1
fi

# X-0. configure
DEV=$1 # nvme0n1
DEV_TYPE=$2 # fdp, cns
BENCH_TYPE=$3 # flat_kvcache_reg  graph_cache_leader  kvcache_202206  kvcache_202401  kvcache_l2_reg  kvcache_l2_wc

DEV_CONFIG=$DIR_CONFIG$BENCH_TYPE'/'$DEV'_'$DEV_TYPE'_config_kvcache.json'
NODEV_CONFIG=$DIR_CONFIG$BENCH_TYPE/$NODEV_JSON
FILE_OUTPUT=$DIR_OUTPUT$DEV'_'$DEV_TYPE'_'$BENCH_TYPE'_test.txt'
SMART_OUTPUT=$DIR_OUTPUT$DEV'_'$DEV_TYPE'_'$BENCH_TYPE'_smart.txt'

# X-1. initialize
sudo rm $FILE_OUTPUT
sudo rm $DEV_CONFIG
sudo rm $SMART_OUTPUT
echo START_TIME : `cat /proc/uptime` >> $SMART_OUTPUT
sudo umount /dev/$DEV
mkdir -p $DIR_OUTPUT

sudo nvme smart-log /dev/$DEV >> $SMART_OUTPUT
sed 's/DEVICE/'$DEV'/g' $NODEV_CONFIG > $DEV_CONFIG
if [ $DEV_TYPE == 'cns' ]; then
    sed -i '/FDP/d' $DEV_CONFIG
    sed -i '/IoUring/d' $DEV_CONFIG
    sed -i '/navyQDepth/d' $DEV_CONFIG
fi

# 0. enable nvme
sudo $PATH_SCRIPTS'nvmeconfig.sh' /dev/${DEV:0:5} $DEV_TYPE

# 1. trim device
sudo fio --name=trim --filename=/dev/$DEV --rw=trim --bs=3G

# 2. execute benchmark
sudo $CACHEBENCH -json_test_config $DEV_CONFIG -progress_stats_file $FILE_OUTPUT --progress 60

# 3. end
echo END_TIME : `cat /proc/uptime` >> $SMART_OUTPUT
sudo nvme smart-log /dev/$DEV >> $SMART_OUTPUT
