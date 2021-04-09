#!/bin/sh -eu
# Script to Enter Backup Test Chroot 1.0.0, Copyright (c) 2021 Ma_Sys.ma.
# For further info send an e-mail to Ma_Sys.ma@web.de.

root="$(cd "$(dirname "$0")" && pwd)"

chroot=/fs/ll/chroot_backuptests
inputs=/fs/e01/normal/source_or_raw/backup_test_data_sets

cd "$chroot"
exec systemd-nspawn --tmpfs=/var/lock \
	--bind-ro="$root:/home/linux-fan/wd/automation" \
	--bind-ro="$inputs:/media/backup_test_data_sets" \
	"$@"
