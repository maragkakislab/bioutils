#!/usr/bin/env Rscript

upper_quartile <- function(x) {
	return (quantile(x, probs=c(0.75), type=1)[[1]])
}

col_upper_quartile <- function(x) {
	y = subset(x, colSums(x) > 0)
	return(apply(y, 2, upper_quartile))
}

divide_matrix_rows_by_vector <- function(x, uqs) {
	return(t(t(x) / uqs))
}

library(optparse)
library(reshape2)

# Read command line options and arguments
option_list <- list(
	make_option(
		c("-a", "--ifile"), type="character",
		help="Input table. Reads from STDIN if \"-\". Default: -", metavar="File", default = "-"),
	make_option(
		c("-b", "--sample-col"), type="character",
		help="Name of column with sample names. Default: sample", default="sample"),
	make_option(
		c("-c", "--key-col"), type="character",
		help="Name of column with keys per sample. Default: key", default="key"),
	make_option(
		c("-d", "--value-col"), type="character",
		help="Name of column with values. Default: value", default="value"),
	make_option(
		c("-e", "--out-wide"), type="character",
		help="Optional output file for wide format", metavar="File", default="")
)
opt = parse_args(OptionParser(option_list = option_list))

sample = opt$`sample-col`
key = opt$`key-col`
val = opt$`value-col`
outwide = opt$`out-wide`

# Read data
if (opt$ifile == "-") {
	df = read.delim(file('stdin'))
} else {
	df = read.delim(opt$ifile)
}

# Convert long to wide format
formu = as.formula(paste(key, "~", sample))
dfc = dcast(df, formu, value.var = val)

# Replace missing values with 0
dfc[is.na(dfc)] <- 0

# Get the upper quartiles per sample
uqs = col_upper_quartile(dfc[,-1])

# Normalize
dfc.norm = divide_matrix_rows_by_vector(dfc[,-1], uqs)
dfc[,-1] <- dfc.norm

# Output the wide format if asked
if (outwide != "") {
	write.table(dfc, outwide, quote = FALSE, sep = "\t", row.names = FALSE)
}

# Convert wide to long format
df.norm = melt(dfc, id.vars=c(key), variable.name = sample, value.name = paste(val, "norm", sep="."))

df.merged = merge(df, df.norm)
write.table(df.merged, stdout(), quote = FALSE, sep = "\t", row.names = FALSE)
