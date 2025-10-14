# ACF Project - Directory Guide

**Last Updated**: 2025-10-14 18:37:43

## Repository Structure

This document provides an overview of the repository organization.

### data/

- **processed/**
  - **acf/**
    - **dge/**
    - **gsea/**
    - **normalized/**
    - **pca/**
- **raw/**
  - **acf/**
    - **metadata/**
    - **sequencing/**

### src/

- **analysis/**
  - `acf_pubplots.R` (6.0 KB)
  - `acf_run_all.R` (6.0 KB)
- **preprocessing/**
- **utils/**
- **visualization/**

### scripts/

- `export_for_jmp.R` (909.0 B)
- `run_acf.ps1` (1.6 KB)
- `run_all.ps1` (3.5 KB)
- `run_all.ps1.bak` (7.8 KB)
- `smoke_test.ps1` (4.8 KB)

### tools/

- `generate_docs.py` (7.9 KB)

### results/

- **figures/**
  - **exploratory/**
  - **main/**
    - `20251010_acf_Epithelial_Heatmap_topVarGenes.pdf` (12.2 KB)
    - `20251010_acf_Epithelial_PCA_samples.pdf` (6.2 KB)
    - `20251010_acf_Epithelial_runlog.txt` (1.3 KB)
    - `20251010_acf_Heatmap_topVarGenes.pdf` (12.1 KB)
    - `20251010_acf_Heatmap_topVarGenes.png` (4.2 KB)
    - `20251010_acf_PCA_samples.pdf` (6.2 KB)
    - `20251010_acf_PCA_samples.png` (2.5 KB)
    - `20251010_acf_epi_Heatmap_topVarGenes.pdf` (20.1 KB)
    - `20251010_acf_epi_PCA_samples.pdf` (6.2 KB)
    - `20251010_acf_epi_runlog.txt` (184.0 B)
    - `20251010_acf_runlog.txt` (1.3 KB)
    - `20251014_acf_fig2_pca.pdf` (7.2 KB)
    - `20251014_acf_fig3_heatmap.pdf` (13.2 KB)
  - **supplementary/**
- **reports/**
- **tables/**
  - **10-10-run/**
    - `20251010_acf_Epithelial_PCA_scores.csv` (2.4 KB)
    - `20251010_acf_PCA_scores.csv` (2.4 KB)
    - `20251010_acf_epi_PCA_scores.csv` (2.4 KB)

### manuscripts/

- **acf_paper/**
  - **drafts/**
  - **figures/**
  - **submission/**
  - **supplementary/**
  - **tables/**

### docs/

- **literature/**
- **meeting_notes/**
- **methods/**
- `dataset_catalog.csv` (17.3 KB)
- `decisions.md` (158.0 B)
- `directory_guide.md` (1.9 KB)
- `figure_map.csv` (2.2 KB)
- `file-manifest.csv` (940.7 KB)
- `gene_metadata.csv` (31.5 KB)
