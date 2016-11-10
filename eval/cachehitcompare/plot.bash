#!/usr/bin/env bash

CDIR=${0%/*}
TOPDIR=$CDIR/../..
. "$TOPDIR/vendor/concurrent/concurrent.lib.sh"

set -e

# job_limit borrowed from
# http://stackoverflow.com/questions/1537956/bash-limit-the-number-of-concurrent-jobs
job_limit() {
	# Test for single positive integer input
	if (( $# == 1 )) && [[ $1 =~ ^[1-9][0-9]*$ ]]; then
		# Check number of running jobs
		joblist=($(jobs -rp))
		while (( ${#joblist[*]} >= $1 )); do
			# Wait for any job to finish
			command='wait '${joblist[0]}
			for job in ${joblist[@]:1}; do
				command+=' || wait '$job
			done
			eval $command
			joblist=($(jobs -rp))
		done
   fi
}

plot_raw() {
	local dest_pre=$1
	local txt=$2
	local raw=$(<"$txt")
	local probs=($(echo "$raw" | awk '/^CumProbs/ {print $2}' | tr , ' '))
	"$CDIR/cmd/process_raw.py" "$txt" \
		| "$CDIR/cmd/single_plot.R" "$dest_pre"
}

plot_cmp() {
	local dest_pre=$1
	local localHashed_txt=$2
	local global_txt=${localHashed_txt//localHashed/global}
	if [[ ! -f "$global_txt" ]]; then
		echo "warn: skipping $localHashed_txt: $global_txt not found" >&2
	fi
	"$CDIR/cmd/process_cmp.py" "$localHashed_txt" "$global_txt" \
		| "$CDIR/cmd/single_plot.R" "$dest_pre"
}

tdir=.
if [[ $# -eq 1 ]]; then
	tdir="$1"
fi

for input_csv in "$tdir"/comparison.config-*.csv; do
	cfg=${input_csv#$tdir/comparison.config-}
	cfg=${cfg%.csv}
	dest_graph=$tdir/graph.config-${cfg}.pdf
	if [[ -f $input_csv ]]; then
		echo "# plot $input_csv" >&2
		"$CDIR/cmd/plot.R" "$dest_graph" "$input_csv" &
	else
		if [[ -f $dest_graph ]]; then
			echo warn: $dest_graph is out of date >&2
		fi
	fi
	job_limit 10
done

for input_txt in "$tdir"/raw.config-*30K*localHashed*.txt; do
	exact_cfg=${input_txt#$tdir/raw.config-}
	exact_cfg=${exact_cfg%.txt}
	dest=$tdir/graph.raw-${exact_cfg}
	dest_cmp=$tdir/graph.rawcmp-$exact_cfg
	echo "# plot $input_txt" >&2
	plot_raw "$dest" "$input_txt" &
	job_limit 10
	echo "# plot cmp $input_txt" >&2
	plot_cmp "$dest_cmp" "$input_txt" &
	job_limit 10
done
