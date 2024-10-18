
HOME="/home/cm/dev/"
DB_BENCH=$HOME'repo/RocksDB/db_bench'
DIR_RESULT=$HOME"fdp/dbbench/result/"
AUX_PATH="/home/cm/tmp/"
TRIM_SH="/home/cm/dev/fdp/util/trim.sh"
XFSMOUNT_SH="/home/cm/dev/fdp/util/mount_xfs.sh"
FLEXFS="/home/cm/dev/repo/RocksDB/plugin/flexfs/util/flexfs"


# CONFIGURATION
BENCH_TYPE="overwrite"
#BENCH_TYPE="readwhilewriting"
#BENCH_TYPE="readrandom"
#BENCH_TYPE="readseq"
#BENCH_TYPE="fillseq"
#BENCH_TYPE="readrandom"
NUMS="100000000" # 300M 
#NUMS="100000000" # 100M
#NUMS="30000000" # 10M
#NUMS="0"
#COMMENT="_RAN100M"
COMMENT="_100M"
THREADS=16
# 3B key_size=20 value_size=800
OPTIONS=" --use_existing_db --key_size=20 --value_size=800 --use_direct_io_for_flush_and_compaction --use_direct_reads --async_io --histogram" #  --statistics"
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
test_cns_fillrandom(){
    BENCH_TYPE="fillrandom"
    #NUMS="500000000" # 500M
    NUMS="1000000000" # 1B
    COMMENT="_0915_DIRTY_1B"
    THREADS=1
    OPTIONS=" --stats_dump_period_sec=60 --key_size=20 --value_size=800 --use_direct_io_for_flush_and_compaction --use_direct_reads --async_io --histogram" #  --statistics"

    # BEGIN TEST #
    DEV_NAME="nvme0n1"
    echo "DO TEST" $BENCH_TYPE $COMMENT $NUMS $DEV_NAME
    sudo nvme smart-log /dev/${DEV_NAME:0:5}
    sudo nvme ocp smart-add-log /dev/${DEV_NAME:0:5}
    $XFSMOUNT_SH $DEV_NAME $AUX_PATH
    
    sudo ./db_bench --db=$AUX_PATH --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS
    RESULT=$DIR_RESULT$BENCH_TYPE$COMMENT'_CNS'
    mkdir -p $RESULT
    cp $AUX_PATH/LOG $RESULT/
    # END TEST #
    sleep 600
    sudo nvme smart-log /dev/${DEV_NAME:0:5}
    sudo nvme ocp smart-add-log /dev/${DEV_NAME:0:5}
}

test_cns_overwrite(){
    BENCH_TYPE="overwrite"
    NUMS="1000000000" # 1B
    COMMENT="_0915_DIRTY_1B_"$1
    THREADS=1
    OPTIONS=" --stats_dump_period_sec=60 --use_existing_db --key_size=20 --value_size=800 --use_direct_io_for_flush_and_compaction --use_direct_reads --async_io --histogram" #  --statistics"

    # BEGIN TEST #
    DEV_NAME="nvme0n1"
    echo "DO TEST" $BENCH_TYPE $COMMENT $NUMS $DEV_NAME
    sudo nvme smart-log /dev/${DEV_NAME:0:5}
    sudo nvme ocp smart-add-log /dev/${DEV_NAME:0:5}
    
    sudo ./db_bench --db=$AUX_PATH --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS
    RESULT=$DIR_RESULT$BENCH_TYPE$COMMENT'_CNS'
    mkdir -p $RESULT
    cp $AUX_PATH/LOG $RESULT/
    # END TEST #
    sleep 600
    sudo nvme smart-log /dev/${DEV_NAME:0:5}
    sudo nvme ocp smart-add-log /dev/${DEV_NAME:0:5}
}

test_cns_readwhilewriting(){
    BENCH_TYPE="readwhilewriting"
    NUMS="300000000" # 300M 
    COMMENT="_0915_DIRTY_1B_"$1
    THREADS=16
    OPTIONS=" --stats_dump_period_sec=60 --use_existing_db --duration=3600 --key_size=20 --value_size=800 --use_direct_io_for_flush_and_compaction --use_direct_reads --async_io --histogram" #  --statistics"

    # BEGIN TEST #
    DEV_NAME="nvme0n1"
    echo "DO TEST" $BENCH_TYPE $COMMENT $NUMS $DEV_NAME
    sudo nvme smart-log /dev/${DEV_NAME:0:5}
    sudo nvme ocp smart-add-log /dev/${DEV_NAME:0:5}
    
    sudo ./db_bench --db=$AUX_PATH --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS
    RESULT=$DIR_RESULT$BENCH_TYPE$COMMENT'_CNS'
    mkdir -p $RESULT
    cp $AUX_PATH/LOG $RESULT/

    # END TEST #
    sleep 600
    sudo nvme smart-log /dev/${DEV_NAME:0:5}
    sudo nvme ocp smart-add-log /dev/${DEV_NAME:0:5}
}

test_cns_readrandomwriterandom(){
    BENCH_TYPE="readrandomwriterandom"
    NUMS="300000000" # 300M 
    COMMENT="_0915_DIRTY_1B_"$1
    THREADS=16
    OPTIONS=" --stats_dump_period_sec=60 --use_existing_db --readwritepercent=50 --duration=3600 --key_size=20 --value_size=800 --use_direct_io_for_flush_and_compaction --use_direct_reads --async_io --histogram" #  --statistics"

    # BEGIN TEST #
    DEV_NAME="nvme0n1"
    echo "DO TEST" $BENCH_TYPE $COMMENT $NUMS $DEV_NAME
    sudo nvme smart-log /dev/${DEV_NAME:0:5}
    sudo nvme ocp smart-add-log /dev/${DEV_NAME:0:5}
    
    sudo ./db_bench --db=$AUX_PATH --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS
    RESULT=$DIR_RESULT$BENCH_TYPE$COMMENT'_CNS'
    mkdir -p $RESULT
    cp $AUX_PATH/LOG $RESULT/

    # END TEST #
    sleep 600
    sudo nvme smart-log /dev/${DEV_NAME:0:5}
    sudo nvme ocp smart-add-log /dev/${DEV_NAME:0:5}
}

test_fdp_fillrandom(){
    echo "DO TEST FDP"
    cat /proc/uptime
    BENCH_TYPE="fillrandom"
    NUMS="1000000000" # 1B
    #NUMS="500000000" # 500M
    COMMENT="_DIRTY_1B"
    THREADS=1
    OPTIONS=" --stats_dump_period_sec=60 --key_size=20 --value_size=800 --use_direct_io_for_flush_and_compaction --use_direct_reads --async_io --histogram" #  --statistics"

    # BEGIN TEST #
    DEV_TYPE="//fdp:"
    DEV_NAME="nvme0n1"
    sudo nvme smart-log /dev/${DEV_NAME:0:5}
    sudo nvme ocp smart-add-log /dev/${DEV_NAME:0:5}
    $TRIM_SH $DEV_NAME
    sudo rm -r $AUX_PATH/*
    sudo $FLEXFS mkfs --fdp_bd=$DEV_NAME --aux_path=$AUX_PATH --force --finish_threshold=10 --enable_gc
    
    sudo ./db_bench --fs_uri=zenfs:$DEV_TYPE$DEV_NAME --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS
    #echo ./db_bench --fs_uri=zenfs:$DEV_TYPE$DEV_NAME --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS
    RESULT=$DIR_RESULT$BENCH_TYPE$COMMENT'_FDP'
    mkdir -p $RESULT
    cp $AUX_PATH/rocksdbtest/dbbench/LOG $RESULT/

    # END TEST #
    sleep 600
    sudo nvme smart-log /dev/${DEV_NAME:0:5}
    sudo nvme ocp smart-add-log /dev/${DEV_NAME:0:5}

    cat /proc/uptime
}
    
test_fdp_overwrite(){
    echo "DO TEST FDP"
    cat /proc/uptime
    BENCH_TYPE="overwrite"
    NUMS="1000000000" # 1B
    #NUMS="500000000" # 500M
    COMMENT="_DIRTY_1B_"$1
    THREADS=1
    OPTIONS=" --stats_dump_period_sec=60 --use_existing_db --key_size=20 --value_size=800 --use_direct_io_for_flush_and_compaction --use_direct_reads --async_io --histogram" #  --statistics"

    # BEGIN TEST #
    DEV_TYPE="//fdp:"
    DEV_NAME="nvme0n1"
    sudo nvme smart-log /dev/${DEV_NAME:0:5}
    sudo nvme ocp smart-add-log /dev/${DEV_NAME:0:5}
    #$TRIM_SH $DEV_NAME
    #sudo rm -r $AUX_PATH/*
    #sudo $FLEXFS mkfs --fdp_bd=$DEV_NAME --aux_path=$AUX_PATH --force --finish_threshold=10 --enable_gc
    
    sudo ./db_bench --fs_uri=zenfs:$DEV_TYPE$DEV_NAME --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS
    #echo ./db_bench --fs_uri=zenfs:$DEV_TYPE$DEV_NAME --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS
    RESULT=$DIR_RESULT$BENCH_TYPE$COMMENT'_FDP'
    mkdir -p $RESULT
    cp $AUX_PATH/rocksdbtest/dbbench/LOG $RESULT/

    # END TEST #
    sleep 600
    sudo nvme smart-log /dev/${DEV_NAME:0:5}
    sudo nvme ocp smart-add-log /dev/${DEV_NAME:0:5}
    cat /proc/uptime
}
    
test_fdp_readwhilewriting(){
    echo "DO TEST FDP"
    BENCH_TYPE="readwhilewriting"
    NUMS="1000000000" # 1B
    #NUMS="500000000" # 500M
    COMMENT="_DIRTY_1B_"$1
    THREADS=16
    OPTIONS=" --stats_dump_period_sec=60 --use_existing_db --duration=3600 --key_size=20 --value_size=800 --use_direct_io_for_flush_and_compaction --use_direct_reads --async_io --histogram" #  --statistics"

    # BEGIN TEST #
    DEV_TYPE="//fdp:"
    DEV_NAME="nvme0n1"
    sudo nvme smart-log /dev/${DEV_NAME:0:5}
    sudo nvme ocp smart-add-log /dev/${DEV_NAME:0:5}
    
    sudo ./db_bench --fs_uri=zenfs:$DEV_TYPE$DEV_NAME --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS
    #echo ./db_bench --fs_uri=zenfs:$DEV_TYPE$DEV_NAME --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS
    RESULT=$DIR_RESULT$BENCH_TYPE$COMMENT'_FDP'
    mkdir -p $RESULT
    cp $AUX_PATH/rocksdbtest/dbbench/LOG $RESULT/

    # END TEST #
    sleep 600
    sudo nvme smart-log /dev/${DEV_NAME:0:5}
    sudo nvme ocp smart-add-log /dev/${DEV_NAME:0:5}
}
    
test_fdp_readrandomwriterandom(){
    echo "DO TEST FDP"
    BENCH_TYPE="readrandomwriterandom"
    NUMS="1000000000" # 1B
    #NUMS="500000000" # 500M
    COMMENT="_DIRTY_1B_"$1
    THREADS=16
    OPTIONS=" --stats_dump_period_sec=60 --use_existing_db --readwritepercent=50 --duration=3600 --key_size=20 --value_size=800 --use_direct_io_for_flush_and_compaction --use_direct_reads --async_io --histogram" #  --statistics"

    # BEGIN TEST #
    DEV_TYPE="//fdp:"
    DEV_NAME="nvme0n1"
    sudo nvme smart-log /dev/${DEV_NAME:0:5}
    sudo nvme ocp smart-add-log /dev/${DEV_NAME:0:5}
    
    sudo ./db_bench --fs_uri=zenfs:$DEV_TYPE$DEV_NAME --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS
    #echo ./db_bench --fs_uri=zenfs:$DEV_TYPE$DEV_NAME --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS
    RESULT=$DIR_RESULT$BENCH_TYPE$COMMENT'_FDP'
    mkdir -p $RESULT
    cp $AUX_PATH/rocksdbtest/dbbench/LOG $RESULT/

    # END TEST #
    sleep 600
    sudo nvme smart-log /dev/${DEV_NAME:0:5}
    sudo nvme ocp smart-add-log /dev/${DEV_NAME:0:5}
}
    
test_zns_fillrandom(){
    echo "DO TEST ZNS"
    BENCH_TYPE="fillrandom"
    NUMS="1000000000" # 1B
    #NUMS="500000000" # 500M
    COMMENT="_DIRTY_1B_"
    THREADS=1
    OPTIONS=" --stats_dump_period_sec=60 --key_size=20 --value_size=800 --use_direct_io_for_flush_and_compaction --use_direct_reads --async_io --histogram" #  --statistics"

    # BEGIN TEST #
    DEV_TYPE="//dev:"
    DEV_NAME="nvme2n2"
    sudo nvme smart-log /dev/nvme2n2
    #sudo nvme ocp smart-add-log /dev/nvme0
    $TRIM_SH $DEV_NAME
    sudo rm -r $AUX_PATH/*
    sudo $FLEXFS mkfs --zbd=$DEV_NAME --aux_path=$AUX_PATH --force --finish_threshold=10 --enable_gc
    
    sudo ./db_bench --fs_uri=zenfs:$DEV_TYPE$DEV_NAME --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS
    RESULT=$DIR_RESULT$BENCH_TYPE$COMMENT'_ZNS'
    mkdir -p $RESULT
    cp $AUX_PATH/rocksdbtest/dbbench/LOG $RESULT/
    # END TEST #
    sleep 600
    sudo nvme smart-log /dev/nvme2n2
    #sudo nvme ocp smart-add-log /dev/nvme0
}

test_zns_overwrite(){
    echo "DO TEST ZNS"
    BENCH_TYPE="overwrite"
    NUMS="1000000000" # 1B
    COMMENT="_DIRTY_1B_"$1
    #NUMS="500000000" # 500M
    #COMMENT="_500M_1T"
    THREADS=1
    OPTIONS=" --stats_dump_period_sec=60 --use_existing_db --key_size=20 --value_size=800 --use_direct_io_for_flush_and_compaction --use_direct_reads --async_io --histogram" #  --statistics"

    # BEGIN TEST #
    DEV_TYPE="//dev:"
    DEV_NAME="nvme2n2"
    sudo nvme smart-log /dev/nvme2n2
    #sudo nvme ocp smart-add-log /dev/nvme0
    
    sudo ./db_bench --fs_uri=zenfs:$DEV_TYPE$DEV_NAME --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS
    #echo ./db_bench --fs_uri=zenfs:$DEV_TYPE$DEV_NAME --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS
    RESULT=$DIR_RESULT$BENCH_TYPE$COMMENT'_ZNS'
    mkdir -p $RESULT
    cp $AUX_PATH/rocksdbtest/dbbench/LOG $RESULT/
    # END TEST #
    sleep 600
    sudo nvme smart-log /dev/nvme2n2
    #sudo nvme ocp smart-add-log /dev/nvme0
}

test_zns_readwhilewriting(){
    echo "DO TEST ZNS"
    BENCH_TYPE="readwhilewriting"
    NUMS="300000000" # 300M 
    COMMENT="_DIRTY_1B_"$1
    THREADS=16
    OPTIONS=" --stats_dump_period_sec=60 --use_existing_db --duration=3600 --key_size=20 --value_size=800 --use_direct_io_for_flush_and_compaction --use_direct_reads --async_io --histogram" #  --statistics"

    # BEGIN TEST #
    DEV_TYPE="//dev:"
    DEV_NAME="nvme2n2"
    sudo nvme smart-log /dev/nvme2n2
    #sudo nvme ocp smart-add-log /dev/nvme0
    
    sudo ./db_bench --fs_uri=zenfs:$DEV_TYPE$DEV_NAME --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS
    #echo ./db_bench --fs_uri=zenfs:$DEV_TYPE$DEV_NAME --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS
    RESULT=$DIR_RESULT$BENCH_TYPE$COMMENT'_ZNS'
    mkdir -p $RESULT
    cp $AUX_PATH/rocksdbtest/dbbench/LOG $RESULT/
    # END TEST #
    sleep 600
    sudo nvme smart-log /dev/nvme2n2
    #sudo nvme ocp smart-add-log /dev/nvme0
}

test_zns_readrandomwriterandom(){
    BENCH_TYPE="readrandomwriterandom"
    NUMS="300000000" # 300M 
    COMMENT="_DIRTY_1B_"$1
    THREADS=16
    OPTIONS=" --stats_dump_period_sec=60 --use_existing_db --readwritepercent=50 --duration=3600 --key_size=20 --value_size=800 --use_direct_io_for_flush_and_compaction --use_direct_reads --async_io --histogram" #  --statistics"

    # BEGIN TEST #
    DEV_TYPE="//dev:"
    DEV_NAME="nvme2n2"
    sudo nvme smart-log /dev/nvme2n2
    #sudo nvme ocp smart-add-log /dev/nvme0
    
    sudo ./db_bench --fs_uri=zenfs:$DEV_TYPE$DEV_NAME --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS
    #echo ./db_bench --fs_uri=zenfs:$DEV_TYPE$DEV_NAME --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS
    RESULT=$DIR_RESULT$BENCH_TYPE$COMMENT'_ZNS'
    mkdir -p $RESULT
    cp $AUX_PATH/rocksdbtest/dbbench/LOG $RESULT/
    # END TEST #
    sleep 600
    sudo nvme smart-log /dev/nvme2n2
    #sudo nvme ocp smart-add-log /dev/nvme0
}

test_cns(){
    echo "DO TEST CNS"
    # BEGIN TEST #
    DEV_NAME="nvme0n1"
    sudo nvme smart-log /dev/${DEV_NAME:0:5}
    sudo nvme ocp smart-add-log /dev/${DEV_NAME:0:5}
    $XFSMOUNT_SH $DEV_NAME $AUX_PATH
    
    sudo ./db_bench --db=$AUX_PATH --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS
    #echo ./db_bench --fs_uri=zenfs:$DEV_TYPE$DEV_NAME --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS
    RESULT=$DIR_RESULT$BENCH_TYPE$COMMENT'_CNS'
    mkdir -p $RESULT
    cp $AUX_PATH/LOG $RESULT/
    # END TEST #
    sleep 600
    sudo nvme smart-log /dev/${DEV_NAME:0:5}
    sudo nvme ocp smart-add-log /dev/${DEV_NAME:0:5}
}
    
test_fdp(){
    echo "DO TEST FDP"
    # BEGIN TEST #
    DEV_TYPE="//fdp:"
    DEV_NAME="nvme0n1"
    sudo nvme smart-log /dev/$DEV_NAME
    $TRIM_SH $DEV_NAME
    sudo rm -r $AUX_PATH/*
    sudo $FLEXFS mkfs --fdp_bd=$DEV_NAME --aux_path=$AUX_PATH --force --finish_threshold=10
    
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

test_fdp_mkfs_trim(){
    echo "DO TEST FDP"
    DEV_TYPE="//fdp:"
    DEV_NAME="nvme0n1"
    $TRIM_SH $DEV_NAME
    sudo rm -r $AUX_PATH/*
    sudo $FLEXFS mkfs --fdp_bd=$DEV_NAME --aux_path=$AUX_PATH --force --finish_threshold=10 --enable_gc
    
    sleep 600
    sudo nvme smart-log /dev/${DEV_NAME:0:5}
    sudo nvme ocp smart-add-log /dev/${DEV_NAME:0:5}
}
    
main(){
    #/home/cm/dev/fdp/util/fill.sh /dev/nvme0n2 /home/cm/cns_fill
    cp $DB_BENCH .
    #sleep 600
    #sleep 1800
# CNS fillrandom 500M -> overwrite 1B -> readwhilewriting 16T 1hr -> rr 50% rw 50% 16T 1hr
# fillrandom 1B -> overwrite 1B -> readwhilewriting 16T 3hr -> rr 50% rw 50% 16T 3hr
    #test_cns_fillrandom
    #test_cns_overwrite '1'
    #test_cns_overwrite '2'
    #test_cns_overwrite '3'
    #test_cns_overwrite '4'
    #test_cns_readwhilewriting '1hr'
    #test_cns_readwhilewriting '2hr'
    #test_cns_readwhilewriting '3hr'
    #test_cns_readrandomwriterandom '1hr'
    #test_cns_readrandomwriterandom '2hr'
    #test_cns_readrandomwriterandom '3hr'
# FDP
    test_fdp_mkfs_trim
    test_fdp_fillrandom
    test_fdp_overwrite '1'
    test_fdp_overwrite '2'
    test_fdp_overwrite '3'
    test_fdp_readwhilewriting '1hr'
    #test_fdp_readwhilewriting '2hr'
    #test_fdp_readwhilewriting '3hr'
    test_fdp_readrandomwriterandom '1hr'
    #test_fdp_readrandomwriterandom '2hr'
    #test_fdp_readrandomwriterandom '3hr'
# ZNS fillrandom 1B --> 이후 고민
    #test_zns_fillrandom
    #test_zns_overwrite '1'
    #test_zns_overwrite '2'
    #test_zns_readwhilewriting '1hr'
    #test_zns_readwhilewriting '2hr'
    #test_zns_readwhilewriting '3hr'
    #test_zns_readrandomwriterandom '1hr'
    #test_zns_readrandomwriterandom '2hr'
    #test_zns_readrandomwriterandom '3hr'
    #
    #test_cns
    #test_fdp
    #test_zns

}

main
