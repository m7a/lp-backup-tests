#!/bin/sh -e
# Ma_Sys.ma Script to run bupstash 1.0.0, Copyright (c) 2021 Ma_Sys.ma.
# For further info send an e-mail to Ma_Sys.ma@web.de.

cache=/home/linux-fan/.cache/bupstash
target=/home/linux-fan/target/bupstash

[ -n "$BUPSTASH_REPOSITORY" ] || BUPSTASH_REPOSITORY="$target"

export BUPSTASH_REPOSITORY
export BUPSTASH_KEY=/home/linux-fan/target/bupstash-key.dat
srcdir=/media/backupinput/br

case "$1" in
(init)
	rm -r "$cache" "$target" "$BUPSTASH_KEY" 2> /dev/null || true
	# bupstash likes to create its target directory itself!
	mkdir -p "$(dirname "$target")"
	bupstash new-key -o "$BUPSTASH_KEY"
	bupstash init
	;;
(run)
	bupstash put hostname=masysma-18-chroot "$srcdir"
	backups="$(bupstash list hostname=masysma-18-chroot)"
	if [ "$(echo "$backups" | wc -l)" = 2 ]; then
		id_to_delete="$(echo "$backups" | head -n 1 | tr ' ' '\n' | \
						grep -E '^id=' | tr -d '"')"
		bupstash rm "$id_to_delete"
		bupstash gc
	else
		echo NOTICE: Not performing backup deletion due to neq 2 \
			entries. This should occur for the first backup only.
	fi
	;;
(restore)
	bupstash get name=br.tar | tar \
		--delay-directory-restore --numeric-owner -C "$srcdir" -x
	;;
(*)
	echo Unknown option: $1. Try init or run.
	exit 1
	;;
esac
