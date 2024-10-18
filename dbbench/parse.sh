#!/bin/bash

nvme_parse() {
    python3 /home/cm/dev/fdp/util/parse_nvme.py "$@" > /dev/null
}

nvme_stat() {
    python3 /home/cm/dev/fdp/util/stats_nvme.py "$@"
}

DIRECTORY='./result/fillrandomTRACE_100M_CNS/'
TYPE='cns'
echo $DIRECTORY$TYPE
nvme_parse -i $DIRECTORY$TYPE.trace -o $DIRECTORY$TYPE.parse
nvme_stat -i $DIRECTORY$TYPE.parse -o $DIRECTORY$TYPE.png

DIRECTORY='./result/fillrandomTRACE_100M_FDP/'
TYPE='fdp'
echo $DIRECTORY$TYPE
nvme_parse -i $DIRECTORY$TYPE.trace -o $DIRECTORY$TYPE.parse
nvme_stat -i $DIRECTORY$TYPE.parse -o $DIRECTORY$TYPE.png

DIRECTORY='./result/fillrandomTRACE_100M_ZNS/'
TYPE='zns'
echo $DIRECTORY$TYPE
nvme_parse -i $DIRECTORY$TYPE.trace -o $DIRECTORY$TYPE.parse
nvme_stat -i $DIRECTORY$TYPE.parse -o $DIRECTORY$TYPE.png
