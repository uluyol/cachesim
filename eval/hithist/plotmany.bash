#!/usr/bin/env bash

set -e

SED=sed
if [[ $(uname) == 'Darwin' ]]; then
	SED=gsed
	if ! which gsed &>/dev/null; then
		echo please install gsed on macOS >&2
		exit 23
	fi
fi

cd ${0%/*}

if [[ $# -lt 1 ]]; then
	echo "usage: ./plotmany.bash resdir" >&2
	exit 2
fi

resdir=$1

results=("$resdir"/*.txt)

tmpdir=$(mktemp -d /tmp/plotmany.XXX)
trap "rm -rf $tmpdir" EXIT SIGQUIT SIGTERM SIGINT

for res in "${results[@]}"; do
	fields=($(echo $res | $SED -E 's|^.*/nr-([0-9]+)_no-([0-9]+)_th-([0-9.]+).txt$|\1 \2 \3|'))
	nr=${fields[0]}
	no=${fields[1]}
	no_plain=$no
	th=${fields[2]}
	p25=$(grep '25% of values$' "$res" | cut -d'%' -f1)
	p50=$(grep '50% of values$' "$res" | cut -d'%' -f1)
	p75=$(grep '75% of values$' "$res" | cut -d'%' -f1)
	p80=$(grep '80% of values$' "$res" | cut -d'%' -f1)
	p90=$(grep '90% of values$' "$res" | cut -d'%' -f1)
	p99=$(grep '99% of values$' "$res" | cut -d'%' -f1)

	if [[ -z $p25 || -z $p50 || -z $p75 || -z $p80 || -z $p90 || -z $p99 ]]; then
		echo skipping $res: incomplete >&2
		continue
	fi

	# optionally make numbers pretty using
	# https://github.com/uluyol/tools/tree/master/humannum
	if which humannum &>/dev/null; then
		nr=$(humannum $nr)
		no=$(humannum $no)
	fi

	printf "%s,$th,%s\n" 25pct $p25 50pct $p50 75pct $p75 80pct $p80 90pct $p90 99pct $p99 >>"$tmpdir/nr-${nr}_no-${no}.csv"
	printf "%s,$no_plain,%s\n" 25pct $p25 50pct $p50 75pct $p75 80pct $p80 90pct $p90 99pct $p99 >>"$tmpdir/nr-${nr}_th-${th}.csv"
done

mkdir -p "$resdir/graphs" || true

for csv in "$tmpdir"/*; do
	name=${csv##*/}
	name=${name%.csv}
	if [[ $name =~ .*_th-.* ]]; then
		echo $csv
		cat "$csv"
		./cmd/plotmany_single.R "$resdir/graphs/$name.pdf" "$csv" Operations
	else
		./cmd/plotmany_single.R "$resdir/graphs/$name.pdf" "$csv"
	fi
done
