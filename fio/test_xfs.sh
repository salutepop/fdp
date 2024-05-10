DEVICE=$1
RUNTIME=30

RW='read'
CHUNK='4k'
sudo fio --name=psync_$RW'_'$CHUNK --filename=$DEVICE --bs=$CHUNK --ioengine=psync --rw=$RW --time_based --runtime=$RUNTIME --direct=1 --output-format=normal,terse
sudo fio --name=uring_$RW'_'$CHUNK'_qd1' --filename=$DEVICE --bs=$CHUNK --ioengine=io_uring --rw=$RW --time_based --runtime=$RUNTIME --iodepth=1 --output-format=normal,terse
sudo fio --name=uring_$RW'_'$CHUNK'_qd32' --filename=$DEVICE --bs=$CHUNK --ioengine=io_uring --rw=$RW --time_based --runtime=$RUNTIME --iodepth=32 --output-format=normal,terse

RW='read'
CHUNK='16k'
sudo fio --name=psync_$RW'_'$CHUNK --filename=$DEVICE --bs=$CHUNK --ioengine=psync --rw=$RW --time_based --runtime=$RUNTIME --direct=1 --output-format=normal,terse
sudo fio --name=uring_$RW'_'$CHUNK'_qd1' --filename=$DEVICE --bs=$CHUNK --ioengine=io_uring --rw=$RW --time_based --runtime=$RUNTIME --iodepth=1 --output-format=normal,terse
sudo fio --name=uring_$RW'_'$CHUNK'_qd32' --filename=$DEVICE --bs=$CHUNK --ioengine=io_uring --rw=$RW --time_based --runtime=$RUNTIME --iodepth=32 --output-format=normal,terse

RW='read'
CHUNK='64k'
sudo fio --name=psync_$RW'_'$CHUNK --filename=$DEVICE --bs=$CHUNK --ioengine=psync --rw=$RW --time_based --runtime=$RUNTIME --direct=1 --output-format=normal,terse
sudo fio --name=uring_$RW'_'$CHUNK'_qd1' --filename=$DEVICE --bs=$CHUNK --ioengine=io_uring --rw=$RW --time_based --runtime=$RUNTIME --iodepth=1 --output-format=normal,terse
sudo fio --name=uring_$RW'_'$CHUNK'_qd32' --filename=$DEVICE --bs=$CHUNK --ioengine=io_uring --rw=$RW --time_based --runtime=$RUNTIME --iodepth=32 --output-format=normal,terse

RW='read'
CHUNK='256k'
sudo fio --name=psync_$RW'_'$CHUNK --filename=$DEVICE --bs=$CHUNK --ioengine=psync --rw=$RW --time_based --runtime=$RUNTIME --direct=1 --output-format=normal,terse
sudo fio --name=uring_$RW'_'$CHUNK'_qd1' --filename=$DEVICE --bs=$CHUNK --ioengine=io_uring --rw=$RW --time_based --runtime=$RUNTIME --iodepth=1 --output-format=normal,terse
sudo fio --name=uring_$RW'_'$CHUNK'_qd32' --filename=$DEVICE --bs=$CHUNK --ioengine=io_uring --rw=$RW --time_based --runtime=$RUNTIME --iodepth=32 --output-format=normal,terse

RW='write'
CHUNK='4k'
sudo fio --name=psync_$RW'_'$CHUNK --filename=$DEVICE --bs=$CHUNK --ioengine=psync --rw=$RW --time_based --runtime=$RUNTIME --direct=1 --output-format=normal,terse
sudo fio --name=uring_$RW'_'$CHUNK'_qd1' --filename=$DEVICE --bs=$CHUNK --ioengine=io_uring --rw=$RW --time_based --runtime=$RUNTIME --iodepth=1 --output-format=normal,terse
sudo fio --name=uring_$RW'_'$CHUNK'_qd32' --filename=$DEVICE --bs=$CHUNK --ioengine=io_uring --rw=$RW --time_based --runtime=$RUNTIME --iodepth=32 --output-format=normal,terse

RW='write'
CHUNK='16k'
sudo fio --name=psync_$RW'_'$CHUNK --filename=$DEVICE --bs=$CHUNK --ioengine=psync --rw=$RW --time_based --runtime=$RUNTIME --direct=1 --output-format=normal,terse
sudo fio --name=uring_$RW'_'$CHUNK'_qd1' --filename=$DEVICE --bs=$CHUNK --ioengine=io_uring --rw=$RW --time_based --runtime=$RUNTIME --iodepth=1 --output-format=normal,terse
sudo fio --name=uring_$RW'_'$CHUNK'_qd32' --filename=$DEVICE --bs=$CHUNK --ioengine=io_uring --rw=$RW --time_based --runtime=$RUNTIME --iodepth=32 --output-format=normal,terse

RW='write'
CHUNK='64k'
sudo fio --name=psync_$RW'_'$CHUNK --filename=$DEVICE --bs=$CHUNK --ioengine=psync --rw=$RW --time_based --runtime=$RUNTIME --direct=1 --output-format=normal,terse
sudo fio --name=uring_$RW'_'$CHUNK'_qd1' --filename=$DEVICE --bs=$CHUNK --ioengine=io_uring --rw=$RW --time_based --runtime=$RUNTIME --iodepth=1 --output-format=normal,terse
sudo fio --name=uring_$RW'_'$CHUNK'_qd32' --filename=$DEVICE --bs=$CHUNK --ioengine=io_uring --rw=$RW --time_based --runtime=$RUNTIME --iodepth=32 --output-format=normal,terse

RW='write'
CHUNK='256k'
sudo fio --name=psync_$RW'_'$CHUNK --filename=$DEVICE --bs=$CHUNK --ioengine=psync --rw=$RW --time_based --runtime=$RUNTIME --direct=1 --output-format=normal,terse
sudo fio --name=uring_$RW'_'$CHUNK'_qd1' --filename=$DEVICE --bs=$CHUNK --ioengine=io_uring --rw=$RW --time_based --runtime=$RUNTIME --iodepth=1 --output-format=normal,terse
sudo fio --name=uring_$RW'_'$CHUNK'_qd32' --filename=$DEVICE --bs=$CHUNK --ioengine=io_uring --rw=$RW --time_based --runtime=$RUNTIME --iodepth=32 --output-format=normal,terse

RW='randread'
CHUNK='4k'
sudo fio --name=psync_$RW'_'$CHUNK --filename=$DEVICE --bs=$CHUNK --ioengine=psync --rw=$RW --time_based --runtime=$RUNTIME --direct=1 --output-format=normal,terse
sudo fio --name=uring_$RW'_'$CHUNK'_qd1' --filename=$DEVICE --bs=$CHUNK --ioengine=io_uring --rw=$RW --time_based --runtime=$RUNTIME --iodepth=1 --output-format=normal,terse
sudo fio --name=uring_$RW'_'$CHUNK'_qd32' --filename=$DEVICE --bs=$CHUNK --ioengine=io_uring --rw=$RW --time_based --runtime=$RUNTIME --iodepth=32 --output-format=normal,terse

RW='randread'
CHUNK='16k'
sudo fio --name=psync_$RW'_'$CHUNK --filename=$DEVICE --bs=$CHUNK --ioengine=psync --rw=$RW --time_based --runtime=$RUNTIME --direct=1 --output-format=normal,terse
sudo fio --name=uring_$RW'_'$CHUNK'_qd1' --filename=$DEVICE --bs=$CHUNK --ioengine=io_uring --rw=$RW --time_based --runtime=$RUNTIME --iodepth=1 --output-format=normal,terse
sudo fio --name=uring_$RW'_'$CHUNK'_qd32' --filename=$DEVICE --bs=$CHUNK --ioengine=io_uring --rw=$RW --time_based --runtime=$RUNTIME --iodepth=32 --output-format=normal,terse

RW='randread'
CHUNK='64k'
sudo fio --name=psync_$RW'_'$CHUNK --filename=$DEVICE --bs=$CHUNK --ioengine=psync --rw=$RW --time_based --runtime=$RUNTIME --direct=1 --output-format=normal,terse
sudo fio --name=uring_$RW'_'$CHUNK'_qd1' --filename=$DEVICE --bs=$CHUNK --ioengine=io_uring --rw=$RW --time_based --runtime=$RUNTIME --iodepth=1 --output-format=normal,terse
sudo fio --name=uring_$RW'_'$CHUNK'_qd32' --filename=$DEVICE --bs=$CHUNK --ioengine=io_uring --rw=$RW --time_based --runtime=$RUNTIME --iodepth=32 --output-format=normal,terse

RW='randread'
CHUNK='256k'
sudo fio --name=psync_$RW'_'$CHUNK --filename=$DEVICE --bs=$CHUNK --ioengine=psync --rw=$RW --time_based --runtime=$RUNTIME --direct=1 --output-format=normal,terse
sudo fio --name=uring_$RW'_'$CHUNK'_qd1' --filename=$DEVICE --bs=$CHUNK --ioengine=io_uring --rw=$RW --time_based --runtime=$RUNTIME --iodepth=1 --output-format=normal,terse
sudo fio --name=uring_$RW'_'$CHUNK'_qd32' --filename=$DEVICE --bs=$CHUNK --ioengine=io_uring --rw=$RW --time_based --runtime=$RUNTIME --iodepth=32 --output-format=normal,terse

RW='randwrite'
CHUNK='4k'
sudo fio --name=psync_$RW'_'$CHUNK --filename=$DEVICE --bs=$CHUNK --ioengine=psync --rw=$RW --time_based --runtime=$RUNTIME --direct=1 --output-format=normal,terse
sudo fio --name=uring_$RW'_'$CHUNK'_qd1' --filename=$DEVICE --bs=$CHUNK --ioengine=io_uring --rw=$RW --time_based --runtime=$RUNTIME --iodepth=1 --output-format=normal,terse
sudo fio --name=uring_$RW'_'$CHUNK'_qd32' --filename=$DEVICE --bs=$CHUNK --ioengine=io_uring --rw=$RW --time_based --runtime=$RUNTIME --iodepth=32 --output-format=normal,terse

RW='randwrite'
CHUNK='16k'
sudo fio --name=psync_$RW'_'$CHUNK --filename=$DEVICE --bs=$CHUNK --ioengine=psync --rw=$RW --time_based --runtime=$RUNTIME --direct=1 --output-format=normal,terse
sudo fio --name=uring_$RW'_'$CHUNK'_qd1' --filename=$DEVICE --bs=$CHUNK --ioengine=io_uring --rw=$RW --time_based --runtime=$RUNTIME --iodepth=1 --output-format=normal,terse
sudo fio --name=uring_$RW'_'$CHUNK'_qd32' --filename=$DEVICE --bs=$CHUNK --ioengine=io_uring --rw=$RW --time_based --runtime=$RUNTIME --iodepth=32 --output-format=normal,terse

RW='randwrite'
CHUNK='64k'
sudo fio --name=psync_$RW'_'$CHUNK --filename=$DEVICE --bs=$CHUNK --ioengine=psync --rw=$RW --time_based --runtime=$RUNTIME --direct=1 --output-format=normal,terse
sudo fio --name=uring_$RW'_'$CHUNK'_qd1' --filename=$DEVICE --bs=$CHUNK --ioengine=io_uring --rw=$RW --time_based --runtime=$RUNTIME --iodepth=1 --output-format=normal,terse
sudo fio --name=uring_$RW'_'$CHUNK'_qd32' --filename=$DEVICE --bs=$CHUNK --ioengine=io_uring --rw=$RW --time_based --runtime=$RUNTIME --iodepth=32 --output-format=normal,terse

RW='randwrite'
CHUNK='256k'
sudo fio --name=psync_$RW'_'$CHUNK --filename=$DEVICE --bs=$CHUNK --ioengine=psync --rw=$RW --time_based --runtime=$RUNTIME --direct=1 --output-format=normal,terse
sudo fio --name=uring_$RW'_'$CHUNK'_qd1' --filename=$DEVICE --bs=$CHUNK --ioengine=io_uring --rw=$RW --time_based --runtime=$RUNTIME --iodepth=1 --output-format=normal,terse
sudo fio --name=uring_$RW'_'$CHUNK'_qd32' --filename=$DEVICE --bs=$CHUNK --ioengine=io_uring --rw=$RW --time_based --runtime=$RUNTIME --iodepth=32 --output-format=normal,terse

# [io_uring_cmd]
sudo umount /dev/nvme0n1

RW='read'
CHUNK='4k'
sudo fio --name=uring_cmd_$RW'_'$CHUNK'_qd1' --filename=/dev/ng0n1 --bs=$CHUNK --ioengine=io_uring_cmd --rw=$RW --time_based --runtime=$RUNTIME --iodepth=1 --output-format=normal,terse
sudo fio --name=uring_cmd_$RW'_'$CHUNK'_qd32' --filename=/dev/ng0n1 --bs=$CHUNK --ioengine=io_uring_cmd --rw=$RW --time_based --runtime=$RUNTIME --iodepth=32 --output-format=normal,terse

RW='read'
CHUNK='16k'
sudo fio --name=uring_cmd_$RW'_'$CHUNK'_qd1' --filename=/dev/ng0n1 --bs=$CHUNK --ioengine=io_uring_cmd --rw=$RW --time_based --runtime=$RUNTIME --iodepth=1 --output-format=normal,terse
sudo fio --name=uring_cmd_$RW'_'$CHUNK'_qd32' --filename=/dev/ng0n1 --bs=$CHUNK --ioengine=io_uring_cmd --rw=$RW --time_based --runtime=$RUNTIME --iodepth=32 --output-format=normal,terse

RW='read'
CHUNK='64k'
sudo fio --name=uring_cmd_$RW'_'$CHUNK'_qd1' --filename=/dev/ng0n1 --bs=$CHUNK --ioengine=io_uring_cmd --rw=$RW --time_based --runtime=$RUNTIME --iodepth=1 --output-format=normal,terse
sudo fio --name=uring_cmd_$RW'_'$CHUNK'_qd32' --filename=/dev/ng0n1 --bs=$CHUNK --ioengine=io_uring_cmd --rw=$RW --time_based --runtime=$RUNTIME --iodepth=32 --output-format=normal,terse

RW='read'
CHUNK='256k'
sudo fio --name=uring_cmd_$RW'_'$CHUNK'_qd1' --filename=/dev/ng0n1 --bs=$CHUNK --ioengine=io_uring_cmd --rw=$RW --time_based --runtime=$RUNTIME --iodepth=1 --output-format=normal,terse
sudo fio --name=uring_cmd_$RW'_'$CHUNK'_qd32' --filename=/dev/ng0n1 --bs=$CHUNK --ioengine=io_uring_cmd --rw=$RW --time_based --runtime=$RUNTIME --iodepth=32 --output-format=normal,terse

RW='write'
CHUNK='4k'
sudo fio --name=uring_cmd_$RW'_'$CHUNK'_qd1' --filename=/dev/ng0n1 --bs=$CHUNK --ioengine=io_uring_cmd --rw=$RW --time_based --runtime=$RUNTIME --iodepth=1 --output-format=normal,terse
sudo fio --name=uring_cmd_$RW'_'$CHUNK'_qd32' --filename=/dev/ng0n1 --bs=$CHUNK --ioengine=io_uring_cmd --rw=$RW --time_based --runtime=$RUNTIME --iodepth=32 --output-format=normal,terse

RW='write'
CHUNK='16k'
sudo fio --name=uring_cmd_$RW'_'$CHUNK'_qd1' --filename=/dev/ng0n1 --bs=$CHUNK --ioengine=io_uring_cmd --rw=$RW --time_based --runtime=$RUNTIME --iodepth=1 --output-format=normal,terse
sudo fio --name=uring_cmd_$RW'_'$CHUNK'_qd32' --filename=/dev/ng0n1 --bs=$CHUNK --ioengine=io_uring_cmd --rw=$RW --time_based --runtime=$RUNTIME --iodepth=32 --output-format=normal,terse

RW='write'
CHUNK='64k'
sudo fio --name=uring_cmd_$RW'_'$CHUNK'_qd1' --filename=/dev/ng0n1 --bs=$CHUNK --ioengine=io_uring_cmd --rw=$RW --time_based --runtime=$RUNTIME --iodepth=1 --output-format=normal,terse
sudo fio --name=uring_cmd_$RW'_'$CHUNK'_qd32' --filename=/dev/ng0n1 --bs=$CHUNK --ioengine=io_uring_cmd --rw=$RW --time_based --runtime=$RUNTIME --iodepth=32 --output-format=normal,terse

RW='write'
CHUNK='256k'
sudo fio --name=uring_cmd_$RW'_'$CHUNK'_qd1' --filename=/dev/ng0n1 --bs=$CHUNK --ioengine=io_uring_cmd --rw=$RW --time_based --runtime=$RUNTIME --iodepth=1 --output-format=normal,terse
sudo fio --name=uring_cmd_$RW'_'$CHUNK'_qd32' --filename=/dev/ng0n1 --bs=$CHUNK --ioengine=io_uring_cmd --rw=$RW --time_based --runtime=$RUNTIME --iodepth=32 --output-format=normal,terse

RW='randread'
CHUNK='4k'
sudo fio --name=uring_cmd_$RW'_'$CHUNK'_qd1' --filename=/dev/ng0n1 --bs=$CHUNK --ioengine=io_uring_cmd --rw=$RW --time_based --runtime=$RUNTIME --iodepth=1 --output-format=normal,terse
sudo fio --name=uring_cmd_$RW'_'$CHUNK'_qd32' --filename=/dev/ng0n1 --bs=$CHUNK --ioengine=io_uring_cmd --rw=$RW --time_based --runtime=$RUNTIME --iodepth=32 --output-format=normal,terse

RW='randread'
CHUNK='16k'
sudo fio --name=uring_cmd_$RW'_'$CHUNK'_qd1' --filename=/dev/ng0n1 --bs=$CHUNK --ioengine=io_uring_cmd --rw=$RW --time_based --runtime=$RUNTIME --iodepth=1 --output-format=normal,terse
sudo fio --name=uring_cmd_$RW'_'$CHUNK'_qd32' --filename=/dev/ng0n1 --bs=$CHUNK --ioengine=io_uring_cmd --rw=$RW --time_based --runtime=$RUNTIME --iodepth=32 --output-format=normal,terse

RW='randread'
CHUNK='64k'
sudo fio --name=uring_cmd_$RW'_'$CHUNK'_qd1' --filename=/dev/ng0n1 --bs=$CHUNK --ioengine=io_uring_cmd --rw=$RW --time_based --runtime=$RUNTIME --iodepth=1 --output-format=normal,terse
sudo fio --name=uring_cmd_$RW'_'$CHUNK'_qd32' --filename=/dev/ng0n1 --bs=$CHUNK --ioengine=io_uring_cmd --rw=$RW --time_based --runtime=$RUNTIME --iodepth=32 --output-format=normal,terse

RW='randread'
CHUNK='256k'
sudo fio --name=uring_cmd_$RW'_'$CHUNK'_qd1' --filename=/dev/ng0n1 --bs=$CHUNK --ioengine=io_uring_cmd --rw=$RW --time_based --runtime=$RUNTIME --iodepth=1 --output-format=normal,terse
sudo fio --name=uring_cmd_$RW'_'$CHUNK'_qd32' --filename=/dev/ng0n1 --bs=$CHUNK --ioengine=io_uring_cmd --rw=$RW --time_based --runtime=$RUNTIME --iodepth=32 --output-format=normal,terse

RW='randwrite'
CHUNK='4k'
sudo fio --name=uring_cmd_$RW'_'$CHUNK'_qd1' --filename=/dev/ng0n1 --bs=$CHUNK --ioengine=io_uring_cmd --rw=$RW --time_based --runtime=$RUNTIME --iodepth=1 --output-format=normal,terse
sudo fio --name=uring_cmd_$RW'_'$CHUNK'_qd32' --filename=/dev/ng0n1 --bs=$CHUNK --ioengine=io_uring_cmd --rw=$RW --time_based --runtime=$RUNTIME --iodepth=32 --output-format=normal,terse

RW='randwrite'
CHUNK='16k'
sudo fio --name=uring_cmd_$RW'_'$CHUNK'_qd1' --filename=/dev/ng0n1 --bs=$CHUNK --ioengine=io_uring_cmd --rw=$RW --time_based --runtime=$RUNTIME --iodepth=1 --output-format=normal,terse
sudo fio --name=uring_cmd_$RW'_'$CHUNK'_qd32' --filename=/dev/ng0n1 --bs=$CHUNK --ioengine=io_uring_cmd --rw=$RW --time_based --runtime=$RUNTIME --iodepth=32 --output-format=normal,terse

RW='randwrite'
CHUNK='64k'
sudo fio --name=uring_cmd_$RW'_'$CHUNK'_qd1' --filename=/dev/ng0n1 --bs=$CHUNK --ioengine=io_uring_cmd --rw=$RW --time_based --runtime=$RUNTIME --iodepth=1 --output-format=normal,terse
sudo fio --name=uring_cmd_$RW'_'$CHUNK'_qd32' --filename=/dev/ng0n1 --bs=$CHUNK --ioengine=io_uring_cmd --rw=$RW --time_based --runtime=$RUNTIME --iodepth=32 --output-format=normal,terse

RW='randwrite'
CHUNK='256k'
sudo fio --name=uring_cmd_$RW'_'$CHUNK'_qd1' --filename=/dev/ng0n1 --bs=$CHUNK --ioengine=io_uring_cmd --rw=$RW --time_based --runtime=$RUNTIME --iodepth=1 --output-format=normal,terse
sudo fio --name=uring_cmd_$RW'_'$CHUNK'_qd32' --filename=/dev/ng0n1 --bs=$CHUNK --ioengine=io_uring_cmd --rw=$RW --time_based --runtime=$RUNTIME --iodepth=32 --output-format=normal,terse
