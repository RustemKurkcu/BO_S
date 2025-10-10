suppressWarnings(suppressMessages({library(grDevices)}))
has <- function(p) requireNamespace(p, quietly=TRUE)
args <- commandArgs(trailingOnly=TRUE); opt <- list()
if (length(args)>0){for(i in seq(1,length(args),2)){k<-gsub("^--","",args[i]); v<-if(i+1<=length(args)) args[i+1] else ""; opt[[k]]<-v}}

counts_path <- opt[["counts"]]
meta_path   <- opt[["meta"]]
outdir      <- if(!is.null(opt[["outdir"]])) opt[["outdir"]] else "results/figures/main"
prefix      <- if(!is.null(opt[["prefix"]])) opt[["prefix"]] else format(Sys.time(), "%Y%m%d_acf")
topN        <- if(!is.null(opt[["topN"]])) as.integer(opt[["topN"]]) else 30
comp_filt   <- if(!is.null(opt[["compartment"]])) opt[["compartment"]] else ""

dir.create(outdir, recursive=TRUE, showWarnings=FALSE)
dir.create("results/tables", recursive=TRUE, showWarnings=FALSE)

read_csv <- function(p){
  x <- read.csv(p, check.names=FALSE, stringsAsFactors=FALSE)
  if(ncol(x)>1 && !is.numeric(x[[1]])){rn <- x[[1]]; x <- x[,-1,drop=FALSE]; rownames(x) <- rn}
  x
}

counts <- read_csv(counts_path)
counts[] <- lapply(counts, function(v) suppressWarnings(as.numeric(v)))
counts <- as.matrix(counts)

meta <- read.csv(meta_path, stringsAsFactors=FALSE, check.names=FALSE)
if(!"sample"%in%names(meta)) stop("metadata must contain 'sample'")
if(!"condition"%in%names(meta)) meta$condition <- "Unknown"
if(!"compartment"%in%names(meta)) meta$compartment <- "Unknown"
rownames(meta) <- meta$sample

# align to metadata
keep <- intersect(colnames(counts), rownames(meta))
counts <- counts[, keep, drop=FALSE]
meta   <- meta[keep, , drop=FALSE]

# optional compartment filter
if(nchar(comp_filt)>0){
  meta   <- subset(meta, compartment==comp_filt)
  keep   <- intersect(colnames(counts), rownames(meta))
  counts <- counts[, keep, drop=FALSE]
  meta   <- meta[keep, , drop=FALSE]
}

# guard: need >=3 samples
if(ncol(counts) < 3){ stop("Fewer than 3 samples after filtering.") }

# drop zero-SD genes BEFORE scaling/PCA
g_sd <- apply(counts, 1, sd, na.rm=TRUE)
counts <- counts[g_sd > 0 & is.finite(g_sd), , drop=FALSE]

# PCA matrix: per-gene z-score; replace non-finite with 0
X <- t(scale(t(counts), center=TRUE, scale=TRUE))
X[!is.finite(X)] <- 0

pc <- prcomp(t(X), center=FALSE, scale.=FALSE)
varp <- round(summary(pc)$importance[2,1:2]*100,1)

# Okabe-Ito colors for condition
cond_levels <- unique(meta$condition)
okabe <- c("#D55E00","#0072B2","#009E73","#E69F00","#56B4E9","#CC79A7","#000000","#F0E442")
cond_map <- setNames(rep(okabe, length.out=length(cond_levels)), cond_levels)

pdf(file.path(outdir, paste0(prefix, if(nchar(comp_filt)>0) paste0("_",comp_filt), "_PCA_samples.pdf")), width=6.6, height=5.2)
if (has("ggplot2")) {
  suppressPackageStartupMessages({library(ggplot2); if(has("ggrepel")) library(ggrepel)})
  df <- data.frame(PC1=pc$x[,1], PC2=pc$x[,2], condition=meta$condition, compartment=meta$compartment, sample=rownames(pc$x))
  p <- ggplot(df, aes(PC1,PC2,color=condition,shape=compartment))+
       geom_point(size=2.6, alpha=0.95)+
       scale_color_manual(values=cond_map, drop=FALSE)+
       labs(title="ACF normalized – PCA", x=paste0("PC1 (",varp[1],"%)"), y=paste0("PC2 (",varp[2],"%)"), color="Condition", shape="Compartment")+
       theme_minimal(base_size=11)+theme(plot.title=element_text(face="bold"))
  if(has("ggrepel")){d<-sqrt((df$PC1-mean(df$PC1))^2+(df$PC2-mean(df$PC2))^2); lab<-order(d,decreasing=TRUE)[1:min(3,nrow(df))]; p<-p+ggrepel::geom_text_repel(data=df[lab,], aes(label=sample), size=3)}
  print(p)
} else {
  plot(pc$x[,1], pc$x[,2], col=cond_map[as.character(meta$condition)], pch=as.numeric(as.factor(meta$compartment))+14,
       xlab=paste0("PC1 (",varp[1],"%)"), ylab=paste0("PC2 (",varp[2],"%)"), main="ACF normalized – PCA"); grid()
}
dev.off()

# Heatmap: top variable genes
rowvar <- apply(counts,1,var,na.rm=TRUE)
topN   <- min(topN, sum(is.finite(rowvar)))
if (topN >= 2) {
  keepg <- names(sort(rowvar,decreasing=TRUE))[seq_len(topN)]
  H <- counts[keepg,,drop=FALSE]
  H <- t(scale(t(H))); H[!is.finite(H)] <- 0
  pdf(file.path(outdir, paste0(prefix, if(nchar(comp_filt)>0) paste0("_",comp_filt), "_Heatmap_topVarGenes.pdf")), width=7.5, height=9)
  if(has("pheatmap") && nrow(H)>1 && ncol(H)>1){
    suppressPackageStartupMessages(library(pheatmap))
    ann <- data.frame(Condition=meta$condition, Compartment=meta$compartment); rownames(ann) <- rownames(meta)
    vir <- colorRampPalette(hcl.colors(255, "Viridis"))(255)
    pheatmap(H, color=vir, show_rownames=TRUE, show_colnames=TRUE, fontsize=9,
             annotation_col=ann, clustering_method="complete", border_color=NA,
             main=paste0("Top ", nrow(H), " variable genes (scaled)", if(nchar(comp_filt)>0) paste0(" – ",comp_filt)))
  } else {
    heatmap(H, Colv=TRUE, scale="none", margins=c(7,7), main=paste("Top", nrow(H), "variable genes"))
  }
  dev.off()
}

# Save PC scores + runlog
pc_scores <- data.frame(sample=rownames(pc$x), pc$x[,1:5,drop=FALSE], condition=meta$condition, compartment=meta$compartment)
write.csv(pc_scores, file.path("results/tables", paste0(prefix, if(nchar(comp_filt)>0) paste0("_",comp_filt), "_PCA_scores.csv")), row.names=FALSE)

sink(file.path(outdir, paste0(prefix, if(nchar(comp_filt)>0) paste0("_",comp_filt), "_runlog.txt")))
cat("Counts:", counts_path, "\n")
cat("Samples:", ncol(counts), " Genes:", nrow(counts), "\n")
cat("Autogenerated metadata: FALSE\n")
print(table(meta$condition, useNA="ifany"))
print(table(meta$compartment, useNA="ifany"))
sink()