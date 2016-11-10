#!/usr/bin/env Rscript

library(ggplot2)

args <- commandArgs(trailingOnly=T)

if (length(args) < 2) {
	stop("usage: plotmany_single.R output.pdf in.csv", call.=F)
}

output_pdf <- args[1]
input_csv <- args[2]
x_axis_lab <- args[3]

data <- read.csv(file=input_csv, header=F)
colnames(data) <- c("ReqPct", "X", "Value")

pdf(output_pdf, height=5, width=8)
ggplot(data, aes(x=X, y=Value, color=ReqPct)) +
	geom_line() +
	xlab(x_axis_lab)
.junk <- dev.off()
