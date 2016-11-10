#!/usr/bin/env bash

if [[ `uname` == Darwin ]]; then
	exec "${0%/*}/notswissbench_darwin_amd64" "$@"
else
	exec "${0%/*}/notswissbench_linux_amd64" "$@"
fi
