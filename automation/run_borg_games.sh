#!/bin/sh -eu
# Ma_Sys.ma Scirpt to run Borg 1.0.0, Copyright (c) 2021 Ma_Sys.ma.
# For further info send an e-mail to Ma_Sys.ma@web.de.

cachem18=/home/linux-fan/.cache/borg
srcdir=/media/backupinput/br
export BORG_REPO=/media/pte5home/target/borg
export BORG_PASSPHRASE=testwort

case "$1" in
(init)
	rm -r "$cachem18" "$BORG_REPO" || true
	mkdir -p "$BORG_REPO"
	exec borg init --encryption repokey
	;;
(run)
	borg create --stats --progress --compression lzma,8 \
					"::masysma-benchmark-{utcnow}" "$srcdir"
	borg prune --keep-last 1
	;;
(*)
	echo Unknown option: $1. Try init or run.
	exit 1
	;;
esac
