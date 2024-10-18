
HOME="/home/cm/dev/"
DB_BENCH=$HOME'repo/RocksDB/db_bench'
DIR_RESULT=$HOME"fdp/dbbench/result/"
AUX_PATH="/home/cm/tmp/"
TRIM_SH="/home/cm/dev/fdp/util/trim.sh"
FLEXFS="/home/cm/dev/repo/RocksDB/plugin/flexfs/util/flexfs"

# CONFIGURATION
BENCH_TYPE="fillrandom"
#BENCH_TYPE="fillseq"
NUMS="10000000"
COMMENT="_RA2M"
THREADS=16
OPTIONS=" --use_direct_io_for_flush_and_compaction --use_direct_reads --compaction_readahead_size=2097152 --readahead_size=2097152" # --statistics

test_fdp(){
    echo "DO TEST FDP"
    # BEGIN TEST #
    DEV_TYPE="//fdp:"
    DEV_NAME="nvme0n1"
    $TRIM_SH $DEV_NAME
    sudo rm -r $AUX_PATH/*
    sudo $FLEXFS mkfs --fdp_bd=$DEV_NAME --aux_path=$AUX_PATH --force
    
    sudo ./db_bench --fs_uri=zenfs:$DEV_TYPE$DEV_NAME --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS
    #echo ./db_bench --fs_uri=zenfs:$DEV_TYPE$DEV_NAME --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS
    # END TEST #
}
    
test_zns(){
    echo "DO TEST ZNS"
    # BEGIN TEST #
    DEV_TYPE="//dev:"
    DEV_NAME="nvme2n2"
    $TRIM_SH $DEV_NAME
    sudo rm -r $AUX_PATH/*
    sudo $FLEXFS mkfs --zbd=$DEV_NAME --aux_path=$AUX_PATH --force
    
    sudo ./db_bench --fs_uri=zenfs:$DEV_TYPE$DEV_NAME --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS
    #echo ./db_bench --fs_uri=zenfs:$DEV_TYPE$DEV_NAME --benchmarks=$BENCH_TYPE --num=$NUMS --threads=$THREADS $OPTIONS
    # END TEST #
}

main(){
    cp $DB_BENCH .
    test_fdp
    test_zns
}

main
