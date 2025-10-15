#!/usr/bin/env Rscript
# ACF Analysis Pipeline - PCA + Heatmap Generation
# Usage: Rscript src/analysis/acf_run_all.R --counts <file> --meta <file> --outdir <dir> --prefix <prefix>

suppressPackageStartupMessages({
  library(optparse)
  library(readr)
  library(dplyr)
  library(tibble)
  library(ggplot2)
  library(pheatmap)
  library(scales)
  library(tidyr)
})

# Parse command line arguments
option_list <- list(
  make_option(c("--counts"), type="character", default=NULL,
              help="Path to normalized counts matrix (CSV)", metavar="FILE"),
  make_option(c("--meta"), type="character", default=NULL,
              help="Path to metadata file (CSV)", metavar="FILE"),
  make_option(c("--outdir"), type="character", default="results/figures/main",
              help="Output directory for figures [default=%default]", metavar="DIR"),
  make_option(c("--prefix"), type="character", default="acf",
              help="Prefix for output files [default=%default]", metavar="PREFIX"),
  make_option(c("--top_genes"), type="integer", default=50,
              help="Number of top variable genes for heatmap [default=%default]", metavar="N")
)

opt_parser <- OptionParser(option_list=option_list)
opt <- parse_args(opt_parser)

# Validate inputs
if (is.null(opt$counts) || is.null(opt$meta)) {
  print_help(opt_parser)
  stop("Both --counts and --meta are required.", call.=FALSE)
}

if (!file.exists(opt$counts)) {
  stop(paste("Counts file not found:", opt$counts), call.=FALSE)
}

if (!file.exists(opt$meta)) {
  stop(paste("Metadata file not found:", opt$meta), call.=FALSE)
}

# Create output directory
dir.create(opt$outdir, showWarnings=FALSE, recursive=TRUE)

cat("ACF Analysis Pipeline\n")
cat("=====================\n")
cat("Counts file:", opt$counts, "\n")
cat("Metadata file:", opt$meta, "\n")
cat("Output directory:", opt$outdir, "\n")
cat("Prefix:", opt$prefix, "\n\n")

# Load data
cat("Loading data...\n")
counts <- read_csv(opt$counts, show_col_types=FALSE)
metadata <- read_csv(opt$meta, show_col_types=FALSE)

# Assume first column is gene names/IDs
gene_col <- names(counts)[1]
genes <- counts[[gene_col]]
counts_matrix <- as.matrix(counts[, -1])
rownames(counts_matrix) <- genes

cat("Loaded", nrow(counts_matrix), "genes and", ncol(counts_matrix), "samples\n")
cat("Metadata has", nrow(metadata), "rows\n\n")

# Ensure sample names match
sample_names <- colnames(counts_matrix)
if (!all(sample_names %in% metadata[[1]])) {
  warning("Not all sample names in counts are found in metadata. Proceeding with available matches.")
}

# Match metadata to counts columns
metadata_matched <- metadata[match(sample_names, metadata[[1]]), ]

# ============================================================================
# FIGURE 2: PCA PLOT
# ============================================================================
cat("Generating PCA plot...\n")

# Transpose for PCA (samples as rows)
counts_t <- t(counts_matrix)

# Remove genes with zero variance
gene_vars <- apply(counts_matrix, 1, var, na.rm=TRUE)
counts_matrix_filtered <- counts_matrix[gene_vars > 0, ]

cat("Filtered to", nrow(counts_matrix_filtered), "genes with non-zero variance\n")

# Perform PCA
pca_result <- prcomp(t(counts_matrix_filtered), scale.=TRUE, center=TRUE)

# Extract PC scores
pca_data <- as.data.frame(pca_result$x[, 1:2])
pca_data$Sample <- rownames(pca_data)

# Add metadata
if (ncol(metadata_matched) >= 2) {
  pca_data$Group <- metadata_matched[[2]]
}
if (ncol(metadata_matched) >= 3) {
  pca_data$Compartment <- metadata_matched[[3]]
}

# Calculate variance explained
var_explained <- summary(pca_result)$importance[2, 1:2] * 100

# Create PCA plot
p_pca <- ggplot(pca_data, aes(x=PC1, y=PC2)) +
  geom_point(aes(color=Group, shape=Compartment), size=3, alpha=0.8) +
  labs(
    title="PCA of ACF Samples",
    x=paste0("PC1 (", round(var_explained[1], 1), "% variance)"),
    y=paste0("PC2 (", round(var_explained[2], 1), "% variance)")
  ) +
  theme_bw() +
  theme(
    plot.title=element_text(hjust=0.5, face="bold", size=14),
    legend.position="right",
    panel.grid.minor=element_blank()
  )

# Save PCA plot
pca_file <- file.path(opt$outdir, paste0(opt$prefix, "_fig2_pca.pdf"))
ggsave(pca_file, p_pca, width=8, height=6)
cat("Saved PCA plot to:", pca_file, "\n\n")

# ============================================================================
# FIGURE 3: HEATMAP
# ============================================================================
cat("Generating heatmap...\n")

# Select top variable genes
gene_vars_sorted <- sort(gene_vars[gene_vars > 0], decreasing=TRUE)
top_genes <- names(gene_vars_sorted)[1:min(opt$top_genes, length(gene_vars_sorted))]

counts_top <- counts_matrix_filtered[top_genes, ]

# Z-score normalization for visualization
counts_scaled <- t(scale(t(counts_top)))

# Prepare annotation
annotation_col <- data.frame(
  Group = metadata_matched[[2]],
  row.names = sample_names
)

if (ncol(metadata_matched) >= 3) {
  annotation_col$Compartment <- metadata_matched[[3]]
}

# Create heatmap
heatmap_file <- file.path(opt$outdir, paste0(opt$prefix, "_fig3_heatmap.pdf"))

pdf(heatmap_file, width=10, height=12)
pheatmap(
  counts_scaled,
  annotation_col = annotation_col,
  show_rownames = TRUE,
  show_colnames = TRUE,
  cluster_rows = TRUE,
  cluster_cols = TRUE,
  clustering_distance_rows = "correlation",
  clustering_distance_cols = "correlation",
  color = colorRampPalette(c("blue", "white", "red"))(100),
  main = paste("Top", opt$top_genes, "Variable Genes"),
  fontsize = 8,
  fontsize_row = 6,
  fontsize_col = 8
)
dev.off()

cat("Saved heatmap to:", heatmap_file, "\n\n")

# ============================================================================
# SUMMARY
# ============================================================================
cat("Analysis complete!\n")
cat("Generated files:\n")
cat("  -", pca_file, "\n")
cat("  -", heatmap_file, "\n")
cat("\nNext steps:\n")
cat("  1. Review the PCA plot for sample clustering\n")
cat("  2. Check the heatmap for gene expression patterns\n")
cat("  3. Run GSEA analysis (src/analysis/acf_gsea.R)\n")
cat("  4. Export data for JMP (scripts/export_for_jmp.R)\n")