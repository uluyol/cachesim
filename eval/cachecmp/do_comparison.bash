#!/usr/bin/env bash

set -e

CONFIGS=(
	# NAME          NRECORDS/node NCACHED/node      NOPS ZFTHETA GENTYPE  LINSTEPS CHANGEN CHANGEPROB
#	stdlong               3000000       300000 300000000 0.99999 zipfian         0       0 0.0
#	std                   3000000       300000   3000000 0.99999 zipfian         0       0 0.0
#	zf-0.99               3000000       300000   3000000 0.99    zipfian         0       0 0.0
#	zf-0.8                3000000       300000   3000000 0.8     zipfian         0       0 0.0
#	cache-1_100           3000000        30000   3000000 0.99999 zipfian         0       0 0.0
#	few-records               300          100   3000000 0.99999 zipfian         0       0 0.0
#	ch-1K-1_2-sm             3000          300    300000 0.99999 changing        0    1000 0.5
#	ch-1K-1_8-sm             3000          300    300000 0.99999 changing        0    1000 0.125
#	ch-10K-1_2-sm            3000          300    300000 0.99999 changing        0   10000 0.5
#	ch-10K-1_8-sm            3000          300    300000 0.99999 changing        0   10000 0.125
#	ch-1K-1_2-lg           300000        30000    300000 0.99999 changing        0    1000 0.5
#	ch-1K-1_2-mn              300           30    300000 0.99999 changing        0    1000 0.5
#	ch-1K-1_2-bs             3000           30    300000 0.99999 changing        0    1000 0.5
#	ch-100-1_2-bs            3000           30    300000 0.99999 changing        0      10 0.5
#	ch-100-1_2-bs            3000           30    300000 0.99999 changing        0      10 0.5
#	ch-100-1_2-es            3000            3    300000 0.99999 changing        0      10 0.5
#	ch-1K-1_2-xs               30            3    300000 0.99999 changing        0    1000 0.5

	zf-300-1_10-0.1           300           30   3000000 0.1     zipfian         0       0 0.0
	zf-300-1_2-0.1            300          150   3000000 0.1     zipfian         0       0 0.0
	zf-300-9_10-0.1           300          270   3000000 0.1     zipfian         0       0 0.0
	zf-3K-1_100-0.1          3000           30   3000000 0.1     zipfian         0       0 0.0
	zf-3K-1_10-0.1           3000          300   3000000 0.1     zipfian         0       0 0.0
	zf-3K-1_2-0.1            3000         1500   3000000 0.1     zipfian         0       0 0.0
	zf-3K-9_10-0.1           3000         2700   3000000 0.1     zipfian         0       0 0.0
	zf-30K-1_100-0.1        30000          300   3000000 0.1     zipfian         0       0 0.0
	zf-30K-1_10-0.1         30000         3000   3000000 0.1     zipfian         0       0 0.0
	zf-30K-1_2-0.1          30000        15000   3000000 0.1     zipfian         0       0 0.0
	zf-30K-9_10-0.1         30000        27000   3000000 0.1     zipfian         0       0 0.0

	std-300-1_10              300           30   3000000 0.99999 zipfian         0       0 0.0
	std-300-1_2               300          150   3000000 0.99999 zipfian         0       0 0.0
	std-300-9_10              300          270   3000000 0.99999 zipfian         0       0 0.0
	std-3K-1_100             3000           30   3000000 0.99999 zipfian         0       0 0.0
	std-3K-1_10              3000          300   3000000 0.99999 zipfian         0       0 0.0
	std-3K-1_2               3000         1500   3000000 0.99999 zipfian         0       0 0.0
	std-3K-9_10              3000         2700   3000000 0.99999 zipfian         0       0 0.0
	std-30K-1_100           30000          300  30000000 0.99999 zipfian         0       0 0.0
	std-30K-1_10            30000         3000  30000000 0.99999 zipfian         0       0 0.0
	std-30K-1_2             30000        15000  30000000 0.99999 zipfian         0       0 0.0
	std-30K-9_10            30000        27000  30000000 0.99999 zipfian         0       0 0.0

	uni-300-1_10              300           30   3000000 0.99999 uniform         0       0 0.0
	uni-300-1_2               300          150   3000000 0.99999 uniform         0       0 0.0
	uni-300-9_10              300          270   3000000 0.99999 uniform         0       0 0.0
	uni-3K-1_100             3000           30   3000000 0.99999 uniform         0       0 0.0
	uni-3K-1_10              3000          300   3000000 0.99999 uniform         0       0 0.0
	uni-3K-1_2               3000         1500   3000000 0.99999 uniform         0       0 0.0
	uni-3K-9_10              3000         2700   3000000 0.99999 uniform         0       0 0.0
	uni-30K-1_100           30000          300  30000000 0.99999 uniform         0       0 0.0
	uni-30K-1_10            30000         3000  30000000 0.99999 uniform         0       0 0.0
	uni-30K-1_2             30000        15000  30000000 0.99999 uniform         0       0 0.0
	uni-30K-9_10            30000        27000  30000000 0.99999 uniform         0       0 0.0

	lin-300-1_10              300           30   3000000 0.99999 linear          0       0 0.0
	lin-300-1_2               300          150   3000000 0.99999 linear          0       0 0.0
	lin-300-9_10              300          270   3000000 0.99999 linear          0       0 0.0
	lin-3K-1_100             3000           30   3000000 0.99999 linear          0       0 0.0
	lin-3K-1_10              3000          300   3000000 0.99999 linear          0       0 0.0
	lin-3K-1_2               3000         1500   3000000 0.99999 linear          0       0 0.0
	lin-3K-9_10              3000         2700   3000000 0.99999 linear          0       0 0.0
	lin-30K-1_100           30000          300  30000000 0.99999 linear          0       0 0.0
	lin-30K-1_10            30000         3000  30000000 0.99999 linear          0       0 0.0
	lin-30K-1_2             30000        15000  30000000 0.99999 linear          0       0 0.0
	lin-30K-9_10            30000        27000  30000000 0.99999 linear          0       0 0.0

#	lst-300-1_10-2            300           30   3000000 0.99999 linstep         2       0 0.0
#	lst-300-1_2-2             300          150   3000000 0.99999 linstep         2       0 0.0
#	lst-300-9_10-2            300          270   3000000 0.99999 linstep         2       0 0.0
#	lst-3K-1_100-2           3000           30   3000000 0.99999 linstep         2       0 0.0
#	lst-3K-1_10-2            3000          300   3000000 0.99999 linstep         2       0 0.0
#	lst-3K-1_2-2             3000         1500   3000000 0.99999 linstep         2       0 0.0
#	lst-3K-9_10-2            3000         2700   3000000 0.99999 linstep         2       0 0.0
#	lst-30K-1_100-2         30000          300  30000000 0.99999 linstep         2       0 0.0
#	lst-30K-1_10-2          30000         3000  30000000 0.99999 linstep         2       0 0.0
#	lst-30K-1_2-2           30000        15000  30000000 0.99999 linstep         2       0 0.0
#	lst-30K-9_10-2          30000        27000  30000000 0.99999 linstep         2       0 0.0
	
	lst-300-1_10-3            300           30   3000000 0.99999 linstep         3       0 0.0
	lst-300-1_2-3             300          150   3000000 0.99999 linstep         3       0 0.0
	lst-300-9_10-3            300          270   3000000 0.99999 linstep         3       0 0.0
	lst-3K-1_100-3           3000           30   3000000 0.99999 linstep         3       0 0.0
	lst-3K-1_10-3            3000          300   3000000 0.99999 linstep         3       0 0.0
	lst-3K-1_2-3             3000         1500   3000000 0.99999 linstep         3       0 0.0
	lst-3K-9_10-3            3000         2700   3000000 0.99999 linstep         3       0 0.0
	lst-30K-1_100-3         30000          300  30000000 0.99999 linstep         3       0 0.0
	lst-30K-1_10-3          30000         3000  30000000 0.99999 linstep         3       0 0.0
	lst-30K-1_2-3           30000        15000  30000000 0.99999 linstep         3       0 0.0
	lst-30K-9_10-3          30000        27000  30000000 0.99999 linstep         3       0 0.0

	lst-300-1_10-5            300           30   3000000 0.99999 linstep         5       0 0.0
	lst-300-1_2-5             300          150   3000000 0.99999 linstep         5       0 0.0
	lst-300-9_10-5            300          270   3000000 0.99999 linstep         5       0 0.0
	lst-3K-1_100-5           3000           30   3000000 0.99999 linstep         5       0 0.0
	lst-3K-1_10-5            3000          300   3000000 0.99999 linstep         5       0 0.0
	lst-3K-1_2-5             3000         1500   3000000 0.99999 linstep         5       0 0.0
	lst-3K-9_10-5            3000         2700   3000000 0.99999 linstep         5       0 0.0
	lst-30K-1_100-5         30000          300  30000000 0.99999 linstep         5       0 0.0
	lst-30K-1_10-5          30000         3000  30000000 0.99999 linstep         5       0 0.0
	lst-30K-1_2-5           30000        15000  30000000 0.99999 linstep         5       0 0.0
	lst-30K-9_10-5          30000        27000  30000000 0.99999 linstep         5       0 0.0

	zfs-300-1_10-59-0.2       300           30   3000000 0.99999 zfswitch        0       0 0.2
	zfs-300-1_2-59-0.2        300          150   3000000 0.99999 zfswitch        0       0 0.2
	zfs-300-9_10-59-0.2       300          270   3000000 0.99999 zfswitch        0       0 0.2
	zfs-3K-1_100-59-0.2      3000           30   3000000 0.99999 zfswitch        0       0 0.2
	zfs-3K-1_10-59-0.2       3000          300   3000000 0.99999 zfswitch        0       0 0.2
	zfs-3K-1_2-59-0.2        3000         1500   3000000 0.99999 zfswitch        0       0 0.2
	zfs-3K-9_10-59-0.2       3000         2700   3000000 0.99999 zfswitch        0       0 0.2
	zfs-30K-1_100-59-0.2    30000          300   3000000 0.99999 zfswitch        0       0 0.2
	zfs-30K-1_10-59-0.2     30000         3000   3000000 0.99999 zfswitch        0       0 0.2
	zfs-30K-1_2-59-0.2      30000        15000   3000000 0.99999 zfswitch        0       0 0.2
	zfs-30K-9_10-59-0.2     30000        27000   3000000 0.99999 zfswitch        0       0 0.2

	zfs-300-1_10-59-0.01      300           30   3000000 0.99999 zfswitch        0       0 0.01
	zfs-300-1_2-59-0.01       300          150   3000000 0.99999 zfswitch        0       0 0.01
	zfs-300-9_10-59-0.01      300          270   3000000 0.99999 zfswitch        0       0 0.01
	zfs-3K-1_100-59-0.01     3000           30   3000000 0.99999 zfswitch        0       0 0.01
	zfs-3K-1_10-59-0.01      3000          300   3000000 0.99999 zfswitch        0       0 0.01
	zfs-3K-1_2-59-0.01       3000         1500   3000000 0.99999 zfswitch        0       0 0.01
	zfs-3K-9_10-59-0.01      3000         2700   3000000 0.99999 zfswitch        0       0 0.01
	zfs-30K-1_100-59-0.01   30000          300   3000000 0.99999 zfswitch        0       0 0.01
	zfs-30K-1_10-59-0.01    30000         3000   3000000 0.99999 zfswitch        0       0 0.01
	zfs-30K-1_2-59-0.01     30000        15000   3000000 0.99999 zfswitch        0       0 0.01
	zfs-30K-9_10-59-0.01    30000        27000   3000000 0.99999 zfswitch        0       0 0.01

	zfs-300-1_10-59-0.0001    300           30   3000000 0.99999 zfswitch        0       0 0.0001
	zfs-300-1_2-59-0.0001     300          150   3000000 0.99999 zfswitch        0       0 0.0001
	zfs-300-9_10-59-0.0001    300          270   3000000 0.99999 zfswitch        0       0 0.0001
	zfs-3K-1_100-59-0.0001   3000           30   3000000 0.99999 zfswitch        0       0 0.0001
	zfs-3K-1_10-59-0.0001    3000          300   3000000 0.99999 zfswitch        0       0 0.0001
	zfs-3K-1_2-59-0.0001     3000         1500   3000000 0.99999 zfswitch        0       0 0.0001
	zfs-3K-9_10-59-0.0001    3000         2700   3000000 0.99999 zfswitch        0       0 0.0001
	zfs-30K-1_100-59-0.0001 30000          300   3000000 0.99999 zfswitch        0       0 0.0001
	zfs-30K-1_10-59-0.0001  30000         3000   3000000 0.99999 zfswitch        0       0 0.0001
	zfs-30K-1_2-59-0.0001   30000        15000   3000000 0.99999 zfswitch        0       0 0.0001
	zfs-30K-9_10-59-0.0001  30000        27000   3000000 0.99999 zfswitch        0       0 0.0001

#	szf-300-1_10-59           300           30   3000000 0.99999 skzipfian       0       0 0
#	szf-300-1_2-59            300          150   3000000 0.99999 skzipfian       0       0 0
#	szf-300-9_10-59           300          270   3000000 0.99999 skzipfian       0       0 0
#	szf-3K-1_100-59          3000           30   3000000 0.99999 skzipfian       0       0 0
#	szf-3K-1_10-59           3000          300   3000000 0.99999 skzipfian       0       0 0
#	szf-3K-1_2-59            3000         1500   3000000 0.99999 skzipfian       0       0 0
#	szf-3K-9_10-59           3000         2700   3000000 0.99999 skzipfian       0       0 0
#	szf-30K-1_100-59        30000          300   3000000 0.99999 skzipfian       0       0 0
#	szf-30K-1_10-59         30000         3000   3000000 0.99999 skzipfian       0       0 0
#	szf-30K-1_2-59          30000        15000   3000000 0.99999 skzipfian       0       0 0
#	szf-30K-9_10-59         30000        27000   3000000 0.99999 skzipfian       0       0 0
)

CACHE_TYPES="cassandra localHashed global"

NODE_COUNTS_SMALL=(8 16 32 64 128)
NODE_COUNTS_BIG=(256)
#NODE_COUNTS_BIG=(64 128 256 512 1024 2048)

_REMOTE_NODES=()

TOPDIR="${0%/*}/../.."

. "$TOPDIR/vendor/concurrent/concurrent.lib.sh"

_run_small() {
	local pids=()
	local cache_type
	for cache_type in $CACHE_TYPES; do
		_run_big "$cache_type" "$@" &
		pids+=($!)
	done

	local p
	for p in "${pids[@]}"; do
		wait $p
	done
}

_run_big() {
	local cache_type=$1; shift
	local outdir=$1; shift
	local nnodes=$1; shift
	local remote=$1; shift

	local name=$1; shift
	local nrecs_pernode=$1; shift
	local ncached_pernode=$1; shift
	local nops=$1; shift
	local zfth=$1; shift
	local gentype=$1; shift
	local linsteps=$1; shift
	local chn=$1; shift
	local chprob=$1; shift

	local nrecs=$((nnodes * nrecs_pernode))
	local ncached=$((nnodes * ncached_pernode))

	echo "# run $name $nnodes $cache_type" >&2
	out=$(
		ssh "$remote" "\
			./notswissbench \
				lru-hitrate \
					--cache-size $ncached \
					--records $nrecs \
					--zftheta $zfth \
					--ops $nops \
					--node-count $nnodes \
					--cache-type $cache_type \
					--generator $gentype \
					--changing-prob $chprob \
					--changing-n $chn \
					--steps $linsteps"
	)
	echo "$out" | awk "/^HitRate:/ { printf \"%s,%d,%s\\n\", \"$cache_type\", $nnodes, \$3; }" \
		>>"$outdir/comparison.config-$name.csv"
	echo "$out" >"$outdir/raw.config-$name.$cache_type.$nnodes.txt"
}

main() {
	if [[ $# -lt 2 ]]; then
		echo usage: run.bash outdir node [node...] >&2
		return 12
	fi
	local outdir=$1
	shift
	_REMOTE_NODES+=("$@")

	push_notswissbench

	mkdir -p "$outdir" || true

	local c_args=()
	local i
	local nn
	local ct
	local cfg_params=()
	local num_jobs=0
	for ((i=0; i < ${#CONFIGS[@]}; i+=9)); do
		cfg_params=(
			"${CONFIGS[i+0]}"
			"${CONFIGS[i+1]}"
			"${CONFIGS[i+2]}"
			"${CONFIGS[i+3]}"
			"${CONFIGS[i+4]}"
			"${CONFIGS[i+5]}"
			"${CONFIGS[i+6]}"
			"${CONFIGS[i+7]}"
			"${CONFIGS[i+8]}"
		)
		for nn in ${NODE_COUNTS_SMALL[@]}; do
			pick_remote_node
			c_args+=(
				+ "${CONFIGS[i+0]} $nn all" _run_small "$outdir" "$nn" "$USE_REMOTE_NODE" "${cfg_params[@]}"
			)
			num_jobs=$((num_jobs+1))
		done
		for nn in ${NODE_COUNTS_BIG[@]}; do
			for ct in $CACHE_TYPES; do
				pick_remote_node
				c_args+=(
					+ "${CONFIGS[i+0]} $nn $ct" _run_big "$ct" "$outdir" "$nn" "$USE_REMOTE_NODE" "${cfg_params[@]}"
				)
				num_jobs=$((num_jobs+1))
			done
		done
 	done

	echo "# will start $num_jobs jobs" >&2
	CONCURRENT_LIMIT=${#_REMOTE_NODES[@]} concurrent "${c_args[@]}"
}

push_notswissbench() {
	local n
	local pids
	for n in "${_REMOTE_NODES[@]}"; do
		echo "# push notswissbench to $n" >&2
		(
			scp -qC "$TOPDIR/bin/notswissbench_linux_amd64" "$n:notswissbench.$$" && \
			ssh "$n" "mv notswissbench.$$ notswissbench"
		) &
		pids+=($!)
	done

	local p
	for p in ${pids[@]}; do
		wait $p
	done
}

_REMOTE_NODES_POS=0
USE_REMOTE_NODE=""
pick_remote_node() {
	# assign work in round robin fashion
	USE_REMOTE_NODE=${_REMOTE_NODES[_REMOTE_NODES_POS]}
	_REMOTE_NODES_POS=$(( (_REMOTE_NODES_POS+1) % ${#_REMOTE_NODES[@]} ))
}

main "$@"
exit $?
