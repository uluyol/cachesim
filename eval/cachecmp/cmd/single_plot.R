#!/usr/bin/env Rscript

library(ggplot2)

args <- commandArgs(trailingOnly=TRUE)

if (length(args) < 1) {
	stop("usage: single_plot.R out_pre", call.=FALSE)
}

out_prefix <- args[1]

data <- read.csv(file="stdin", header=FALSE)
colnames(data) <- c("Node", "Label", "Load")

prob <- data[data$Label == "CumProb",]
req <- data[data$Label == "Req",]

secprobs <- data[data$Label == "SectionCumProbs.0_3" | data$Label == "SectionCumProbs.1_3" | data$Label == "SectionCumProbs.2_3",]
secprob.0_3 <- data[data$Label == "SectionCumProbs.0_3",]
secprob.1_3 <- data[data$Label == "SectionCumProbs.1_3",]
secprob.2_3 <- data[data$Label == "SectionCumProbs.2_3",]

pdf(paste(out_prefix, ".prob.pdf", sep=""), height=3, width=6)
ggplot(prob, aes(x=Node, y=Load, fill=Label)) +
	geom_bar(stat="identity", width=0.7, position="dodge")
.junk <- dev.off()

pdf(paste(out_prefix, ".req.pdf", sep=""), height=3, width=6)
ggplot(req, aes(x=Node, y=Load, fill=Label)) +
	geom_bar(stat="identity", width=0.7, position="dodge")
.junk <- dev.off()

pdf(paste(out_prefix, ".secprob.pdf", sep=""), height=3, width=6)
ggplot(secprobs, aes(x=Node, y=Load, fill=Label)) +
	geom_bar(stat="identity", width=0.7, position="dodge")
.junk <- dev.off()

pdf(paste(out_prefix, ".sec0_3.pdf", sep=""), height=3, width=6)
ggplot(secprob.0_3, aes(x=Node, y=Load, fill=Label)) +
	geom_bar(stat="identity", width=0.7, position="dodge")
.junk <- dev.off()

pdf(paste(out_prefix, ".sec1_3.pdf", sep=""), height=3, width=6)
ggplot(secprob.1_3, aes(x=Node, y=Load, fill=Label)) +
	geom_bar(stat="identity", width=0.7, position="dodge")
.junk <- dev.off()

pdf(paste(out_prefix, ".sec2_3.pdf", sep=""), height=3, width=6)
ggplot(secprob.2_3, aes(x=Node, y=Load, fill=Label)) +
	geom_bar(stat="identity", width=0.7, position="dodge")
.junk <- dev.off()
