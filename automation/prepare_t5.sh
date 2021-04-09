#!/bin/sh -exu

mount -t 9p -o trans=virtio,version=9p2000.L /media/backup_test_data_sets \
						/media/backup_test_data_sets
mount -t 9p -o trans=virtio,version=9p2000.L /home/linux-fan/automation \
						/home/linux-fan/automation
modprobe brd rd_nr=1 rd_size=52428800
mkfs.ext4 -O ^has_journal -L "rambackt" /dev/ram0
mount -o noatime /dev/ram0 /media/backupinput
mkdir /media/backupinput/br
chown linux-fan:linux-fan /media/backupinput/br
date -s "2017-04-04 11:11:11"
