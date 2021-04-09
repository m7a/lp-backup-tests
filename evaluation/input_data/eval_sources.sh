#!/bin/sh -eu
# Ma_Sys.ma Script to evaluate Changes in Input Data 1.0.0,
# Copyright (c) 2021 Ma_Sys.ma.
# For further info send an e-mail to Ma_Sys.ma@web.de

backups="x2a00 x2a4c x2aaf x2af8 x2b81 x2bcb x2c15 x2c80 x2ccb x2d17 x2d6b x2dbf x2e0c x2e57 x2eb4 x2efd x3001 x30da x312a x31a3 x31ec x323b x3288 x32e1 x3333 x338a x33d5 x3436 x3483 x34d7"

[ -d tmp ] || mkdir tmp

prev=
for i in $backups; do
	if [ -n "$prev" ]; then
		./eval_changes.php "$prev" "$i" > "tmp/$prev-$i.csv" 2>&1 &
	fi
	prev="$i"
done

wait
