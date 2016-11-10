#!/usr/bin/env Rscript

library(ggplot2)

args <- commandArgs(trailingOnly=TRUE)

if (length(args) < 2) {
	stop("usage: plot.R out.pdf data.csv", call.=FALSE)
}

output_pdf <- args[1]
data_path <- args[2]

data <- read.csv(file=data_path, header=FALSE)
colnames(data) <- c("Policy", "NumServers", "HitRate")

pdf(output_pdf, height=3, width=6)
ggplot(data, aes(x=NumServers, y=HitRate, group=Policy, color=Policy, linetype=Policy, shape=Policy)) +
	geom_line() +
	geom_point() +
	scale_x_continuous(trans="log2", breaks=c(8,16,32,64,128,256,512,1024,2048), limits=c(8, 2048)) +
	xlab("Number of Servers") +
	ylab("Hit Rate")
.junk <- dev.off()
