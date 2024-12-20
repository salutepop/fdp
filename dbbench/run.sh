
HOME="/home/cm/dev/"
DB_BENCH=$HOME'repo/RocksDB/db_bench'
DIR_RESULT=$HOME"fdp/dbbench/result/"
AUX_PATH="/home/cm/tmp/"
TRIM_SH="/home/cm/dev/fdp/util/trim.sh"
XFSMOUNT_SH="/home/cm/dev/fdp/util/mount_xfs.sh"
FLEXFS="/home/cm/dev/repo/RocksDB/plugin/flexfs/util/flexfs"


NUM_1M=1000000
NUM_10M=10000000
NUM_100M=100000000
NUM_300M=300000000
NUM_500M=500000000
NUM_700M=700000000
NUM_800M=800000000
NUM_1B=1000000000
NUM_1500M=1500000000
NUM_2B=2000000000
NUM_3B=3000000000

# CONFIGURATION
#COMMON_OPTIONS=" --stats_dump_period_sec=60 --key_size=20 --value_size=800 --use_direct_io_for_flush_and_compaction --use_direct_reads --max_auto_readahead_size=4194304 --auto_readahead_size --histogram" #  --statistics"
#COMMON_OPTIONS=" --disable_wal --stats_dump_period_sec=60 --key_size=20 --value_size=800 --use_direct_io_for_flush_and_compaction --use_direct_reads --histogram" #  --statistics"
COMMON_OPTIONS=" --stats_dump_period_sec=60 --key_size=20 --value_size=800 --use_direct_io_for_flush_and_compaction --use_direct_reads --histogram" #  --statistics"
#COMMON_OPTIONS=" --stats_dump_period_sec=60 --key_size=20 --value_size=800 --histogram" #  --statistics"
#COMMON_OPTIONS=" --stats_dump_period_sec=60 --key_size=20 --value_size=800 --use_direct_io_for_flush_and_compaction --use_direct_reads --auto_readahead_size --max_auto_readahead_size=4194304 --histogram" #  --statistics"
#COMMON_OPTIONS=" --stats_dump_period_sec=60 --key_size=20 --value_size=800 --use_direct_io_for_flush_and_compaction --use_direct_reads --readahead_size=4194304 --histogram" #  --statistics"
#COMMON_OPTIONS=" --stats_dump_period_sec=60 --key_size=20 --value_size=800 --use_direct_io_for_flush_and_compaction --use_direct_reads --histogram" #  --statistics"

test_fdp_mkfs_trim(){
    DEV_NAME=$1
    sudo umount /dev/$DEV_NAME
    $TRIM_SH $DEV_NAME
    sudo rm -r $AUX_PATH/*
    sudo $FLEXFS mkfs --fdp_bd=$DEV_NAME --aux_path=$AUX_PATH --force --finish_threshold=10 --enable_gc
}
    
test_cns(){
    DEV_NAME=$1
    BENCH_TYPE=$2
    NUMS=$3
    THREADS=$4
    CLEANING=$5
    GET_LOG=$6
    if [ $# -eq 7 ]; then
        OPTIONS="$COMMON_OPTIONS"
        COMMENT=$7
    else
        OPTIONS="$COMMON_OPTIONS $7"
        COMMENT=$8
    fi

    # BEGIN TEST #
    echo "[RUN-CNS] [TIME `(cat /proc/uptime)`]" `date +"%m-%d %H:%M:%S"` $BENCH_TYPE $COMMENT $NUMS $DEV_NAME
    echo 3 | sudo tee /proc/sys/vm/drop_caches
    if [ $CLEANING -eq 1 ]; then
        $XFSMOUNT_SH $DEV_NAME $AUX_PATH
        if [ $GET_LOG -eq 1 ]; then
            sleep 600
        fi
    fi

    if [ $GET_LOG -eq 1 ]; then
        sudo nvme smart-log /dev/${DEV_NAME:0:5}
        sudo nvme ocp smart-add-log /dev/${DEV_NAME:0:5}
    fi
    
    # RUN TEST #
    #sudo /home/cm/bin/perf record ./db_bench --db=$AUX_PATH --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS
    sudo ./db_bench --db=$AUX_PATH --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS

    # END TEST #
    RESULT=$DIR_RESULT'CNS_'$BENCH_TYPE'_'$COMMENT
    mkdir -p $RESULT
    cp $AUX_PATH/LOG $RESULT/

    if [ $GET_LOG -eq 1 ]; then
        sleep 600
        sudo nvme smart-log /dev/${DEV_NAME:0:5}
        sudo nvme ocp smart-add-log /dev/${DEV_NAME:0:5}
    fi

    df -h # check utilization
    echo "[END-CNS] [TIME `(cat /proc/uptime)`]" `date +"%m-%d %H:%M:%S"`
}

test_fdp(){
    DEV_NAME=$1
    BENCH_TYPE=$2
    NUMS=$3
    THREADS=$4
    CLEANING=$5
    GET_LOG=$6
    if [ $# -eq 7 ]; then
        OPTIONS="$COMMON_OPTIONS"
        COMMENT=$7
    else
        OPTIONS="$COMMON_OPTIONS $7"
        COMMENT=$8
    fi

    # BEGIN TEST #
    echo "[RUN-FDP] [TIME `(cat /proc/uptime)`]" `date +"%m-%d %H:%M:%S"` $BENCH_TYPE $COMMENT $NUMS $DEV_NAME
    echo 3 | sudo tee /proc/sys/vm/drop_caches
    if [ $CLEANING -eq 1 ]; then
        sudo umount /dev/$DEV_NAME
        sudo nvme fdp update /dev/$DEV_NAME -p 0,1,2,3,4,5,6
        $TRIM_SH $DEV_NAME
        sudo nvme fdp status /dev/$DEV_NAME
        sudo rm -r $AUX_PATH/*
        sudo $FLEXFS mkfs --fdp_bd=$DEV_NAME --aux_path=$AUX_PATH --force --finish_threshold=50 --enable_gc
        if [ $GET_LOG -eq 1 ]; then
            sleep 600
        fi
    fi

    if [ $GET_LOG -eq 1 ]; then
        sudo nvme smart-log /dev/${DEV_NAME:0:5}
        sudo nvme ocp smart-add-log /dev/${DEV_NAME:0:5}
    fi

    # RUN TEST #
    DEV_TYPE="//fdp:"
    sudo ./db_bench --fs_uri=zenfs:$DEV_TYPE$DEV_NAME --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS
    #sudo /home/cm/bin/perf record ./db_bench --fs_uri=zenfs:$DEV_TYPE$DEV_NAME --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS

    # END TEST #
    RESULT=$DIR_RESULT'FDP_'$BENCH_TYPE'_'$COMMENT
    mkdir -p $RESULT
    cp $AUX_PATH/rocksdbtest/dbbench/LOG $RESULT/

    if [ $GET_LOG -eq 1 ]; then
        sleep 600
        sudo nvme smart-log /dev/${DEV_NAME:0:5}
        sudo nvme ocp smart-add-log /dev/${DEV_NAME:0:5}
    fi
    echo "[END-FDP] [TIME `(cat /proc/uptime)`]" `date +"%m-%d %H:%M:%S"`
}

test_zns(){
    DEV_NAME=$1
    BENCH_TYPE=$2
    NUMS=$3
    THREADS=$4
    CLEANING=$5
    GET_LOG=$6
    if [ $# -eq 7 ]; then
        OPTIONS="$COMMON_OPTIONS"
        COMMENT=$7
    else
        OPTIONS="$COMMON_OPTIONS $7"
        COMMENT=$8
    fi

    # BEGIN TEST #
    echo "[RUN-ZNS] [TIME `(cat /proc/uptime)`]" `date +"%m-%d %H:%M:%S"` $BENCH_TYPE $COMMENT $NUMS $DEV_NAME
    if [ $CLEANING -eq 1 ]; then
        sudo umount /dev/$DEV_NAME
        $TRIM_SH $DEV_NAME
        sudo rm -r $AUX_PATH/*
        sudo $FLEXFS mkfs --zbd=$DEV_NAME --aux_path=$AUX_PATH --force --finish_threshold=10 --enable_gc
        if [ $GET_LOG -eq 1 ]; then
            sleep 600
        fi
    fi

    if [ $GET_LOG -eq 1 ]; then
        sudo nvme smart-log /dev/$DEV_NAME
    fi

    # RUN TEST #
    DEV_TYPE="//dev:"
    sudo ./db_bench --fs_uri=zenfs:$DEV_TYPE$DEV_NAME --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS

    # END TEST #
    RESULT=$DIR_RESULT'ZNS_'$BENCH_TYPE'_'$COMMENT
    mkdir -p $RESULT
    cp $AUX_PATH/rocksdbtest/dbbench/LOG $RESULT/

    if [ $GET_LOG -eq 1 ]; then
        sleep 600
        sudo nvme smart-log /dev/$DEV_NAME
    fi
    echo "[END-ZNS] [TIME `(cat /proc/uptime)`]" `date +"%m-%d %H:%M:%S"`
}

test_tor(){
    DEV_NAME=$1
    BENCH_TYPE=$2
    NUMS=$3
    THREADS=$4
    CLEANING=$5
    GET_LOG=$6
    if [ $# -eq 7 ]; then
        OPTIONS="$COMMON_OPTIONS"
        COMMENT=$7
    else
        OPTIONS="$COMMON_OPTIONS $7"
        COMMENT=$8
    fi

    # BEGIN TEST #
    echo "[RUN-TOR_FS] [TIME `(cat /proc/uptime)`]" $BENCH_TYPE $COMMENT $NUMS $DEV_NAME
    if [ $CLEANING -eq 1 ]; then
        sudo umount /dev/$DEV_NAME
        sudo nvme fdp update /dev/$DEV_NAME -p 0,1,2,3,4,5,6
        $TRIM_SH $DEV_NAME
        sudo nvme fdp status /dev/$DEV_NAME
        sudo rm -r $AUX_PATH/*
        if [ $GET_LOG -eq 1 ]; then
            sleep 600
        fi
    fi

    if [ $GET_LOG -eq 1 ]; then
        sudo nvme smart-log /dev/${DEV_NAME:0:5}
        sudo nvme ocp smart-add-log /dev/${DEV_NAME:0:5}
    fi

    # RUN TEST #
    sudo ./db_bench_torfs --db=$AUX_PATH --fs_uri=torfs:xnvme:/dev/ng${DEV_NAME: -3}?be=io_uring_cmd --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS


    # END TEST #
    RESULT=$DIR_RESULT'TOR_'$BENCH_TYPE'_'$COMMENT
    mkdir -p $RESULT
    cp $AUX_PATH/LOG $RESULT/

    if [ $GET_LOG -eq 1 ]; then
        sleep 600
        sudo nvme smart-log /dev/${DEV_NAME:0:5}
        sudo nvme ocp smart-add-log /dev/${DEV_NAME:0:5}
    fi
    echo "[END-TOR_FS] [TIME `(cat /proc/uptime)`]"
}

#test_cns <DevName> <Type of benchmark> <# of operations> <# of threads> <Cleaning before test[0:no, 1:yes]> <Get LOG[0:no, 1:yes]> <User Options or Comment> <Comment>
test_cns_common(){
    test_cns $1 fillseq $NUM_500M 1 1 1 "500M" 
    test_cns $1 overwrite $NUM_300M 1 0 1 "--use_existing_db" "300M_1"
    test_cns $1 overwrite $NUM_300M 1 0 1 "--use_existing_db" "300M_2"
    test_cns $1 overwrite $NUM_300M 1 0 1 "--use_existing_db" "300M_3"
    test_cns $1 overwrite $NUM_300M 1 0 1 "--use_existing_db" "300M_4"
    test_cns $1 overwrite $NUM_300M 1 0 1 "--use_existing_db" "300M_5"
    test_cns $1 readwhilewriting $NUM_1 16 0 1 "--use_existing_db --duration=3600" "1"
    #test_cns $1 readwhilewriting $NUM_1B 16 0 1 "--use_existing_db --duration=3600" "1B_2"
    #test_cns $1 readwhilewriting $NUM_1B 16 0 1 "--use_existing_db --duration=3600" "1B_3"
    test_cns $1 readrandomwriterandom $NUM_1 16 0 1 "--use_existing_db --duration=3600 --readwritepercent=50" "1"
    #test_cns $1 readrandomwriterandom $NUM_1B 16 0 1 "--use_existing_db --duration=3600 --readwritepercent=50" "1B_2"
    #test_cns $1 readrandomwriterandom $NUM_1B 16 0 1 "--use_existing_db --duration=3600 --readwritepercent=50" "1B_3"
}

test_zns_common(){
    test_zns $1 fillseq $NUM_500M 1 1 1 "500M" 
    test_zns $1 overwrite $NUM_300M 1 0 1 "--use_existing_db" "300M_1"
    test_zns $1 overwrite $NUM_300M 1 0 1 "--use_existing_db" "300M_2"
    test_zns $1 overwrite $NUM_300M 1 0 1 "--use_existing_db" "300M_3"
    test_zns $1 overwrite $NUM_300M 1 0 1 "--use_existing_db" "300M_4"
    test_zns $1 overwrite $NUM_300M 1 0 1 "--use_existing_db" "300M_5"
    test_zns $1 readwhilewriting $NUM_1M 16 0 1 "--use_existing_db --duration=3600" "1"
    #test_zns $1 readwhilewriting $NUM_1B 16 0 1 "--use_existing_db --duration=3600" "1B_2"
    #test_zns $1 readwhilewriting $NUM_1B 16 0 1 "--use_existing_db --duration=3600" "1B_3"
    test_zns $1 readrandomwriterandom $NUM_1M 16 0 1 "--use_existing_db --duration=3600 --readwritepercent=50" "1"
    #test_zns $1 readrandomwriterandom $NUM_1B 16 0 1 "--use_existing_db --duration=3600 --readwritepercent=50" "1B_2"
    #test_zns $1 readrandomwriterandom $NUM_1B 16 0 1 "--use_existing_db --duration=3600 --readwritepercent=50" "1B_3"
}

test_fdp_common(){
    test_fdp $1 fillseq $NUM_500M 1 1 1 "500M" 
    test_fdp $1 overwrite $NUM_300M 1 0 1 "--use_existing_db" "300M_1"
    test_fdp $1 overwrite $NUM_300M 1 0 1 "--use_existing_db" "300M_2"
    test_fdp $1 overwrite $NUM_300M 1 0 1 "--use_existing_db" "300M_3"
    test_fdp $1 overwrite $NUM_300M 1 0 1 "--use_existing_db" "300M_4"
    test_fdp $1 overwrite $NUM_300M 1 0 1 "--use_existing_db" "300M_5"
    test_fdp $1 readwhilewriting $NUM_1M 16 0 1 "--use_existing_db --duration=3600" "300M_1"
    #test_fdp $1 readwhilewriting $NUM_1B 16 0 1 "--use_existing_db --duration=3600" "1B_2"
    #test_fdp $1 readwhilewriting $NUM_1B 16 0 1 "--use_existing_db --duration=3600" "1B_3"
    test_fdp $1 readrandomwriterandom $NUM_1M 16 0 1 "--use_existing_db --duration=3600 --readwritepercent=50" "1"
    #test_fdp $1 readrandomwriterandom $NUM_1B 16 0 1 "--use_existing_db --duration=3600 --readwritepercent=50" "1B_2"
    #test_fdp $1 readrandomwriterandom $NUM_1B 16 0 1 "--use_existing_db --duration=3600 --readwritepercent=50" "1B_3"
}

test_tor_common(){
    test_tor $1 fillseq $NUM_500M 1 1 1 "500M" 
    test_tor $1 overwrite $NUM_300M 1 0 1 "--use_existing_db" "300M_1"
    test_tor $1 overwrite $NUM_300M 1 0 1 "--use_existing_db" "300M_2"
    test_tor $1 overwrite $NUM_300M 1 0 1 "--use_existing_db" "300M_3"
    test_tor $1 overwrite $NUM_300M 1 0 1 "--use_existing_db" "300M_4"
    test_tor $1 overwrite $NUM_300M 1 0 1 "--use_existing_db" "300M_5"
    test_tor $1 readwhilewriting $NUM_1M 16 0 1 "--use_existing_db --duration=3600" "1"
    #test_tor $1 readwhilewriting $NUM_1B 16 0 1 "--use_existing_db --duration=3600" "1B_2"
    #test_tor $1 readwhilewriting $NUM_1B 16 0 1 "--use_existing_db --duration=3600" "1B_3"
    test_tor $1 readrandomwriterandom $NUM_1M 16 0 1 "--use_existing_db --duration=3600 --readwritepercent=50" "1"
    #test_tor $1 readrandomwriterandom $NUM_1B 16 0 1 "--use_existing_db --duration=3600 --readwritepercent=50" "1B_2"
    #test_tor $1 readrandomwriterandom $NUM_1B 16 0 1 "--use_existing_db --duration=3600 --readwritepercent=50" "1B_3"
}

test_cns_dev(){
    test_cns $1 fillseq $NUM_10M 1 1 0 "10M" 
    test_cns $1 overwrite $NUM_10M 1 0 0 "--use_existing_db" "10M_1"
    test_cns $1 overwrite $NUM_10M 1 0 0 "--use_existing_db" "10M_2"
}

test_tor_dev(){
    test_tor $1 fillseq $NUM_10M 1 1 0 "10M" 
    test_tor $1 overwrite $NUM_10M 1 0 0 "--use_existing_db" "10M_1"
    test_tor $1 overwrite $NUM_10M 1 0 0 "--use_existing_db" "10M_2"
}

test_fdp_dev(){
    test_fdp $1 fillseq $NUM_1B 1 1 0 "1B" 
    test_fdp $1 overwrite $NUM_10M 1 0 0 "--use_existing_db" "10M_1"
    test_fdp $1 overwrite $NUM_10M 1 0 0 "--use_existing_db" "10M_2"
}

test_zns_dev(){
    test_zns $1 fillseq $NUM_10M 1 1 0 "10M" 
    test_zns $1 overwrite $NUM_10M 1 0 0 "--use_existing_db" "10M_1"
    test_zns $1 overwrite $NUM_10M 1 0 0 "--use_existing_db" "10M_2"
}

test_cns_waf(){
    #test_cns $1 fillseq $NUM_3B 1 1 1 "--max_background_jobs=4 --max_bytes_for_level_multiplier=6" "3B" 
    #test_cns $1 overwrite $NUM_3B 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=6 --max_background_jobs=4" "3B_1"
    # todo : WAF 비교 (default)
    #test_fdp $1 fillseq $NUM_10M 1 1 0 "--max_bytes_for_level_multiplier=8 --max_background_jobs=4" "temp" 
    #test_fdp $1 overwrite $NUM_10M 1 0 0 "--use_existing_db --max_bytes_for_level_multiplier=8 --max_background_jobs=4" "temp"

    #test_cns $1 fillseq $NUM_4B 1 1 1 "--max_bytes_for_level_multiplier=8 --max_background_jobs=4" "5B" 
    #test_cns $1 overwrite $NUM_4B 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=8 --max_background_jobs=4" "5B_1"
    #test_cns $1 overwrite $NUM_4B 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=8 --max_background_jobs=4" "5B_2"

    #test_fdp $1 overwrite $NUM_4B 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=8 --max_background_jobs=4" "5B_3"
    #test_fdp $1 overwrite $NUM_4B 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=8 --max_background_jobs=4" "5B_4"
    #test_fdp $1 overwrite $NUM_4B 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=8 --max_background_jobs=4" "5B_5"
    #test_cns $1 fillseq $NUM_500M 1 1 1 "500M" 
    #test_cns $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_1"
    #test_cns $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_2"
    #test_cns $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_3"
    #test_cns $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_4"
    #test_cns $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_5"
    #test_cns $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_6"
    #test_cns $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_7"
    #test_cns $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_8"
    #test_cns $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_9"
    #test_cns $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_10"
    #test_cns $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_11"
    #test_cns $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_12"
    #test_cns $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_13"
    #test_cns $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_14"
    #test_cns $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_15"
    #test_cns $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_16"
    #test_cns $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_17"
    #test_cns $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_18"
    #test_cns $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_19"
    #test_cns $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_20"
    
    test_cns $1 fillseq $NUM_500M 1 1 1 "--max_bytes_for_level_multiplier=5" "500M" 
    test_cns $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=5" "500M_1"
    test_cns $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=5" "500M_2"
    test_cns $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=5" "500M_3"
    test_cns $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=5" "500M_4"
    test_cns $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=5" "500M_5"

    #test_cns $1 fillseq $NUM_500M 1 1 1 "--max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "500M" 
    #test_cns $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "500M_1"
    #test_cns $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "500M_2"
    #test_cns $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "500M_3"
    #test_cns $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "500M_4"
    #test_cns $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "500M_5"

    #test_cns $1 fillseq $NUM_500M 1 1 0 "--max_background_jobs=8 --max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "1B" 
    #test_cns $1 overwrite $NUM_500M 1 0 0 "--max_background_jobs=8 --use_existing_db --max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "1B"
    #test_cns $1 overwrite $NUM_500M 1 0 0 "--max_background_jobs=8 --use_existing_db --max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "1B"
    #test_cns $1 overwrite $NUM_500M 1 0 0 "--max_background_jobs=8 --use_existing_db --max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "1B"
    #test_cns $1 overwrite $NUM_500M 1 0 0 "--max_background_jobs=8 --use_existing_db --max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "1B"
    #
    #test_cns $1 overwrite $NUM_1B 1 0 1 "--use_existing_db --max_background_jobs=8 --max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "1B"
    #test_cns $1 fillseq $NUM_500M 1 1 1 "base" 
    #test_cns $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --duration=3600" "base_1"
    #test_cns $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --duration=3600" "base_2"
    #test_cns $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --duration=3600" "base_3"

    #test_cns $1 fillrandom $NUM_500M 1 1 1 "fillrandom" 
    #test_cns $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --duration=3600" "fillrandom_1"
    #test_cns $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --duration=3600" "fillrandom_1"
    #test_cns $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --duration=3600" "fillrandom_1"

    #test_cns $1 fillseq $NUM_500M 1 1 1 "th16" 
    #test_cns $1 overwrite $NUM_500M 16 0 1 "--use_existing_db --duration=3600" "th16"

    #test_cns $1 fillseq $NUM_700M 1 1 1 "--max_background_compactions=8 --max_bytes_for_level_multiplier=4 --level0_file_num_compaction_trigger=8" "700M" 
    #test_cns $1 overwrite $NUM_10M 1 0 1 "--use_existing_db" "10M"
    #test_cns $1 readwhilewriting $NUM_1M 16 0 1 "--use_existing_db --duration=1800" "rnw"
    #test_cns $1 readrandomwriterandom $NUM_1M 16 0 1 "--use_existing_db --duration=1800 --readwritepercent=50" "rrwr"
}

test_fdp_waf(){
    #test_fdp $1 fillseq $NUM_500M 1 1 1 "--max_bytes_for_level_multiplier=5" "500M" 
    #test_fdp $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=5  --max_background_jobs=8" "500M_1"
    #test_fdp $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=5  --max_background_jobs=8" "500M_2"
    #test_fdp $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=5  --max_background_jobs=8" "500M_3"
    #test_fdp $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=5  --max_background_jobs=8" "500M_4"
    #test_fdp $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=5  --max_background_jobs=8" "500M_5"

    test_fdp $1 fillseq $NUM_500M 1 1 1 "--max_bytes_for_level_multiplier=5" "500M" 
    test_fdp $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=5" "500M_1"
    test_fdp $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=5" "500M_2"
    test_fdp $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=5" "500M_3"
    test_fdp $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=5" "500M_4"
    test_fdp $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=5" "500M_5"
    #test_fdp $1 fillseq $NUM_2B 1 1 1 "--max_background_jobs=4 --max_bytes_for_level_multiplier=6" "3B" 
    #test_fdp $1 readseq $NUM_2B 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=6 --max_background_jobs=8" "3B_1"
    #test_fdp $1 readseq $NUM_2B 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=6 --max_background_jobs=8" "3B_2"
    #test_fdp $1 readseq $NUM_2B 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=6 --max_background_jobs=8" "3B_3"
    #test_fdp $1 overwrite $NUM_3B 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=6 --max_background_jobs=8" "3B_1"
    #test_fdp $1 overwrite $NUM_3B 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=6 --max_background_jobs=8" "3B_2"
    #test_fdp $1 overwrite $NUM_1B 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=6 --max_background_jobs=4" "1B_3"
    #test_fdp $1 fillseq $NUM_3B 1 1 1 "--max_background_jobs=4 --max_bytes_for_level_multiplier=6" "3B" 
    #test_fdp $1 overwrite $NUM_3B 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=6 --max_background_jobs=4" "3B_2"
    #test_fdp $1 overwrite $NUM_3B 1 0 1 "--use_existing_db --max_background_jobs=4" "4B_2"
    #test_fdp $1 fillseq $NUM_500M 1 1 1 "500M" 
    #test_fdp $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_1"
    #test_fdp $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_2"
    #test_fdp $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_3"
    #test_fdp $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_4"
    #test_fdp $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_5"
    #test_fdp $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_6"
    #test_fdp $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_7"
    #test_fdp $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_8"
    #test_fdp $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_9"
    #test_fdp $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_10"
    #test_fdp $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_11"
    #test_fdp $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_12"
    #test_fdp $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_13"
    #test_fdp $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_14"
    #test_fdp $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_15"
    #test_fdp $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_16"
    #test_fdp $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_17"
    #test_fdp $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_18"
    #test_fdp $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_19"
    #test_fdp $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_20"

    #
    #test_fdp $1 fillseq $NUM_1B 1 1 1 "--max_background_jobs=8 --max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "1B" 
    #test_fdp $1 overwrite $NUM_1B 1 0 1 "--max_background_jobs=8 --use_existing_db --max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "1B"

    #test_fdp $1 fillseq $NUM_500M 1 1 1 "--max_background_jobs=4 --max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "multi_5" 
    #test_fdp $1 overwrite $NUM_500M 1 0 1 "--max_background_jobs=4 --use_existing_db --max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "500M_1"
    #test_fdp $1 overwrite $NUM_500M 1 0 1 "--max_background_jobs=4 --use_existing_db --max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "500M_2"
    #test_fdp $1 overwrite $NUM_500M 1 0 1 "--max_background_jobs=4 --use_existing_db --max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "500M_3"
    #test_fdp $1 overwrite $NUM_500M 1 0 1 "--max_background_jobs=4 --use_existing_db --max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "500M_4"
    #test_fdp $1 overwrite $NUM_500M 1 0 1 "--max_background_jobs=4 --use_existing_db --max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "500M_5"

    #test_fdp $1 fillseq $NUM_500M 1 1 1 "--max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "multi_5" 
    #test_fdp $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "500M_1"
    #test_fdp $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "500M_2"
    #test_fdp $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "500M_3"
    #test_fdp $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "500M_4"
    #test_fdp $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "500M_5"
    # todo : WAF 비교 (default)
    #test_fdp $1 fillseq $NUM_500M 1 1 0 "db_default" 
    #test_fdp $1 overwrite $NUM_500M 1 0 0 "--use_existing_db" "500M_1"
    #test_fdp $1 overwrite $NUM_500M 1 0 0 "--use_existing_db" "500M_2"
    #test_fdp $1 overwrite $NUM_500M 1 0 0 "--use_existing_db" "500M_3"
    #test_fdp $1 overwrite $NUM_500M 1 0 0 "--use_existing_db" "500M_4"
    #test_fdp $1 overwrite $NUM_500M 1 0 0 "--use_existing_db" "500M_5"
    #
    #test_fdp $1 fillseq $NUM_700M 1 1 1 "700M" 
    #test_fdp $1 overwrite $NUM_1B 1 0 1 "--use_existing_db" "1B"
    #test_fdp $1 fillseq $NUM_500M 1 1 1 "base" 
    #test_fdp $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --duration=3600" "base_1"
    #test_fdp $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --duration=3600" "base_2"
    #test_fdp $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --duration=3600" "base_3"

    #test_fdp $1 fillrandom $NUM_500M 1 1 1 "fillrandom" 
    #test_fdp $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --duration=3600" "fillrandom_1"
    #test_fdp $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --duration=3600" "fillrandom_1"
    #test_fdp $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --duration=3600" "fillrandom_1"

    #test_cns $1 fillseq $NUM_500M 1 1 1 "th16" 
    #test_cns $1 overwrite $NUM_500M 16 0 1 "--use_existing_db --duration=3600" "th16"

    #test_cns $1 fillseq $NUM_500M 1 1 1 "--max_bytes_for_level_multiplier=4" "max_4" 
    #test_cns $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --duration=3600 --max_bytes_for_level_multiplier=4" "max_4"
    #
    #test_fdp $1 fillseq $NUM_700M 1 1 1 "700M" 
    #test_fdp $1 overwrite $NUM_1B 1 0 1 "--use_existing_db" "1B"
    #test_fdp $1 readwhilewriting $NUM_1M 16 0 1 "--use_existing_db --duration=1800" "rnw"
    #test_fdp $1 readrandomwriterandom $NUM_1M 16 0 1 "--use_existing_db --duration=1800 --readwritepercent=50" "rrwr"

    #test_fdp $1 fillseq $NUM_500M 1 1 1 "default" 
    #test_fdp $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --duration=3600" "def_1"
    #test_fdp $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --duration=3600" "def_2"
    #test_fdp $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --duration=3600" "def_3"
    #test_fdp $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --duration=3600" "def_4"
}

test_tor_waf(){
    # todo : WAF 비교 (default)
    test_tor $1 fillseq $NUM_500M 1 1 1 "db_default" 
    test_tor $1 overwrite $NUM_500M 1 0 1 "--use_existing_db" "500M_1"
    test_tor $1 overwrite $NUM_500M 1 0 1 "--use_existing_db" "500M_2"
    test_tor $1 overwrite $NUM_500M 1 0 1 "--use_existing_db" "500M_3"
    test_tor $1 overwrite $NUM_500M 1 0 1 "--use_existing_db" "500M_4"
    test_tor $1 overwrite $NUM_500M 1 0 1 "--use_existing_db" "500M_5"

    #test_tor $1 fillseq $NUM_500M 1 1 1 "500M" 
    #test_tor $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_1"
    #test_tor $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_2"
    #test_tor $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_3"
    #test_tor $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_4"
    #test_tor $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_5"
    #test_tor $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_6"
    #test_tor $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_7"
    #test_tor $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_8"
    #test_tor $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_9"
    #test_tor $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_10"
    #test_tor $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_11"
    #test_tor $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_12"
    #test_tor $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_13"
    #test_tor $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_14"
    #test_tor $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_15"
    #test_tor $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_16"
    #test_tor $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_17"
    #test_tor $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_18"
    #test_tor $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_19"
    #test_tor $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "100M_20"

    #test_tor $1 fillseq $NUM_500M 1 1 1 "--max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "500M" 
    #test_tor $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "500M_1"
    #test_tor $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "500M_2"
    #test_tor $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "500M_3"
    #test_tor $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "500M_4"
    #test_tor $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "500M_5"
    #test_tor $1 fillseq $NUM_800M 1 1 1 "--max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "1B" 
    #test_tor $1 overwrite $NUM_1B 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "1B"
    #test_tor $1 fillseq $NUM_700M 1 1 1 "700M" 
    #test_tor $1 overwrite $NUM_1B 1 0 1 "--use_existing_db" "1B"
    #test_tor $1 readwhilewriting $NUM_1M 16 0 1 "--use_existing_db --duration=1800" "rnw"
    #test_tor $1 readrandomwriterandom $NUM_1M 16 0 1 "--use_existing_db --duration=1800 --readwritepercent=50" "rrwr"

    #test_tor $1 fillseq $NUM_500M 1 1 1 "--max_bytes_for_level_multiplier=4" "max_4" 
    #test_tor $1 overwrite $NUM_100M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=4" "max4_1"
    #test_tor $1 overwrite $NUM_100M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=4" "max4_2"
    #test_tor $1 overwrite $NUM_100M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=4" "max4_3"
    #test_tor $1 overwrite $NUM_100M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=4" "max4_4"
    #test_tor $1 overwrite $NUM_100M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=4" "max4_5"
    #test_tor $1 overwrite $NUM_100M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=4" "max4_6"
    #test_tor $1 overwrite $NUM_100M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=4" "max4_7"
    #test_tor $1 overwrite $NUM_100M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=4" "max4_8"
    #test_tor $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --duration=3600 --max_bytes_for_level_multiplier=4" "max4_5"
    #test_tor $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --duration=3600 --max_bytes_for_level_multiplier=4" "max4_6"
}

test_perf(){

COMMON_OPTIONS=" --stats_dump_period_sec=60 --key_size=20 --value_size=800 --histogram" #  --statistics"
    #XFS Buffered
    test_cns $1 fillrandom $NUM_10M 1 1 0 "buff_rw_t1" 
    test_cns $1 fillrandom $NUM_10M 16 1 0 "buff_rw_t16" 
    test_cns $1 fillseq $NUM_10M 1 1 0 "buff_sw_t1" 
    test_cns $1 readseq $NUM_10M 1 0 0 "--use_existing_db" "buff_sr_t1" 
    test_cns $1 readseq $NUM_10M 16 0 0 "--use_existing_db" "buff_sr_t16" 
    test_cns $1 readseq $NUM_10M 1 0 0 "--use_existing_db --max_auto_readahead_size=2097152 --auto_readahead_size" "buff_sr_auto_t1" 
    test_cns $1 readseq $NUM_10M 16 0 0 "--use_existing_db --max_auto_readahead_size=2097152 --auto_readahead_size" "buff_sr_auto_t16" 
    test_cns $1 readrandom $NUM_1M 1 0 0 "--use_existing_db" "buff_rr_t1" 
    test_cns $1 readrandom $NUM_1M 16 0 0 "--use_existing_db" "buff_rr_t16" 
    test_cns $1 overwrite $NUM_10M 1 0 0 "--use_existing_db" "buff_over_t1" 
    test_cns $1 overwrite $NUM_10M 16 0 0 "--use_existing_db" "buff_over_t16" 

COMMON_OPTIONS=" --stats_dump_period_sec=60 --key_size=20 --value_size=800 --use_direct_io_for_flush_and_compaction --use_direct_reads --histogram" #  --statistics"
    #XFS Direct I/O for Read
    test_cns $1 fillrandom $NUM_10M 1 1 0 "rw_t1" 
    test_cns $1 fillrandom $NUM_10M 16 1 0 "rw_t16" 
    test_cns $1 fillseq $NUM_10M 1 1 0 "sw_t1" 
    test_cns $1 readseq $NUM_10M 1 0 0 "--use_existing_db" "sr_t1" 
    test_cns $1 readseq $NUM_10M 16 0 0 "--use_existing_db" "sr_t16" 
    test_cns $1 readseq $NUM_10M 1 0 0 "--use_existing_db --max_auto_readahead_size=2097152 --auto_readahead_size" "sr_auto_t1" 
    test_cns $1 readseq $NUM_10M 16 0 0 "--use_existing_db --max_auto_readahead_size=2097152 --auto_readahead_size" "sr_auto_t16" 
    test_cns $1 readrandom $NUM_1M 1 0 0 "--use_existing_db" "rr_t1" 
    test_cns $1 readrandom $NUM_1M 16 0 0 "--use_existing_db" "rr_t16" 
    test_cns $1 overwrite $NUM_10M 1 0 0 "--use_existing_db" "over_t1" 
    test_cns $1 overwrite $NUM_10M 16 0 0 "--use_existing_db" "over_t16" 

    #FlexFS
COMMON_OPTIONS=" --stats_dump_period_sec=60 --key_size=20 --value_size=800 --histogram" #  --statistics"
    test_fdp $1 fillrandom $NUM_10M 1 1 0 "rw_t1" 
    test_fdp $1 fillrandom $NUM_10M 16 1 0 "rw_t16" 
    test_fdp $1 fillseq $NUM_10M 1 1 0 "sw_t1" 
    test_fdp $1 readseq $NUM_10M 1 0 0 "--use_existing_db" "sr_t1" 
    test_fdp $1 readseq $NUM_10M 16 0 0 "--use_existing_db" "sr_t16" 
    test_fdp $1 readseq $NUM_10M 1 0 0 "--use_existing_db --max_auto_readahead_size=2097152 --auto_readahead_size" "sr_auto_t1" 
    test_fdp $1 readseq $NUM_10M 16 0 0 "--use_existing_db --max_auto_readahead_size=2097152 --auto_readahead_size" "sr_auto_t16" 
    test_fdp $1 readrandom $NUM_1M 1 0 0 "--use_existing_db" "rr_t1" 
    test_fdp $1 readrandom $NUM_1M 16 0 0 "--use_existing_db" "rr_t16" 
    test_fdp $1 overwrite $NUM_10M 1 0 0 "--use_existing_db" "over_t1" 
    test_fdp $1 overwrite $NUM_10M 16 0 0 "--use_existing_db" "over_t16" 

COMMON_OPTIONS=" --stats_dump_period_sec=60 --key_size=20 --value_size=800 --use_direct_io_for_flush_and_compaction --use_direct_reads --histogram" #  --statistics"
    test_fdp $1 fillrandom $NUM_10M 1 1 0 "rw_t1" 
    test_fdp $1 fillrandom $NUM_10M 16 1 0 "rw_t16" 
    test_fdp $1 fillseq $NUM_10M 1 1 0 "sw_t1" 
    test_fdp $1 readseq $NUM_10M 1 0 0 "--use_existing_db" "sr_t1" 
    test_fdp $1 readseq $NUM_10M 16 0 0 "--use_existing_db" "sr_t16" 
    test_fdp $1 readseq $NUM_10M 1 0 0 "--use_existing_db --max_auto_readahead_size=2097152 --auto_readahead_size" "sr_auto_t1" 
    test_fdp $1 readseq $NUM_10M 16 0 0 "--use_existing_db --max_auto_readahead_size=2097152 --auto_readahead_size" "sr_auto_t16" 
    test_fdp $1 readrandom $NUM_1M 1 0 0 "--use_existing_db" "rr_t1" 
    test_fdp $1 readrandom $NUM_1M 16 0 0 "--use_existing_db" "rr_t16" 
    test_fdp $1 overwrite $NUM_10M 1 0 0 "--use_existing_db" "over_t1" 
    test_fdp $1 overwrite $NUM_10M 16 0 0 "--use_existing_db" "over_t16" 

    #TorFS
    test_tor $1 fillrandom $NUM_10M 1 1 0 "rw_t1" 
    test_tor $1 fillrandom $NUM_10M 16 1 0 "rw_t16" 
    test_tor $1 fillseq $NUM_10M 1 1 0 "sw_t1" 
    test_tor $1 readseq $NUM_10M 1 0 0 "--use_existing_db" "sr_t1" 
    test_tor $1 readseq $NUM_10M 16 0 0 "--use_existing_db" "sr_t16" 
    test_tor $1 readseq $NUM_10M 1 0 0 "--use_existing_db --max_auto_readahead_size=2097152 --auto_readahead_size" "sr_auto_t1" 
    test_tor $1 readseq $NUM_10M 16 0 0 "--use_existing_db --max_auto_readahead_size=2097152 --auto_readahead_size" "sr_auto_t16" 
    test_tor $1 readrandom $NUM_1M 1 0 0 "--use_existing_db" "rr_t1" 
    test_tor $1 readrandom $NUM_1M 16 0 0 "--use_existing_db" "rr_t16" 
    test_tor $1 overwrite $NUM_10M 1 0 0 "--use_existing_db" "over_t1" 
    test_tor $1 overwrite $NUM_10M 16 0 0 "--use_existing_db" "over_t16" 

    #test_cns $1 readwhilewriting $NUM_1M 1 0 0 "--use_existing_db --duration=300" "rnw_t1"
    #test_cns $1 readwhilewriting $NUM_1M 16 0 0 "--use_existing_db --duration=300" "rnw_t16"
    #test_cns $1 readrandomwriterandom $NUM_1M 1 0 0 "--use_existing_db --readwritepercent=50 --duration=300" "rrwr_t1"
    #test_cns $1 readrandomwriterandom $NUM_1M 16 0 0 "--use_existing_db --readwritepercent=50 --duration=300" "rrwr_t16"

#    test_fdp $1 fillseq $NUM_10M 1 1 0 "default" 
#    test_fdp $1 readseq $NUM_10M 1 0 0 "--use_existing_db" "sr_t1" 
#    test_fdp $1 readseq $NUM_10M 16 0 0 "--use_existing_db" "sr_t16" 
#    test_fdp $1 readseq $NUM_10M 1 0 0 "--use_existing_db --max_auto_readahead_size=2097152 --auto_readahead_size" "sr_auto_t1" 
#    test_fdp $1 readseq $NUM_10M 16 0 0 "--use_existing_db --max_auto_readahead_size=2097152 --auto_readahead_size" "sr_auto_t16" 
#    test_fdp $1 readrandom $NUM_1M 1 0 0 "--use_existing_db" "rr_t1" 
#    test_fdp $1 readrandom $NUM_1M 16 0 0 "--use_existing_db" "rr_t16" 
#    test_fdp $1 overwrite $NUM_10M 1 0 0 "--use_existing_db" "rw_t1" 
#    test_fdp $1 overwrite $NUM_10M 16 0 0 "--use_existing_db" "rw_t16" 

    #test_fdp $1 readwhilewriting $NUM_1M 1 0 0 "--use_existing_db --duration=300" "rnw_t1"
    #test_fdp $1 readwhilewriting $NUM_1M 16 0 0 "--use_existing_db --duration=300" "rnw_t16"
    #test_fdp $1 readrandomwriterandom $NUM_1M 1 0 0 "--use_existing_db --readwritepercent=50 --duration=300" "rrwr_t1"
    #test_fdp $1 readrandomwriterandom $NUM_1M 16 0 0 "--use_existing_db --readwritepercent=50 --duration=300" "rrwr_t16"

#    test_tor $1 fillseq $NUM_10M 1 1 0 "default" 
#    test_tor $1 readseq $NUM_10M 1 0 0 "--use_existing_db" "sr_t1" 
#    test_tor $1 readseq $NUM_10M 16 0 0 "--use_existing_db" "sr_t16" 
#    test_tor $1 readseq $NUM_10M 1 0 0 "--use_existing_db --max_auto_readahead_size=2097152 --auto_readahead_size" "sr_auto_t1" 
#    test_tor $1 readseq $NUM_10M 16 0 0 "--use_existing_db --max_auto_readahead_size=2097152 --auto_readahead_size" "sr_auto_t16" 
#    test_tor $1 readrandom $NUM_1M 1 0 0 "--use_existing_db" "rr_t1" 
#    test_tor $1 readrandom $NUM_1M 16 0 0 "--use_existing_db" "rr_t16" 
#    test_tor $1 overwrite $NUM_10M 1 0 0 "--use_existing_db" "rw_t1" 
#    test_tor $1 overwrite $NUM_10M 16 0 0 "--use_existing_db" "rw_t16" 

    #test_tor $1 readwhilewriting $NUM_1M 1 0 0 "--use_existing_db --duration=300" "rnw_t1"
    #test_tor $1 readwhilewriting $NUM_1M 16 0 0 "--use_existing_db --duration=300" "rnw_t16"
    #test_tor $1 readrandomwriterandom $NUM_1M 1 0 0 "--use_existing_db --readwritepercent=50 --duration=300" "rrwr_t1"
    #test_tor $1 readrandomwriterandom $NUM_1M 16 0 0 "--use_existing_db --readwritepercent=50 --duration=300" "rrwr_t16"
}
test_compaction(){
    test_fdp $1 fillseq $NUM_500M 1 1 1 "default" 
    test_fdp $1 overwrite $NUM_500M 1 0 0 "--use_existing_db --duration=600" "sr_t1" 
    test_fdp $1 overwrite $NUM_500M 16 0 0 "--use_existing_db --duration=600" "sr_t16" 

    test_cns $1 fillseq $NUM_500M 1 1 1 "default" 
    test_cns $1 overwrite $NUM_500M 1 0 0 "--use_existing_db --duration=600" "sr_t1" 
    test_cns $1 overwrite $NUM_500M 16 0 0 "--use_existing_db --duration=600" "sr_t16" 

    test_tor $1 fillseq $NUM_500M 1 1 1 "default" 
    test_tor $1 overwrite $NUM_500M 1 0 0 "--use_existing_db --duration=600" "sr_t1" 
    test_tor $1 overwrite $NUM_500M 16 0 0 "--use_existing_db --duration=600" "sr_t16" 
}

test_debug(){
    #test_fdp $1 fillseq $NUM_300M 1 1 0 "--max_background_jobs=8 --max_bytes_for_level_multiplier=5" "temp" 
    #test_fdp $1 overwrite $NUM_100M 1 0 0 "--use_existing_db --max_background_jobs=8 --max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "100M"
    #test_fdp $1 overwrite $NUM_100M 1 0 0 "--use_existing_db --max_background_jobs=8 --max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "200M"
    test_fdp $1 readseq $NUM_10M 1 0 0 "--use_existing_db" "sr_t1" 
    #test_fdp $1 overwrite $NUM_100M 1 0 0 "--use_existing_db  --max_background_jobs=4 --max_bytes_for_level_multiplier=5 --level0_file_num_compaction_trigger=8" "300M"
    #test_fdp $1 fillseq $NUM_100M 1 1 0 "default"
    #test_fdp $1 fillseq $NUM_100M 1 1 0 "--disable_wal=true" "disable" 
    #test_tor $1 fillseq $NUM_100M 1 1 0 "default" 
    #test_tor $1 fillseq $NUM_100M 1 1 0 "--disable_wal=true" "disable" 
    #test_fdp $1 overwrite $NUM_500M 1 0 0 "--use_existing_db --duration=60" "over"

    #sleep 500

    #test_tor $1 fillseq $NUM_100M 1 1 0 "default" 
    #test_tor $1 overwrite 100 1 0 0 "--use_existing_db " "over"
}

test_perf_fillrandom(){
    test_cns $1 fillrandom $NUM_10M 1 1 0 "default" 
    #test_cns $1 fillrandom $NUM_10M 1 1 0 "--disable_wal" "default" 
    #test_fdp $1 fillrandom $NUM_10M 1 1 0 "--disable_wal" "default" 
    #test_fdp $1 fillrandom $NUM_10M 1 1 0 "default" 
    #test_tor $1 fillrandom $NUM_10M 1 1 0 "default" 
}

test_tmp(){
    #FlexFS
COMMON_OPTIONS=" --stats_dump_period_sec=60 --key_size=20 --value_size=800 --histogram" #  --statistics"
    test_fdp $1 fillrandom $NUM_10M 1 1 0 "rw_t1" 
    test_fdp $1 fillrandom $NUM_10M 16 1 0 "rw_t16" 
    test_fdp $1 fillseq $NUM_10M 1 1 0 "sw_t1" 
    test_fdp $1 readseq $NUM_10M 1 0 0 "--use_existing_db" "sr_t1" 
    test_fdp $1 readseq $NUM_10M 16 0 0 "--use_existing_db" "sr_t16" 
    test_fdp $1 readseq $NUM_10M 1 0 0 "--use_existing_db --max_auto_readahead_size=2097152 --auto_readahead_size" "sr_auto_t1" 
    test_fdp $1 readseq $NUM_10M 16 0 0 "--use_existing_db --max_auto_readahead_size=2097152 --auto_readahead_size" "sr_auto_t16" 
    test_fdp $1 readrandom $NUM_1M 1 0 0 "--use_existing_db" "rr_t1" 
    test_fdp $1 readrandom $NUM_1M 16 0 0 "--use_existing_db" "rr_t16" 
    test_fdp $1 overwrite $NUM_10M 1 0 0 "--use_existing_db" "over_t1" 
    test_fdp $1 overwrite $NUM_10M 16 0 0 "--use_existing_db" "over_t16" 

COMMON_OPTIONS=" --stats_dump_period_sec=60 --key_size=20 --value_size=800 --use_direct_io_for_flush_and_compaction --use_direct_reads --histogram" #  --statistics"
    test_fdp $1 fillrandom $NUM_10M 1 1 0 "rw_t1" 
    test_fdp $1 fillrandom $NUM_10M 16 1 0 "rw_t16" 
    test_fdp $1 fillseq $NUM_10M 1 1 0 "sw_t1" 
    test_fdp $1 readseq $NUM_10M 1 0 0 "--use_existing_db" "sr_t1" 
    test_fdp $1 readseq $NUM_10M 16 0 0 "--use_existing_db" "sr_t16" 
    test_fdp $1 readseq $NUM_10M 1 0 0 "--use_existing_db --max_auto_readahead_size=2097152 --auto_readahead_size" "sr_auto_t1" 
    test_fdp $1 readseq $NUM_10M 16 0 0 "--use_existing_db --max_auto_readahead_size=2097152 --auto_readahead_size" "sr_auto_t16" 
    test_fdp $1 readrandom $NUM_1M 1 0 0 "--use_existing_db" "rr_t1" 
    test_fdp $1 readrandom $NUM_1M 16 0 0 "--use_existing_db" "rr_t16" 
    test_fdp $1 overwrite $NUM_10M 1 0 0 "--use_existing_db" "over_t1" 
    test_fdp $1 overwrite $NUM_10M 16 0 0 "--use_existing_db" "over_t16" 
}

#test_universal(){
#COMMON_OPTIONS=" --compaction_style=1 --universal_size_ratio=10 --universal_min_merge_width=2 --universal_max_merge_width=4 --stats_dump_period_sec=60 --key_size=20 --value_size=800 --use_direct_io_for_flush_and_compaction --use_direct_reads --histogram" #  --statistics"
    #test_fdp $1 fillseq $NUM_500M 1 1 1 "--options_file=universal_options.ini" "500M" 
    #test_fdp $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --options_file=universal_options.ini" "500M_1"
    #test_fdp $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --options_file=universal_options.ini" "500M_2"
    #test_fdp $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --options_file=universal_options.ini" "500M_3"
    #test_fdp $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --options_file=universal_options.ini" "500M_4"
    #test_fdp $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --options_file=universal_options.ini" "500M_5"

    #test_cns $1 fillseq $NUM_500M 1 1 1 "--max_bytes_for_level_multiplier=5 --options_file=universal_options.ini" "500M" 
    #test_cns $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=5 --options_file=universal_options.ini" "500M_1"
    #test_cns $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=5 --options_file=universal_options.ini" "500M_2"
    #test_cns $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=5 --options_file=universal_options.ini" "500M_3"
    #test_cns $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=5 --options_file=universal_options.ini" "500M_4"
    #test_cns $1 overwrite $NUM_500M 1 0 1 "--use_existing_db --max_bytes_for_level_multiplier=5 --options_file=universal_options.ini" "500M_5"

#}

test_fdp_perf(){
    
    #1GB block cache
COMMON_OPTIONS=" --stats_dump_period_sec=60 --cache_size=1073741824 --key_size=20 --value_size=800 --use_direct_io_for_flush_and_compaction --use_direct_reads --histogram" #  --statistics"
    test_fdp $1 fillrandom $NUM_10M 1 1 0 "rw_t1" 
    test_fdp $1 fillrandom $NUM_10M 16 1 0 "rw_t16" 
    test_fdp $1 fillseq $NUM_10M 1 1 0 "sw_t1" 
    test_fdp $1 readseq $NUM_10M 1 0 0 "--use_existing_db" "sr_t1" 
    test_fdp $1 readseq $NUM_10M 16 0 0 "--use_existing_db" "sr_t16" 
    test_fdp $1 readseq $NUM_10M 1 0 0 "--use_existing_db --max_auto_readahead_size=2097152 --auto_readahead_size" "sr_auto_t1" 
    test_fdp $1 readseq $NUM_10M 16 0 0 "--use_existing_db --max_auto_readahead_size=2097152 --auto_readahead_size" "sr_auto_t16" 
    test_fdp $1 readrandom $NUM_1M 1 0 0 "--use_existing_db" "rr_t1" 
    test_fdp $1 readrandom $NUM_1M 16 0 0 "--use_existing_db" "rr_t16" 
    test_fdp $1 overwrite $NUM_10M 1 0 0 "--use_existing_db" "over_t1" 
    test_fdp $1 overwrite $NUM_10M 16 0 0 "--use_existing_db" "over_t16" 
}

test_fdp_trace(){
    #test_fdp $1 fillseq $NUM_500M 1 1 1 "500M" 
    test_fdp $1 overwrite $NUM_500M 1 0 1 "--use_existing_db" "500M_2"
}
main(){
    #/home/cm/dev/fdp/util/fill.sh /dev/nvme0n2 /home/cm/cns_fill
    cp $DB_BENCH .
    CURRENT=$(date +"%y%m%d_%H%M") 
    DIR_RESULT+=$CURRENT"/"
    sudo rm -r $DIR_RESULT
    mkdir $DIR_RESULT

    test_fdp_trace nvme0n1
    #test_fdp_perf nvme0n1
    #test_fdp_perf nvme0n1
    #test_universal nvme0n1
    #test_tmp nvme0n1
    #test_tmp nvme0n1
    #test_tmp nvme0n1
    #test_perf_fillrandom nvme0n1
    #test_perf nvme0n1
    #test_perf nvme0n1
    #test_perf nvme0n1
    #test_compaction nvme0n1
    #test_fdp_mkfs_trim nvme0n1
    #test_debug nvme0n1
    #test_fdp_waf nvme0n1
    #test_tor_waf nvme0n1
    #test_cns_waf nvme0n1
    #test_cns_common nvme0n1
    #test_tor_common nvme0n1
    #test_fdp_common nvme0n1
    #test_zns_common nvme2n2
    #
    #test_cns_dev nvme0n1
    #test_tor_dev nvme0n1
    #test_fdp_dev nvme0n1
    #test_zns_dev nvme2n2
}

main
