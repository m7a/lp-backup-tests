#!/bin/sh -eu
# Ma_Sys.ma Test Runner 1.0.0, Copyright (c) 2021 Ma_Sys.ma.
# For further info send an e-mail to Ma_Sys.ma@web.de

backupinputs=/media/backup_test_data_sets
logdir=/home/linux-fan/wd/run_tests_logs
targetroot=/home/linux-fan/target
workspace=/media/backupinput/br

root="$(cd "$(dirname "$0")" && pwd)"
statdb="--db=INSECURE:linux-fan:testwort@127.0.0.1"
prefix=t5kopiavm3-

malog() {
	echo "test-runner[$$] === $* :: $(date) ==="
}

dirstat_all_targets() {
	statid="$prefix$1"
	malog "dirstat-all-targets: $statid"
	i=kopia
	dirstat2 --scan=true "$statdb" "--name=${statid}-$i-target" \
							"--src=$targetroot/$i" &
	cachedir="$(grep cache= "run_$i.sh" | cut -d= -f 2-)"
	if [ -d "$cachedir" ]; then
		dirstat2 --scan=true "$statdb" \
			"--name=${statid}-$i-cache" "--src=$cachedir"
	fi
	find "$cachedir" "$targetroot/$i" -type f | \
			parallel -m sha256sum {} | sort > \
			"$logdir/${statid}sha256sum-$i.txt" 2>&1 &
	du -sh "$cachedir" "$targetroot/$i" \
			> "$logdir/${statid}du-$i.txt" 2>&1 &
	ls -Rlha "$cachedir" "$targetroot/$i" \
			> "$logdir/${statid}lsrh-$i.txt" 2>&1 &
	malog "dirstat-all-targets: wait"
	wait
	malog "dirstat-all-targets: finish"
}

# $1 test to run
fake_real_time() {
	ttime="$(grep -E "^$1	" "$root/ids_to_times.tsv" | cut -f 2)"
	sudo date -s "$ttime"
}

[ -d "$logdir" ] || mkdir "$logdir"

if [ $# = 0 ]; then
	runid="$(date +%s)"
	malog "restarting with logging to file enabled"
	"$0" --logged "$runid" 2>&1 | tee "$logdir/${prefix}mainlog_$runid.txt"
	exit $?
fi

runid="$2"
malog "this is run id $runid with ver 4 prefix=$prefix"

inputs="$(find "$backupinputs" -maxdepth 1 -type f -name '*.tar' | sort)"
finish="$logdir/${prefix}finish.txt"

if [ -f "$finish" ]; then
	malog "skipping initializers, already executed"
	dirstat_all_targets "resume-$runid"
else
	i=kopia
	malog "running initializer $i"
	
	fake_real_time init
	/usr/bin/time "$root/run_$i.sh" init
	malog "finish initializers"

	dirstat_all_targets initial
fi

for current_input_file in $inputs; do
	current_input="$(echo "$current_input_file" | tr '/' '\n' | \
						tail -n 1 | cut -d. -f 1)"
	if grep -qF "$current_input" "$finish"; then
		malog "SKIP $current_input already processed."
		continue
	fi
	malog "PROCESS BACKUP $current_input"

	# process logging subshell
	(
		while sleep 1; do
			date
			ps -ao cputimes,rss,start,args
		done
	) > "$logdir/${prefix}ps-$current_input.txt" 2>&1 &
	pspid=$!

	malog "clear working directory"
	for i in "$workspace"/*; do
		if [ -e "$i" ]; then
			# multi-stage deletion routine because tar's extractions
			# cannot be directly deleted by rm -rf...
			chown linux-fan:linux-fan -R "$i"
			chmod 777 -R "$i"
			rm -r "$i"
		fi
	done

	malog "fake tar time (disable whine)"
	sudo date -s "2021-03-11 11:11:11"

	malog "prepare input data"
	tar -C "$workspace" -xf "$current_input_file"

	malog "du input data size"
	du -sh "$workspace"

	malog "kopia special fake time"
	fake_real_time "$current_input"

	i=kopia
	malog "running tool $i"
	/usr/bin/time "$root/run_$i.sh" run "$current_input" > \
				"$logdir/${prefix}$current_input-$i.txt" 2>&1
	malog "finish tools"

	kill -s TERM "$pspid"
	dirstat_all_targets "$current_input"

	echo "$current_input" >> "$logdir/${prefix}finish.txt"
	malog "FINISH $current_input"
done

malog "EXIT 0 ALL TOOLS FINISHED."
