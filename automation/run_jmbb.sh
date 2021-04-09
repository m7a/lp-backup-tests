#!/bin/sh -e
# Ma_Sys.ma Script to run JMBB 1.0.0, Copyright (c) 2021 Ma_Sys.ma.
# For further info send an e-mail to Ma_Sys.ma@web.de.

destdir=/home/linux-fan/target/jmbb
srcdir=/media/backupinput/br
password=testwort

case "$1" in
(init)
	mkdir -p "$destdir"
	rm -r "$destdir"/* || true
	echo $password | jmbb -o "$destdir" -i
	;;
(run)
	exec jmbb -o "$destdir" -i "$srcdir"
	;;
(restore)
	exec jmbb -r "$srcdir" -s "$destdir"
	;;
(*)
	echo Unknown option: $1. Try init or run.
	exit 1
	;;
esac
