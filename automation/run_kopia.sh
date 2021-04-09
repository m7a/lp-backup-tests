#!/bin/sh -exu
# Ma_Sys.ma Script to run Kopia 1.0.0, Copyright (c) 2021 Ma_Sys.ma.
# For further info send an e-mail to Ma_Sys.ma@web.de.

cache=/home/linux-fan/target/kopia_aux
destdir=/home/linux-fan/target/kopia
srcdir=/media/backupinput/br
password=testwort

# Kopia writes to two separate locations under $HOME.
# Bend this back into a single directory to simplify processing.
export XDG_CONFIG_HOME="$cache/config"
export XDG_CACHE_HOME="$cache/cache"

export KOPIA_CHECK_FOR_UPDATES=false

case "$1" in
(init)
	rm -r "$cache" "$destdir" || true
	mkdir -p "$destdir" "$cache/cache" "$cache/config"
	kopia repository create filesystem "--path=$destdir" \
							"--password=$password"
	kopia "--password=$password" repository connect \
						filesystem "--path=$destdir"
	kopia policy set \
		--keep-latest=1 --keep-hourly=0 --keep-daily=0 \
		--keep-weekly=0 --keep-monthly=0 --keep-annual=0 \
		--compression=zstd --clear-dot-ignore \
		--ignore-cache-dirs=false "$destdir"
	;;
(run)
	kopia "--password=$password" snapshot create "$srcdir"
	# regular maintenance/policy/expire does not seem to work as expected
	# attempt to force operation as wanted
	oldsnapshots="$(kopia snapshot list | grep -oE 'k[0-9a-f]+' | \
								head -n -1)"
	if [ -n "$oldsnapshots" ]; then
		# shellcheck disable=SC2086
		echo Explicitly deleting non-latest snapshots $oldsnapshots...
		# shellcheck disable=SC2086
		kopia snapshot delete --delete $oldsnapshots
	fi

	# TODO z might need `kopia snapshot expire` before?
	# kopia snapshot expire --delete # seems to do nothing?

	kopia maintenance run "--password=$password" --full
	;;
(restore)
	snapshot="$(kopia snapshot list | grep -oE 'k[0-9a-f]+' | tail -n 1)"
	echo "restore snapshot=$snapshot"
	kopia restore "$snapshot" "$srcdir"
	;;
(*)
	echo "Unknown option: $1. Try init or run."
	exit 1
	;;
esac
