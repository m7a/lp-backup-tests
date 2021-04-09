#!/bin/sh -eu
# Ma_Sys.ma Test Runner 1.0.0, Copyright (c) 2021 Ma_Sys.ma.
# For further info send an e-mail to Ma_Sys.ma@web.de

logdir=/home/linux-fan/wd/run_tests_logs
targetroot=/media/pte5home/target
workspace=/media/backupinput/br

root="$(cd "$(dirname "$0")" && pwd)"
statdb="--db=INSECURE:linux-fan:testwort@127.0.0.1"
toolslist="borg bupstash kopia"
prefix=t6gamtests3-

malog() {
	echo "test-runner[$$] === $* :: $(date) ==="
}

dirstat_all_targets() {
	statid="$prefix$1"
	malog "dirstat-all-targets: $statid"
	for i in $toolslist; do
		dirstat2 --scan=true "$statdb" "--name=${statid}-$i-target" \
							"--src=$targetroot/$i" &
	done
	for i in $toolslist; do
		cachedir="$(grep cachem18= "run_${i}_games.sh" | \
						cut -d= -f 2- | tr -d '"')"
		j=1
		for cache in $cachedir; do
			if ! [ -d "$cache" ]; then
				continue
			fi
			dirstat2 --scan=true "$statdb" \
				"--name=${statid}-$i-cache-$j" \
				"--src=$cache" &
			j=$((j+1))
		done
		find $cachedir "$targetroot/$i" -type f | \
			parallel -m sha256sum {} | sort > \
			"$logdir/${statid}sha256sum-$i.txt" 2>&1 &
		du -sh $cachedir "$targetroot/$i" \
			> "$logdir/${statid}du-$i.txt" 2>&1 &
		ls -Rlha $cachedir "$targetroot/$i" \
			> "$logdir/${statid}lsrh-$i.txt" 2>&1 &
	done
	malog "dirstat-all-targets: wait"
	wait
	malog "dirstat-all-targets: finish"
}

[ -d "$logdir" ] || mkdir "$logdir"

if [ $# = 0 ]; then
	runid="$(date +%s)"
	malog "restarting with logging to file enabled"
	"$0" --logged "$runid" 2>&1 | tee "$logdir/${prefix}mainlog_$runid.txt"
	exit $?
fi

runid="$2"
malog "this is run id $runid with ver 3 prefix=$prefix"

for i in $toolslist; do
	malog "running initializer $i"
	/usr/bin/time "$root/run_${i}_games.sh" init
done
malog "finish initializers"

dirstat_all_targets initial

for current_input in t1 t2; do
	malog "PROCESS BACKUP $current_input"

	# process logging subshell
	(
		while sleep 1; do
			date
			ps -ao cputimes,rss,start,args
		done
	) > "$logdir/${prefix}ps-$current_input.txt" 2>&1 &
	pspid=$!

	malog "du input data size"
	/usr/bin/time du -sh "$workspace"

	for i in $toolslist; do
		malog "running tool $i"
		/usr/bin/time "$root/run_${i}_games.sh" run "$current_input" > \
				"$logdir/${prefix}$current_input-$i.txt" 2>&1
	done
	malog "finish tools"

	kill -s TERM "$pspid"
	dirstat_all_targets "$current_input"

	echo "$current_input" >> "$logdir/${prefix}finish.txt"
	malog "FINISH $current_input"
done

malog "EXIT 0 ALL TOOLS FINISHED."
