
.PHONY: build build-regular build-custom

ifdef GOPATH
	build = regular
else
	build = custom
endif

build: build-$(build)

build-regular:
	GOOS=darwin GOARCH=amd64 go build -o bin/notswissbench_darwin_amd64 github.com/uluyol/cachesim/cmd/notswissbench
	GOOS=linux GOARCH=amd64 go build -o bin/notswissbench_linux_amd64 github.com/uluyol/cachesim/cmd/notswissbench

build-custom:
	rm -rf /tmp/cachesim-build
	mkdir -p /tmp/cachesim-build/src/github.com/uluyol/
	cp -R . /tmp/cachesim-build/src/github.com/uluyol/cachesim
	GOPATH=/tmp/cachesim-build GOOS=darwin GOARCH=amd64 go build -o bin/notswissbench_darwin_amd64 github.com/uluyol/cachesim/cmd/notswissbench
	GOPATH=/tmp/cachesim-build GOOS=linux GOARCH=amd64 go build -o bin/notswissbench_linux_amd64 github.com/uluyol/cachesim/cmd/notswissbench
	rm -rf /tmp/cachesim-build
