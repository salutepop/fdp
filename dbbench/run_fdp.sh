
HOME="/home/cm/dev/"
DB_BENCH=$HOME'repo/RocksDB/db_bench'
DIR_RESULT=$HOME"fdp/dbbench/result/"
AUX_PATH="/home/cm/tmp/"
TRIM_SH="/home/cm/dev/fdp/util/trim.sh"
XFSMOUNT_SH="/home/cm/dev/fdp/util/mount_xfs.sh"
FLEXFS="/home/cm/dev/repo/RocksDB/plugin/flexfs/util/flexfs"


# CONFIGURATION
BENCH_TYPE="fillrandom"
#BENCH_TYPE="readwhilewriting"
#BENCH_TYPE="readrandom"
#BENCH_TYPE="readseq"
#BENCH_TYPE="fillseq"
#BENCH_TYPE="readrandom"
NUMS="300000000" # 300M 
#NUMS="100000000" # 100M
#NUMS="30000000" # 10M
#NUMS="0"
#COMMENT="_RAN100M"
COMMENT="_300M"
THREADS=16
# 3B key_size=20 value_size=800
OPTIONS=" --key_size=20 --value_size=800 --use_direct_io_for_flush_and_compaction --use_direct_reads --async_io --histogram" #  --statistics"
# 240902 WAL_CNS OPTIONS=" --use_direct_io_for_flush_and_compaction --use_direct_reads --async_io --histogram" #  --statistics"
#OPTIONS=" --use_existing_db --use_direct_io_for_flush_and_compaction --use_direct_reads --compaction_readahead_size=262144 --readahead_size=262144" # --histogram --statistics" # --statistics
#OPTIONS=" --trace_file=cm_trace --block_cache_trace_file=cm_block_trace --use_direct_io_for_flush_and_compaction --use_direct_reads --compaction_readahead_size=262144 --readahead_size=262144 --histogram --statistics" # --statistics
# 240831_NOWAL OPTIONS=" --disable_wal=true --use_direct_io_for_flush_and_compaction --use_direct_reads --compaction_readahead_size=262144 --readahead_size=262144 --histogram" #  --statistics"
# 240902 WAL_CNS OPTIONS=" --use_direct_io_for_flush_and_compaction --use_direct_reads --async_io --histogram" #  --statistics"
# 240902 WAL_ZNS OPTIONS=" --use_direct_io_for_flush_and_compaction --use_direct_reads --compaction_readahead_size=262144 --readahead_size=262144 --histogram" #  --statistics"
# OPTIONS=" --use_direct_io_for_flush_and_compaction --use_direct_reads --compaction_readahead_size=262144 --readahead_size=262144 --histogram" #  --statistics"
# NOWAL_AUTO OPTIONS=" --disable_wal=true --use_direct_io_for_flush_and_compaction --use_direct_reads --async_io --histogram" #  --statistics"
# RECOVERY_TEST OPTIONS=" --use_existing_db --use_direct_io_for_flush_and_compaction --use_direct_reads --async_io --histogram --statistics" # --statistics
#OPTIONS=" --use_existing_db --use_direct_io_for_flush_and_compaction --use_direct_reads --async_io --histogram --statistics" # --statistics
#OPTIONS=" --use_direct_io_for_flush_and_compaction --async_io=true --histogram --statistics" # --statistics

#use_existing_db
test_cns(){
    echo "DO TEST CNS"
    # BEGIN TEST #
    DEV_NAME="nvme0n1"
    sudo nvme smart-log /dev/$DEV_NAME
    $XFSMOUNT_SH $DEV_NAME $AUX_PATH
    
    sudo ./db_bench --db=$AUX_PATH --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS
    #echo ./db_bench --fs_uri=zenfs:$DEV_TYPE$DEV_NAME --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS
    RESULT=$DIR_RESULT$BENCH_TYPE$COMMENT'_CNS'
    mkdir -p $RESULT
    cp $AUX_PATH/LOG $RESULT/
    # END TEST #
    sleep 600
    sudo nvme smart-log /dev/$DEV_NAME
}
    
test_fdp(){
    echo "DO TEST FDP"
    # BEGIN TEST #
    DEV_TYPE="//fdp:"
    DEV_NAME="nvme0n1"
    sudo nvme smart-log /dev/$DEV_NAME
    $TRIM_SH $DEV_NAME
    sudo rm -r $AUX_PATH/*
    sudo $FLEXFS mkfs --fdp_bd=$DEV_NAME --aux_path=$AUX_PATH --force
    
    sudo ./db_bench --fs_uri=zenfs:$DEV_TYPE$DEV_NAME --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS
    #echo ./db_bench --fs_uri=zenfs:$DEV_TYPE$DEV_NAME --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS
    RESULT=$DIR_RESULT$BENCH_TYPE$COMMENT'_FDP'
    mkdir -p $RESULT
    cp $AUX_PATH/rocksdbtest/dbbench/LOG $RESULT/
    # END TEST #
}
    
test_zns(){
    echo "DO TEST ZNS"
    # BEGIN TEST #
    DEV_TYPE="//dev:"
    DEV_NAME="nvme2n2"
    sudo nvme smart-log /dev/$DEV_NAME
    #$TRIM_SH $DEV_NAME
    sudo rm -r $AUX_PATH/*
    #sudo $FLEXFS mkfs --zbd=$DEV_NAME --aux_path=$AUX_PATH --force
    
    sudo ./db_bench --fs_uri=zenfs:$DEV_TYPE$DEV_NAME --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS
    #echo ./db_bench --fs_uri=zenfs:$DEV_TYPE$DEV_NAME --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS
    RESULT=$DIR_RESULT$BENCH_TYPE$COMMENT'_ZNS'
    mkdir -p $RESULT
    cp $AUX_PATH/rocksdbtest/dbbench/LOG $RESULT/
    # END TEST #
}

main(){
    sleep 600
    cp $DB_BENCH .
    test_cns
    #test_fdp
    #test_zns

}

main
