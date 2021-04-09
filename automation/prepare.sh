#!/bin/sh -exu

docker start ma-d-postgres-dirstat-backup-test-large
modprobe brd rd_nr=1 rd_size=52428800
mkfs.ext4 -O ^has_journal -L "rambackt" /dev/ram0
mount -o noatime /dev/ram0 /fs/ll/chroot_backuptests/media/backupinput
mkdir /fs/ll/chroot_backuptests/media/backupinput/br
chown linux-fan:linux-fan /fs/ll/chroot_backuptests/media/backupinput/br
