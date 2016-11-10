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

"$NSB" hist "$@" \
	| "$BINDIR/plothist.R" "$pdfout" \
	| tee "$pdfout.stdout"

echo "$0 $pdfout $@" >"$pdfout.gencmd"

