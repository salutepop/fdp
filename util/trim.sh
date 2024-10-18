#(usage) ./trim.sh nvme1n1
DEV=$1
sudo fio --name=trim --filename=/dev/$DEV --rw=trim --bs=3G

