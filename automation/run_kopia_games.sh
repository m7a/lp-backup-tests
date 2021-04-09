#!/bin/sh -exu
# Ma_Sys.ma Script to run Kopia 1.0.0, Copyright (c) 2021 Ma_Sys.ma.
# For further info send an e-mail to Ma_Sys.ma@web.de.

cache=/home/linux-fan/target/kopia_aux
cachem18="/home/linux-fan/target/kopia_aux /media/pte5home/.config/kopia /media/pte5home/.cache/kopia"
keyfile=/home/linux-fan/wd/id_ed25519
srcdir=/media/backupinput/br
password=testwort

# Kopia writes to two separate locations under $HOME.
# Bend this back into a single directory to simplify processing.
export XDG_CONFIG_HOME="$cache/config"
export XDG_CACHE_HOME="$cache/cache"

export KOPIA_CHECK_FOR_UPDATES=false

case "$1" in
(init)
	rm -r $cachem18 /media/pte5home/target/kopia || true
	mkdir -p "$cache/cache" "$cache/config" /media/pte5home/target/kopia
	kopia repository create \
		sftp "--path=/home/linux-fan/target/kopia" \
		--host 192.168.4.2 --port 2092 \
		--username=linux-fan "--password=$password" \
		"--keyfile=$keyfile"
	kopia "--password=$password" repository connect \
		sftp "--path=/home/linux-fan/target/kopia" \
		--host 192.168.4.2 --port 2092 \
		--username=linux-fan "--keyfile=$keyfile"
	kopia policy set \
		--keep-latest=1 --keep-hourly=0 --keep-daily=0 \
		--keep-weekly=0 --keep-monthly=0 --keep-annual=0 \
		--compression=zstd --clear-dot-ignore \
		--ignore-cache-dirs=false global
	;;
(run)
	kopia "--password=$password" snapshot create "$srcdir"
	oldsnapshots="$(kopia snapshot list | grep -oE 'k[0-9a-f]+' | \
								head -n -1)"
	if [ -n "$oldsnapshots" ]; then
		# shellcheck disable=SC2086
		echo Explicitly deleting non-latest snapshots $oldsnapshots...
		# shellcheck disable=SC2086
		kopia snapshot delete --delete $oldsnapshots
	fi

	# do not work for our test scenario anyways
	# kopia snapshot expire --delete # seems to do nothing?
	# kopia maintenance run "--password=$password" --full
	;;
(*)
	echo "Unknown option: $1. Try init or run."
	exit 1
	;;
esac
