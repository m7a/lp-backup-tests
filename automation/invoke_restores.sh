#!/bin/sh -eu
# Ma_Sys.ma Test Runner 1.0.0, Copyright (c) 2021 Ma_Sys.ma.
# For further info send an e-mail to Ma_Sys.ma@web.de

logdir=/home/linux-fan/wd/run_tests_logs
workspace=/media/backupinput/br

root="$(cd "$(dirname "$0")" && pwd)"

#toolslist="borg bupstash jmbb kopia"
toolslist="borg jmbb kopia"
prefix=t2-restore-

malog() { echo "test-runner[$$] === $* :: $(date) ==="; }

[ -d "$logdir" ] || mkdir "$logdir"

if [ $# = 0 ]; then
	runid="$(date +%s)"
	malog "restarting with logging to file enabled"
	"$0" --logged "$runid" 2>&1 | tee "$logdir/${prefix}mainlog_$runid.txt"
	exit $?
fi

runid="$2"
malog "this is RESTORE run id $runid with ver 3 prefix=$prefix"

finish="$logdir/${prefix}finish.txt"

# process logging subshell
(
	while sleep 1; do
		date
		ps -ao cputimes,rss,start,args
	done
) > "$logdir/${prefix}ps-restore.txt" 2>&1 &
pspid=$!

for i in $toolslist; do
	if grep -qF "$i" "$finish"; then
		malog "SKIP $i already processed."
		continue
	fi

	malog "clear working directory"
	for j in "$workspace"/*; do
		if [ -e "$j" ]; then
			chown linux-fan:linux-fan -R "$j"
			chmod 777 -R "$j"
			rm -r "$j"
		fi
	done

	malog "running tool $i"
	/usr/bin/time "$root/run_$i.sh" restore \
				> "$logdir/${prefix}restore-$i.txt" 2>&1

	malog "collecting checksums"
	find "$workspace" -type f | \
			parallel -m sha256sum {} | sort > \
			"$logdir/${prefix}restore-sha256sum-$i.txt" 2>&1

	echo "$i" >> "$finish"
done

kill -s TERM "$pspid"
malog "EXIT 0 finish tools"
