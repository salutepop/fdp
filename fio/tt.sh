DEVICE=$1
RUNTIME=30

RW='read'
CHUNK='4k'
#sudo fio --name=psync_$RW'_'$CHUNK --filename=/dev/nvme$DEVICE --bs=$CHUNK --ioengine=psync --rw=$RW --time_based --runtime=$RUNTIME --direct=1 --output-format=normal,terse
#sudo fio --name=uring_$RW'_'$CHUNK'_qd1' --filename=/dev/nvme$DEVICE --bs=$CHUNK --ioengine=io_uring --rw=$RW --time_based --runtime=$RUNTIME --iodepth=1 --output-format=normal,terse
#sudo fio --name=uring_$RW'_'$CHUNK'_qd32' --filename=/dev/nvme$DEVICE --bs=$CHUNK --ioengine=io_uring --rw=$RW --time_based --runtime=$RUNTIME --iodepth=32 --output-format=normal,terse
#sudo fio --name=uring_cmd_$RW'_'$CHUNK'_qd1' --filename=/dev/ng$DEVICE --bs=$CHUNK --ioengine=io_uring_cmd --rw=$RW --time_based --runtime=$RUNTIME --iodepth=1 --output-format=normal,terse
#sudo fio --name=uring_cmd_$RW'_'$CHUNK'_qd32' --filename=/dev/ng$DEVICE --bs=$CHUNK --ioengine=io_uring_cmd --rw=$RW --time_based --runtime=$RUNTIME --iodepth=32 --output-format=normal,terse
sudo fio --name=uring_cmd_$RW'_'$CHUNK'_qd1' --filename=/dev/ng$DEVICE --bs=$CHUNK --ioengine=io_uring_cmd --rw=$RW --size=$CHUNK --iodepth=16 --output-format=normal,terse
