#!/usr/bin/env Rscript

library(ggplot2)

args <- commandArgs(trailingOnly=TRUE)

if (length(args) < 3) {
	stop("need output pdf, zfchk pdf, and theta value", call.=FALSE)
}

output_pdf <- args[1]
zfchk_pdf <- args[2]
theta <- as.numeric(args[3])

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

if (zfchk_pdf != "none") {
	idx.pairs <- nrow(hits)-combn(40, 2)+1
	num <- hits$Hits[idx.pairs[2,]] / hits$Hits[idx.pairs[1,]]
	denom <- hits$Key[idx.pairs[1,]] / hits$Key[idx.pairs[2,]]
	denom <- denom^theta
	cmp <- data.frame(x=num/denom)
	cat(sprintf("draw %s\n", zfchk_pdf))
	pdf(zfchk_pdf, height=5, width=8)
	print(ggplot(cmp, aes(x=x)) + stat_ecdf())
	.junk <- dev.off()
}

cat("calculate %iles\n")
keyCount25 <- -1
keyCount50 <- -1
keyCount75 <- -1
keyCount80 <- -1
keyCount90 <- -1
keyCount99 <- -1
sofar <- 0
for (i in nrow(hits):1) {
	sofar <- sofar + hits[i, 2]
	r <- sofar / totalCount
	kc <- nrow(hits) - (i-1)
	#cat(sprintf("total: %f sofar: %f r: %f\n", totalCount, sofar, r))
	if (r >= 0.25 && keyCount25 < 0) {
		keyCount25 <- kc
	}
	if (r >= 0.5 && keyCount50 < 0) {
		keyCount50 <- kc
	}
	if (r >= 0.75 && keyCount75 < 0) {
		keyCount75 <- kc
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

cat(sprintf("%f%% of keys hold 25%% of values\n", 100*keyCount25/nrow(hits)))
cat(sprintf("%f%% of keys hold 50%% of values\n", 100*keyCount50/nrow(hits)))
cat(sprintf("%f%% of keys hold 75%% of values\n", 100*keyCount75/nrow(hits)))
cat(sprintf("%f%% of keys hold 80%% of values\n", 100*keyCount80/nrow(hits)))
cat(sprintf("%f%% of keys hold 90%% of values\n", 100*keyCount90/nrow(hits)))
cat(sprintf("%f%% of keys hold 99%% of values\n", 100*keyCount99/nrow(hits)))
