#!/bin/sh -eu
# Script to Enter Backup Test Chroot 1.0.0, Copyright (c) 2021 Ma_Sys.ma.
# For further info send an e-mail to Ma_Sys.ma@web.de.

root="$(cd "$(dirname "$0")" && pwd)"

chroot=/fs/ll/chroot_backuptests

cd "$chroot"
exec systemd-nspawn --tmpfs=/var/lock \
	--bind-ro="$root:/home/linux-fan/wd/automation" \
	--bind-ro="/fs/e01/imp/playonlinux:/media/backupinput/br" \
	"$@"
