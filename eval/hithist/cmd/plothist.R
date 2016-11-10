#!/usr/bin/env Rscript

library(ggplot2)

# list with amortized append implementation
# written by JanKanis on
# https://stackoverflow.com/questions/2436688/append-an-object-to-a-list-in-r-in-amortized-constant-time-o1/32870310#32870310

expandingList <- function(capacity = 10) {
	buffer <- vector('list', capacity)
	length <- 0

	methods <- list()

	methods$double.size <- function() {
		buffer <<- c(buffer, vector('list', capacity))
		capacity <<- capacity * 2
	}

	methods$add <- function(val) {
		if(length == capacity) {
			methods$double.size()
		}

		length <<- length + 1
		buffer[[length]] <<- val
	}

	methods$as.list <- function() {
		b <- buffer[0:length]
		return(b)
	}

	methods
}

# end of list implementation

args <- commandArgs(trailingOnly=TRUE)

if (length(args) < 1) {
	stop("output pdf must be supplied", call.=FALSE)
}

output_pdf <- args[1]

hits <- read.csv(file="stdin", header=FALSE)
colnames(hits) <- c("Key", "Hits")

cat("renumber keys\n")
totalCount <- 0
hits$Key <- nrow(hits):1
totalCount <- sum(hits$Hits)

if (output_pdf != "none") {
	smpl <- hits
	if (nrow(hits) > 12000) {
		allThresh <- nrow(hits)-1000
		idx <- c(allThresh:nrow(hits), sample(allThresh, 10000))
		smpl <- hits[idx,]
	}
	cat(sprintf("draw %s\n", output_pdf))
	pdf(output_pdf, height=5, width=8)
	print(ggplot(smpl, aes(x=Key, y=Hits)) +
		geom_line() +
		ylim(c(0, NA))) #+
		#scale_x_log10() +
		#scale_y_continuous(breaks=c(0, 10, 100, 1000), trans='log1p'))
	.junk <- dev.off()
}

cat("calculate %iles\n")
keyCount50 <- -1
keyCount80 <- -1
keyCount90 <- -1
keyCount99 <- -1
sofar <- 0
for (i in nrow(hits):1) {
	sofar <- sofar + hits[i, 2]
	r <- sofar / totalCount
	kc <- nrow(hits) - (i-1)
	#cat(sprintf("total: %f sofar: %f r: %f\n", totalCount, sofar, r))
	if (r >= 0.5 && keyCount50 < 0) {
		keyCount50 <- kc
	}
	if (r >= 0.8 && keyCount80 < 0) {
		keyCount80 <- kc
	}
	if (r >= 0.9 && keyCount90 < 0) {
		keyCount90 <- kc
	}
	if (r >= 0.99 && keyCount99 < 0) {
		keyCount99 <- kc
		break
	}
}

cat(sprintf("%f%% of keys hold 50%% of values\n", 100*keyCount50/nrow(hits)))
cat(sprintf("%f%% of keys hold 80%% of values\n", 100*keyCount80/nrow(hits)))
cat(sprintf("%f%% of keys hold 90%% of values\n", 100*keyCount90/nrow(hits)))
cat(sprintf("%f%% of keys hold 99%% of values\n", 100*keyCount99/nrow(hits)))
