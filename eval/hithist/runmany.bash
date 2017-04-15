#!/usr/bin/env bash

set -e

cd ${0%/*}

TOPDIR=$PWD/../..
. "$TOPDIR/vendor/concurrent/concurrent.lib.sh"

if [[ $# -lt 1 ]]; then
	echo "usage: ./runmany.bash outdir" >&2
	exit 2
fi

CONFIGS=(
	# records       ops
#	      300        30
#	      300       300
#	      300      3000
#	      300     30000
	      300    300000
#	     3000       300
#	     3000      3000
#	     3000     30000
	     3000    300000
#	   300000     30000
#	   300000    300000
#	   300000   3000000
#	  3000000    300000
#	  3000000   3000000
#	  3000000  30000000
#	 30000000   3000000
#	 30000000  30000000
#	 30000000 300000000
)

THETA=(
	0.1
	0.3
	0.5
	0.7
	0.9
	0.99
	0.999
	0.99999
	0.99999999
	0.99999999999
	0.999999999999
)

outdir=$1

mkdir -p $outdir || true

run_single() {
	local nr=$1
	local no=$2
	local theta=$3
	./cmd/histplot.bash "$outdir/nr-${nr}_no-${no}_th-${theta}.pdf" \
		--records $nr --ops $no --zftheta $theta \
		>"$outdir/nr-${nr}_no-${no}_th-${theta}.txt"
}

c_args=()

for ((i=0; i < ${#CONFIGS[@]}; i+=2)); do
	nr=${CONFIGS[i]}
	no=${CONFIGS[i+1]}
	for theta in ${THETA[@]}; do
		c_args+=(
			+
			"records=$nr ops=$no θ=$theta"
			run_single $nr $no $theta
		)
	done
done

CONCURRENT_LIMIT=4 concurrent "${c_args[@]}"
