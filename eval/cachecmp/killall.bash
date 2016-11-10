#!/usr/bin/env bash

for n in $@; do
	ssh $n killall notswissbench
done

