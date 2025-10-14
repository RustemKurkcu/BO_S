suppressPackageStartupMessages({ library(optparse); library(readr); library(dplyr); library(tidyr) })
opt <- parse_args(OptionParser(option_list=list(
  make_option("--counts"), make_option("--meta"),
  make_option("--out",    default="results/tables"),
  make_option("--prefix", default="run")
)))
dir.create(opt$out, showWarnings=FALSE, recursive=TRUE)

X <- read_csv(opt$counts)      # genes x samples (first col = gene)
M <- read_csv(opt$meta)

gene_col <- names(X)[1]
genes    <- X[[gene_col]]
X[[gene_col]] <- NULL

# Ensure unique out subdir per run
outdir <- file.path(opt$out, opt$prefix)
dir.create(outdir, showWarnings=FALSE, recursive=TRUE)

# Wide (gene rows, sample cols)
write_csv(cbind(Gene=genes, X), file.path(outdir, paste0(opt$prefix, "_counts_wide.csv")))
# Long (sample, gene, value)
long <- pivot_longer(cbind(data.frame(Gene=genes), as.data.frame(X)),
                     -Gene, names_to="Sample", values_to="Expression")
write_csv(long, file.path(outdir, paste0(opt$prefix, "_counts_long.csv")))
# Metadata (as-is)
write_csv(M,    file.path(outdir, paste0(opt$prefix, "_metadata.csv")))

cat("Wrote JMP tables to ", outdir, "\n", sep="")