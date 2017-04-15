#!/usr/bin/env bash

BINDIR=${0%/*}

TOPDIR=$BINDIR/../../..
NSB=$TOPDIR/bin/notswissbench.bash

if [[ $# -lt 1 ]]; then
	echo "usage: histplot.bash output.pdf [notswissbench hist args]" >&2
	exit 2
fi

pdfout=$1
shift

theta=0
args=("$@")
is_theta=no
for ((i=0; i < ${#args[@]}; i++)); do
	if [[ $is_theta == yes ]]; then
		theta=${args[i]}
		break
	fi
	if [[ ${args[i]} == "--zftheta" ]]; then
		is_theta=yes
	fi
done

zfcheckout="${pdfout%/*}/zfchk-${pdfout##*/}"

"$NSB" hist "$@" \
	| "$BINDIR/plothist.R" "$pdfout" "$zfcheckout" "$theta" \
	| tee "$pdfout.stdout"

for ps in ${PIPESTATUS[@]}; do
	if [[ $ps -ne 0 ]]; then
		exit 1
	fi
done

echo "$0 $pdfout $@" >"$pdfout.gencmd"

