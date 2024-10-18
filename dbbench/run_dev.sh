
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
NUM_1B=1000000000

# CONFIGURATION
#COMMON_OPTIONS=" --disable_wal=true --stats_dump_period_sec=60 --key_size=20 --value_size=800 --use_direct_io_for_flush_and_compaction --use_direct_reads --async_io --histogram" #  --statistics"
COMMON_OPTIONS=" --stats_dump_period_sec=60 --key_size=20 --value_size=800 --use_direct_io_for_flush_and_compaction --use_direct_reads --async_io --histogram" #  --statistics"

test_fdp_mkfs_trim(){
    DEV_NAME=$1
    $TRIM_SH $DEV_NAME
    sleep 600
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
    echo "[RUN-CNS] [TIME `(cat /proc/uptime)`]" $BENCH_TYPE $COMMENT $NUMS $DEV_NAME
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
    echo "[END-CNS] [TIME `(cat /proc/uptime)`]" $BENCH_TYPE $COMMENT $NUMS $DEV_NAME
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
    echo "[RUN-FDP] [TIME `(cat /proc/uptime)`]" $BENCH_TYPE $COMMENT $NUMS $DEV_NAME
    if [ $CLEANING -eq 1 ]; then
        sudo umount /dev/$DEV_NAME
        $TRIM_SH $DEV_NAME
        sudo rm -r $AUX_PATH
        mkdir $AUX_PATH
        sudo $FLEXFS mkfs --fdp_bd=$DEV_NAME --aux_path=$AUX_PATH --force --finish_threshold=10 --enable_gc
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

    # END TEST #
    RESULT=$DIR_RESULT'FDP_'$BENCH_TYPE'_'$COMMENT
    mkdir -p $RESULT
    cp $AUX_PATH/rocksdbtest/dbbench/LOG $RESULT/

    if [ $GET_LOG -eq 1 ]; then
        sleep 600
        sudo nvme smart-log /dev/${DEV_NAME:0:5}
        sudo nvme ocp smart-add-log /dev/${DEV_NAME:0:5}
    fi
    echo "[END-FDP] [TIME `(cat /proc/uptime)`]" $BENCH_TYPE $COMMENT $NUMS $DEV_NAME
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
    echo "[RUN-ZNS] [TIME `(cat /proc/uptime)`]" $BENCH_TYPE $COMMENT $NUMS $DEV_NAME
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
    echo "[END-ZNS] [TIME `(cat /proc/uptime)`]" $BENCH_TYPE $COMMENT $NUMS $DEV_NAME
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
        $TRIM_SH $DEV_NAME
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
    test_cns $1 fillseq $NUM_1B 1 1 1 "1B" 
    test_cns $1 overwrite $NUM_100M 1 0 1 "--use_existing_db" "100M_1"
    test_cns $1 overwrite $NUM_100M 1 0 1 "--use_existing_db" "100M_2"
    test_cns $1 overwrite $NUM_100M 1 0 1 "--use_existing_db" "100M_3"
    test_cns $1 overwrite $NUM_100M 1 0 1 "--use_existing_db" "100M_3"
    test_cns $1 overwrite $NUM_100M 1 0 1 "--use_existing_db" "100M_3"
    test_cns $1 readwhilewriting $NUM_100M 16 0 1 "--use_existing_db --duration=3600" "100M_1"
    #test_cns $1 readwhilewriting $NUM_1B 16 0 1 "--use_existing_db --duration=3600" "1B_2"
    #test_cns $1 readwhilewriting $NUM_1B 16 0 1 "--use_existing_db --duration=3600" "1B_3"
    test_cns $1 readrandomwriterandom $NUM_100M 16 0 1 "--use_existing_db --duration=3600 --readwritepercent=50" "100M_1"
    #test_cns $1 readrandomwriterandom $NUM_1B 16 0 1 "--use_existing_db --duration=3600 --readwritepercent=50" "1B_2"
    #test_cns $1 readrandomwriterandom $NUM_1B 16 0 1 "--use_existing_db --duration=3600 --readwritepercent=50" "1B_3"
}

test_zns_common(){
    test_zns $1 fillseq $NUM_1B 1 1 1 "1B" 
    test_zns $1 overwrite $NUM_100M 1 0 1 "--use_existing_db" "100M_1"
    test_zns $1 overwrite $NUM_100M 1 0 1 "--use_existing_db" "100M_2"
    test_zns $1 overwrite $NUM_100M 1 0 1 "--use_existing_db" "100M_3"
    test_zns $1 readwhilewriting $NUM_100M 16 0 1 "--use_existing_db --duration=3600" "100M_1"
    #test_zns $1 readwhilewriting $NUM_1B 16 0 1 "--use_existing_db --duration=3600" "1B_2"
    #test_zns $1 readwhilewriting $NUM_1B 16 0 1 "--use_existing_db --duration=3600" "1B_3"
    test_zns $1 readrandomwriterandom $NUM_100M 16 0 1 "--use_existing_db --duration=3600 --readwritepercent=50" "100M_1"
    #test_zns $1 readrandomwriterandom $NUM_1B 16 0 1 "--use_existing_db --duration=3600 --readwritepercent=50" "1B_2"
    #test_zns $1 readrandomwriterandom $NUM_1B 16 0 1 "--use_existing_db --duration=3600 --readwritepercent=50" "1B_3"
}

test_fdp_common(){
    test_fdp $1 fillrandom $NUM_1B 1 1 1 "1B" 
    test_fdp $1 overwrite $NUM_1B 1 0 1 "--use_existing_db" "1B"
    #test_fdp $1 overwrite $NUM_1B 1 0 1 "--use_existing_db" "1B"
    #test_fdp $1 overwrite $NUM_100M 1 0 1 "--use_existing_db" "100M_3"
    #test_fdp $1 overwrite $NUM_100M 1 0 1 "--use_existing_db" "100M_4"
    #test_fdp $1 overwrite $NUM_100M 1 0 1 "--use_existing_db" "100M_5"
    #test_fdp $1 readwhilewriting $NUM_100M 16 0 1 "--use_existing_db --duration=3600" "100M_1"
    #test_fdp $1 readwhilewriting $NUM_1B 16 0 1 "--use_existing_db --duration=3600" "1B_2"
    #test_fdp $1 readwhilewriting $NUM_1B 16 0 1 "--use_existing_db --duration=3600" "1B_3"
    #test_fdp $1 readrandomwriterandom $NUM_100M 16 0 1 "--use_existing_db --duration=3600 --readwritepercent=50" "100M_1"
    #test_fdp $1 readrandomwriterandom $NUM_1B 16 0 1 "--use_existing_db --duration=3600 --readwritepercent=50" "1B_2"
    #test_fdp $1 readrandomwriterandom $NUM_1B 16 0 1 "--use_existing_db --duration=3600 --readwritepercent=50" "1B_3"
}

test_tor_common(){
    test_tor $1 fillseq $NUM_1B 1 1 1 "1B" 
    test_tor $1 overwrite $NUM_100M 1 0 1 "--use_existing_db" "100M_1"
    test_tor $1 overwrite $NUM_100M 1 0 1 "--use_existing_db" "100M_2"
    test_tor $1 overwrite $NUM_100M 1 0 1 "--use_existing_db" "100M_3"
    test_tor $1 overwrite $NUM_100M 1 0 1 "--use_existing_db" "100M_4"
    test_tor $1 overwrite $NUM_100M 1 0 1 "--use_existing_db" "100M_5"
    test_tor $1 readwhilewriting $NUM_1B 16 0 1 "--use_existing_db --duration=3600" "100M_1"
    #test_tor $1 readwhilewriting $NUM_1B 16 0 1 "--use_existing_db --duration=3600" "1B_2"
    #test_tor $1 readwhilewriting $NUM_1B 16 0 1 "--use_existing_db --duration=3600" "1B_3"
    test_tor $1 readrandomwriterandom $NUM_1B 16 0 1 "--use_existing_db --duration=3600 --readwritepercent=50" "100M_1"
    #test_tor $1 readrandomwriterandom $NUM_1B 16 0 1 "--use_existing_db --duration=3600 --readwritepercent=50" "1B_2"
    #test_tor $1 readrandomwriterandom $NUM_1B 16 0 1 "--use_existing_db --duration=3600 --readwritepercent=50" "1B_3"
}

test_cns_dev(){
    #test_cns $1 fillseq $NUM_10M 1 1 0 "10M" 
    #test_cns $1 overwrite $NUM_10M 1 0 0 "--use_existing_db" "10M_1"
    #test_cns $1 overwrite $NUM_10M 1 0 0 "--use_existing_db" "10M_2"

    #test_cns $1 fillseq $NUM_100M 1 1 0 "readran" 
    #test_cns $1 readwhilewriting $NUM_1M 16 0 0 "--use_existing_db" "seq"
    #test_cns $1 readrandom $NUM_10M 16 0 0 "--use_existing_db" "readran"
    test_cns $1 fillseq $NUM_100M 1 1 0 "readseq"
    #test_cns $1 readseq $NUM_10M 1 0 0 "--use_existing_db" "test"
    #test_cns $1 readseq $NUM_10M 16 0 0 "--use_existing_db" "test"
    #test_cns $1 readrandom $NUM_10M 1 0 0 "--use_existing_db" "seq"
    #test_cns $1 readrandom $NUM_10M 16 0 0 "--use_existing_db" "seq"
}

test_tor_dev(){
    #test_tor $1 fillseq $NUM_10M 1 1 0 "10M" 
    #test_tor $1 overwrite $NUM_10M 1 0 0 "--use_existing_db" "10M_1"
    #test_tor $1 overwrite $NUM_10M 1 0 0 "--use_existing_db" "10M_2"
    
    #test_tor $1 fillseq $NUM_100M 1 1 0 "readran"
    #test_tor $1 readwhilewriting $NUM_1M 16 0 0 "--use_existing_db" "seq"
    #test_tor $1 readrandom $NUM_10M 16 0 0 "--use_existing_db" "readran"

    #test_tor $1 fillseq $NUM_10M 1 1 0 "readseq"
    test_tor $1 readseq $NUM_10M 1 0 0 "--use_existing_db" "test"
    #test_tor $1 readseq $NUM_10M 16 0 0 "--use_existing_db" "test"
    #test_tor $1 readrandom $NUM_10M 1 0 0 "--use_existing_db" "seq"
    #test_tor $1 readrandom $NUM_10M 16 0 0 "--use_existing_db" "seq"
}

test_fdp_dev(){
    # 이건 잘돌아감... 왜지? fillseq->overwrite->overwrite는 에러 발생
    #test_fdp $1 fillrandom $NUM_100M 1 1 0 "1B_test" 
    #test_fdp $1 overwrite $NUM_10M 1 0 0 "--use_existing_db" "test"
    #test_fdp $1 overwrite $NUM_10M 1 0 0 "--use_existing_db" "test"
    # 죽는지 확인해보기 > sparse file extent가 0이라고 에러발생
    #test_fdp $1 fillrandom $NUM_100M 1 1 0 "1B_test" 
    #test_fdp $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "test"
    #test_fdp $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "test"
    #test_fdp $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "test"

    test_fdp $1 fillseq $NUM_300M 1 1 0 "test" 
    #test_fdp $1 fillrandom $NUM_10M 1 0 0 "--use_existing_db" "test"
    #test_fdp $1 fillrandom $NUM_10M 1 0 0 "--use_existing_db" "test"
    #test_fdp $1 fillseq $NUM_100M 1 1 0 "1B_test" 
    #test_fdp $1 fillseq $NUM_100M 1 1 0 "1B_test" 
    test_fdp $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "test1"
    #test_fdp $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "test2"
    #test_fdp $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "test3"
    #test_fdp $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "test4"
    #test_fdp $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "test5"
    #test_fdp $1 overwrite $NUM_100M 1 0 0 "--use_existing_db" "test6"
    #test_fdp $1 overwrite $NUM_10M 1 0 0 "--use_existing_db" "test"
    #test_fdp $1 readwhilewriting $NUM_1B 16 0 0 "--use_existing_db --duration=3600" "100M_1"
    
    #test_fdp $1 fillseq $NUM_1B 1 1 0 "seq"
    #test_fdp $1 fillseq $NUM_100M 1 1 0 "readran"
    #test_fdp $1 readwhilewriting $NUM_1B 16 0 0 "--use_existing_db --duration=3600" "seq"
    #test_fdp $1 readrandom $NUM_10M 16 0 0 "--use_existing_db" "readran"
    #test_fdp $1 readrandom $NUM_1M 16 0 0 "--use_existing_db" "seq"
    #test_fdp $1 readrandom $NUM_1M 16 0 0 "--use_existing_db" "seq"
    #
    # READ TEST
    #test_fdp $1 fillseq $NUM_100M 1 1 0 "readseq"
    #test_fdp $1 readseq $NUM_100M 1 0 0 "--use_existing_db " "default"
    #test_fdp $1 readseq $NUM_100M 1 0 0 "--use_existing_db --duration=10 --initial_auto_readahead_size=16384" "init_ra_16K"
    #test_fdp $1 readseq $NUM_100M 1 0 0 "--use_existing_db --duration=10 --initial_auto_readahead_size=32768" "init_ra_32K"
    #test_fdp $1 readseq $NUM_100M 1 0 0 "--use_existing_db --duration=10 --initial_auto_readahead_size=65536" "init_ra_64K"
    #test_fdp $1 readseq $NUM_100M 1 0 0 "--use_existing_db --duration=10 --auto_readahead_size" "auto_ra" #1570MB/s
    #test_fdp $1 readseq $NUM_100M 1 0 0 "--use_existing_db --duration=10 --adaptive_readahead" "adapt_ra" #1583MB/s
    #test_fdp $1 readseq $NUM_100M 1 0 0 "--use_existing_db --duration=10 --max_auto_readahead_size=524288" "max_ra_512K"
    #test_fdp $1 readseq $NUM_100M 1 0 0 "--use_existing_db --duration=10 --max_auto_readahead_size=1048576" "max_ra_1M"
    #test_fdp $1 readseq $NUM_100M 1 0 0 "--use_existing_db --duration=10 --max_auto_readahead_size=2097152" "max_ra_2M"
    #test_fdp $1 readseq $NUM_100M 1 0 0 "--use_existing_db --duration=10 --auto_readahead_size --auto_readahead_size" "auto_adapt_ra" #1567MB/s
    #test_fdp $1 readseq $NUM_10M 16 0 0 "--use_existing_db" "test"
    #test_fdp $1 readrandom $NUM_10M 1 0 0 "--use_existing_db" "seq"
    #test_fdp $1 readrandom $NUM_10M 16 0 0 "--use_existing_db" "seq"
}

test_zns_dev(){
    test_zns $1 fillseq $NUM_10M 1 1 0 "10M" 
    test_zns $1 overwrite $NUM_10M 1 0 0 "--use_existing_db" "10M_1"
    test_zns $1 overwrite $NUM_10M 1 0 0 "--use_existing_db" "10M_2"
}

main(){
    #/home/cm/dev/fdp/util/fill.sh /dev/nvme0n2 /home/cm/cns_fill
    cp $DB_BENCH .
    #test_zns_common nvme2n2
    #test_tor_common nvme0n1
    #test_cns_common nvme0n1
    #test_fdp_common nvme0n1
    test_fdp_dev nvme0n1
    #test_tor_dev nvme0n1
    #test_cns_dev nvme0n1
    #test_zns_dev nvme2n2
}

main
