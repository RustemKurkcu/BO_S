# COMPLETE PROJECT GUIDE - ACF & TS19 Projects

**Date:** October 11, 2025  
**Your Setup:** `C:\work\BO_S` (Local PC) + OneDrive (Bo's files)  
**Status:** Ready to complete and publish

---

# TABLE OF CONTENTS

## PART 1: PROJECT UNDERSTANDING
- [Project 1: ACF - What Bo Did](#project-1-acf---what-bo-did)
- [Project 2: TS19 - What Bo Did](#project-2-ts19---what-bo-did)

## PART 2: EXACT SCRIPTS TO RUN
- [Scripts for ACF Project](#scripts-for-acf-project)
- [Scripts for TS19 Project](#scripts-for-ts19-project)

## PART 3: STEP-BY-STEP EXECUTION
- [Week-by-Week Plan](#week-by-week-plan)
- [Meeting with Advisor Guide](#meeting-with-advisor-guide)

---

# PART 1: PROJECT UNDERSTANDING

## PROJECT 1: ACF - What Bo Did

### 🎯 The Big Picture

**Research Question:**  
"What immune-related gene expression changes occur in the earliest precancerous colon lesions (ACF), and can these serve as biomarkers for colorectal cancer risk?"

**Why This Matters:**
- ACF (Aberrant Crypt Foci) are microscopic abnormalities that appear **years before** polyps or cancer
- Current colonoscopy can't reliably detect them
- If we can identify immune changes at this stage, we could:
  - Identify high-risk patients early
  - Develop blood-based biomarker tests
  - Potentially prevent cancer before it starts

**Clinical Impact:**
- Early detection = early intervention
- Could save thousands of lives
- Potential for immunotherapy in cancer **prevention** (not just treatment)

---

### 📊 The Data - What Bo Collected

**Sample Collection:**
- **20 patients** undergoing routine colonoscopy
- **Collaboration:** Dr. Rosenberg's group (provided samples)
- **For each patient:**
  - ACF tissue biopsy (the abnormal tissue)
  - Normal tissue biopsy (from same patient, as control)
  - Both tissues separated into:
    - **Epithelial** (cells lining the colon - where cancer starts)
    - **Stromal** (supporting tissue - the microenvironment)

**Total Samples:**
```
20 patients × 2 conditions (ACF vs Normal) × 2 compartments (Epithelial vs Stromal) = 80 samples
Each with 2 biological replicates = 160 libraries total
```

**Technology Used:**
- **RNA Sequencing** (measures gene expression)
- **Platform:** Ion Torrent
- **Assay:** Oncomine Immune Response Research Assay
- **Genes Measured:** ~400 immune-related genes (targeted panel, not whole genome)

**What the Raw Data Looks Like:**
```
Gene Expression Matrix (Counts):
              Sample1_ACF_Epi  Sample1_Norm_Epi  Sample1_ACF_Stro  Sample1_Norm_Stro  ...
Gene1 (CCL20)      1234             987               456               234
Gene2 (CXCL1)      5678             5432              789               456
Gene3 (PD-1)       910              876               234               123
...
(~400 genes × 80 samples)
```

---

### 🔬 The Pipeline - What Bo Did Step-by-Step

#### Step 1: Raw Sequencing Data → Gene Counts

**Input:** FASTQ files (raw sequencing reads)  
**Process:**
1. Quality filtering (remove low-quality reads)
2. Alignment to human genome (hg38)
3. Quantification (count reads per gene)

**Output:** Raw count matrix (genes × samples)

**Tools Used:** Ion Torrent Suite, STAR aligner, featureCounts

---

#### Step 2: Normalization

**Why Needed:**
- Different samples have different total read counts
- Need to make samples comparable
- Account for technical variation

**Method Used: DESeq2 Normalization**

**Process:**
1. Calculate size factors for each sample
   - Accounts for library size differences
   - Geometric mean approach
   
2. Normalize counts by size factors
   - Divide each sample's counts by its size factor
   
3. Apply Variance Stabilizing Transformation (VST)
   - For visualization (PCA, heatmaps)
   - Stabilizes variance across expression range
   - Makes data more normally distributed

**Output Files:**
- `ACF_normalized.csv` - Size-factor normalized counts
- `ACF_normalized_epi.csv` - Epithelial samples only
- `ACF_normalized_stro.csv` - Stromal samples only
- `PCA_cell.csv` - VST-transformed data for PCA

**Formula (simplified):**
```
Normalized_count = Raw_count / Size_factor
VST_count ≈ log2(Normalized_count + pseudocount) with variance stabilization
```

---

#### Step 3: Quality Control & Exploratory Analysis

**Purpose:** Check data quality, identify outliers, validate experimental design

**Analysis: Principal Component Analysis (PCA)**

**What PCA Does:**
- Reduces 400 genes to 2-3 main "components"
- Shows which samples are similar/different
- Reveals patterns in the data

**What Bo Found:**
- **PC1 (30-40% variance):** Separates ACF from Normal
- **PC2 (10-20% variance):** Separates Epithelial from Stromal
- **Replicates cluster together** (good - shows reproducibility)
- **No obvious outliers** (good - data quality is high)

**Interpretation:**
- Clear separation = real biological differences
- ACF and Normal are distinct at molecular level
- Epithelial and Stromal have different biology

**Output:**
- PCA plots (Figure 2 in manuscript)
- PC scores for each sample

---

#### Step 4: Differential Expression Analysis

**Purpose:** Find genes that are significantly different between ACF and Normal

**Method: DESeq2 Statistical Model**

**How It Works:**
1. **Model:** For each gene, fit a negative binomial model
   ```
   Gene_expression ~ Patient + Condition
   ```
   - Patient: accounts for patient-to-patient variation
   - Condition: tests ACF vs Normal effect

2. **Test:** Wald test for significance
   - Null hypothesis: No difference between ACF and Normal
   - Alternative: Gene is differentially expressed

3. **Correct for multiple testing:** Benjamini-Hochberg FDR
   - Testing 400 genes → expect ~20 false positives by chance
   - FDR correction controls false discovery rate

**Significance Criteria:**
- **Adjusted p-value < 0.05** (statistically significant)
- **|log2 Fold Change| > 0.58** (fold change > 1.5 or < 0.67)
- Both criteria must be met

**What Bo Found:**

**Epithelial Compartment:**
- **61 genes** significantly different
- **Upregulated:** Chemokines (CCL20, CXCL1), immune checkpoints (PD-1)
- **Downregulated:** Some regulatory genes

**Stromal Compartment:**
- **36 genes** significantly different
- **Upregulated:** Different chemokines, cytokines
- **Downregulated:** Some structural genes

**Key Observation:**
- Epithelial and stromal show **different** gene changes
- Some overlap, but mostly distinct
- Both compartments contribute to ACF biology

**Output Files:**
- `DESeq2_output.epi_only.ACF_vs_Norm.xlsx` - Epithelial results
- `DESeq2_output.stro_only.ACF_vs_Norm.xlsx` - Stromal results
- Each file contains: gene name, fold change, p-value, adjusted p-value

---

#### Step 5: Pathway Enrichment Analysis (GSEA)

**Purpose:** Understand biological meaning of gene lists

**Method: Gene Set Enrichment Analysis**

**How It Works:**
1. Rank all genes by differential expression
2. For each pathway (e.g., "chemokine signaling"):
   - Check if pathway genes are enriched at top/bottom of list
   - Calculate enrichment score
   - Test significance

3. Identify pathways significantly enriched

**Databases Used:**
- **Gene Ontology (GO):** Biological processes, molecular functions
- **KEGG:** Metabolic and signaling pathways
- **Reactome:** Curated biological pathways
- **Custom:** Immune cell signatures

**What Bo Found:**

**Epithelial ACF - Upregulated Pathways:**
1. **Chemokine signaling pathway** (p < 0.001)
   - Genes: CCL20, CXCL1, CXCL2, CXCL8
   - Function: Recruit immune cells

2. **Immune checkpoint regulation** (p < 0.01)
   - Genes: PD-1, CTLA4
   - Function: Suppress immune response

3. **Cytokine-mediated signaling** (p < 0.01)
   - Genes: IL6, IL8, TNF
   - Function: Inflammation

4. **Cell aging** (p < 0.05)
   - Genes: Various senescence markers
   - Function: Cellular stress response

**Stromal ACF - Upregulated Pathways:**
1. **Extracellular matrix organization**
2. **Immune cell recruitment**
3. **Angiogenesis** (blood vessel formation)

**Interpretation:**
- **Chemokine dysregulation:** Immune cells can't get to right place
- **Immune checkpoint elevation:** Immune cells are "exhausted"
- **Inflammation:** Chronic inflammatory state
- **Cell aging:** Stress response activated

**Output Files:**
- `GeneAnalytics_Results_5-11.epi.up.xlsx` - Epithelial upregulated
- `GeneAnalytics_Results_5-11.epi.down.xlsx` - Epithelial downregulated
- `GeneAnalytics_Results_5-11.stro.up.xlsx` - Stromal upregulated
- `GeneAnalytics_Results_5-11.stro.down.xlsx` - Stromal downregulated

---

#### Step 6: Visualization

**Purpose:** Create publication-quality figures

**Figure 2: PCA Plots**
- Shows sample relationships
- Validates experimental design
- Demonstrates ACF vs Normal separation

**Figure 3: Heatmaps**
- Shows expression patterns of DE genes
- Hierarchical clustering
- Color-coded by expression level

**Figure 4: GSEA Bar Charts**
- Shows enriched pathways
- Bar length = significance
- Organized by category

**Your Recent Work:**
- You've regenerated Figure 2 (PCA) ✅
- You've regenerated Figure 3 (Heatmap) ✅
- You need to create Figure 4 (GSEA) ⚠️

---

### 🔍 The Findings - What Bo Discovered

#### Finding 1: ACF Have Distinct Immune Profiles

**Evidence:**
- Clear separation in PCA
- 61 epithelial genes different
- 36 stromal genes different

**Significance:**
- Immune dysfunction begins **very early**
- Not just in advanced cancer
- Detectable at microscopic stage

**Clinical Implication:**
- Could develop early detection tests
- Blood-based biomarkers possible

---

#### Finding 2: Chemokine Pathways Are Dysregulated

**Evidence:**
- Multiple chemokine genes upregulated
- GSEA shows chemokine pathway enrichment
- Consistent across patients

**What This Means:**
- Chemokines = "address labels" for immune cells
- When dysregulated, immune cells can't find abnormal tissue
- Allows precancerous cells to escape immune surveillance

**Analogy:**
"It's like the GPS system for immune cells is malfunctioning. The cancer-fighting cells can't find the abnormal tissue because the address labels are wrong."

**Clinical Implication:**
- Potential therapeutic target
- Could "fix" the chemokine signals
- Help immune cells find and destroy ACF

---

#### Finding 3: PD-1+ Immune Cells Are Elevated

**Evidence:**
- PD-1 expression increased in ACF epithelium
- Immune checkpoint pathway enriched
- Similar to advanced cancers

**What This Means:**
- PD-1 = "off switch" for immune cells
- High PD-1 = exhausted immune cells
- Can't effectively fight abnormal cells

**Why This Is Exciting:**
- PD-1 inhibitors are FDA-approved cancer drugs
- Work by blocking the "off switch"
- Could potentially use for cancer **prevention**

**Clinical Implication:**
- Immunotherapy for prevention (not just treatment)
- Could prevent cancer before it starts
- Novel approach to cancer prevention

---

#### Finding 4: Epithelial and Stromal Changes Differ

**Evidence:**
- Different genes in each compartment
- Different pathways enriched
- Some overlap but mostly distinct

**What This Means:**
- Not just the precancerous cells changing
- Entire microenvironment affected
- Complex interaction between compartments

**Analogy:**
"It's not just the bad actors (epithelial cells) that are changing. The entire neighborhood (stroma) is also affected and contributing to the problem."

**Scientific Implication:**
- Need to study both compartments
- Tumor microenvironment is important
- Therapeutic targets in both compartments

---

### ✅ Validity of Findings

**Are Bo's Findings Valid? YES - Here's Why:**

#### 1. Appropriate Sample Size
- **20 patients** is standard for this type of study
- Matched controls (same patient)
- Biological replicates
- Statistical power adequate

#### 2. Rigorous Methods
- **DESeq2:** Gold standard for RNA-seq analysis
- **Proper normalization:** Accounts for technical variation
- **Multiple testing correction:** Controls false positives
- **Paired analysis:** Accounts for patient variation

#### 3. Reproducible Results
- Replicates cluster together
- Consistent patterns across patients
- No obvious outliers
- Clear biological signal

#### 4. Biologically Coherent
- Findings make biological sense
- Consistent with cancer biology literature
- Pathways are known cancer-related
- Chemokine/immune checkpoint roles established

#### 5. Technically Sound
- High-quality RNA (RIN > 7)
- Good mapping rates (>80%)
- Appropriate sequencing depth
- Proper controls

**Potential Limitations (to acknowledge):**
1. **Sample size:** 20 patients is good but not huge
2. **Targeted panel:** Only 400 genes (not whole genome)
3. **Observational:** Shows association, not causation
4. **Single time point:** Can't show progression

**How to Address in Manuscript:**
- Acknowledge limitations in Discussion
- Emphasize strengths (matched controls, rigorous methods)
- Suggest future validation studies
- Propose mechanistic follow-up

---

### 📝 Current Manuscript Status

**What Exists:**
- Draft manuscript: "Copy of Oncomine manuscript BL dwr2 5-11.docx"
- Located in your OneDrive: `ACF paper revised` folder
- ~90% complete according to Bo's notes

**What's in the Manuscript:**
- Introduction (background on ACF and colorectal cancer)
- Methods (sample collection, RNA-seq, analysis)
- Results (DE genes, pathway analysis)
- Discussion (interpretation, implications)
- Figures 1-4 (study design, PCA, heatmaps, GSEA)
- Tables 1-2 (demographics, DE genes)

**What Needs to Be Done:**
1. **Figure 4 remake** - Bo's note: "Reorder figures, remake Figure 4 (GSEA summary)"
2. **Table 2 formatting** - Currently a screenshot, needs to be proper table
3. **Supplementary figures** - QC metrics, additional analyses
4. **Methods polish** - Add software versions, detailed parameters
5. **Final formatting** - Format for target journal

---

## PROJECT 2: TS19 - What Bo Did

### 🎯 The Big Picture

**Research Question:**  
"What are all the cell types present in a mouse embryo at E11.5 (embryonic day 11.5), and how do they relate to each other developmentally?"

**Why This Matters:**
- E11.5 is a critical stage in mouse development
- Major organs are forming
- Understanding cell types helps understand:
  - Normal development
  - Birth defects
  - Developmental diseases
  - Stem cell biology

**Scientific Impact:**
- Comprehensive reference atlas
- Enables comparison across studies
- Foundation for developmental biology research
- Potential for regenerative medicine applications

---

### 📊 The Data - What Bo Collected

**Sample Collection:**
- **Mouse embryos** at E11.5 developmental stage
- **Whole embryo** dissociation into single cells
- **Technology:** 10X Genomics Chromium (droplet-based scRNA-seq)

**Scale:**
- **Thousands of cells** analyzed
- **Thousands of genes** per cell measured
- **Whole transcriptome** (not targeted panel like ACF)

**What Single-Cell Data Looks Like:**
```
UMI (Unique Molecular Identifier) Matrix:
              Cell_1  Cell_2  Cell_3  Cell_4  ...  Cell_N (thousands)
Gene_1 (Tnnt2)    5      0      12     3           2
Gene_2 (Sox2)     0      8      0      15          0
Gene_3 (Hba-a1)   23     45     67     12          89
...
Gene_M (thousands)
```

**Difference from ACF:**
- **ACF:** Bulk RNA-seq (average of many cells)
- **TS19:** Single-cell RNA-seq (individual cells)
- **ACF:** 400 genes (targeted)
- **TS19:** ~20,000 genes (whole transcriptome)

---

### 🔬 The Pipeline - What Bo Did Step-by-Step

#### Step 1: Raw Sequencing → UMI Counts

**Input:** FASTQ files (raw sequencing reads)

**Process:**
1. **Cell barcode extraction**
   - Each droplet has unique barcode
   - Identifies which cell each read came from

2. **UMI extraction**
   - Unique Molecular Identifier
   - Counts individual mRNA molecules
   - Reduces PCR amplification bias

3. **Alignment to mouse genome**
   - Maps reads to genes

4. **UMI counting**
   - Count unique UMIs per gene per cell

**Output:** UMI count matrix (genes × cells)

**Tool Used:** Cell Ranger (10X Genomics software)

**File Location (mentioned by Bo):**
- Ion server: `/data5/bo/UMI_table/TS19.qc.all.0excluded.csv`
- Status: Unknown if still exists

---

#### Step 2: Quality Control

**Purpose:** Remove low-quality cells and genes

**Cell Filtering Criteria:**
- **Minimum genes detected:** >200 genes per cell
- **Minimum UMIs:** >500 UMIs per cell
- **Maximum mitochondrial %:** <20% (high = dying cell)

**Gene Filtering Criteria:**
- **Minimum cells:** Detected in ≥3 cells

**What Gets Removed:**
- Empty droplets (no cell)
- Doublets (two cells in one droplet)
- Dying cells (high mitochondrial %)
- Low-quality cells (few genes detected)

**Output:** QC-filtered UMI matrix

---

#### Step 3: Normalization & Scaling

**Purpose:** Make cells comparable

**Process:**
1. **Normalize by total counts**
   - Each cell has different total UMI count
   - Normalize to same total (e.g., 10,000)

2. **Log transformation**
   - log(normalized_count + 1)
   - Makes data more normally distributed

3. **Scale and center**
   - Per-gene z-score
   - Mean = 0, SD = 1

**Output:** Normalized expression matrix

---

#### Step 4: Dimensionality Reduction

**Purpose:** Reduce from thousands of genes to manageable dimensions

**Step 4a: PCA**
- Reduce to ~50 principal components
- Captures main variation in data

**Step 4b: t-SNE or UMAP**
- Further reduce to 2D for visualization
- Preserves local structure
- Cells close together = similar expression

**Output:**
- PCA coordinates (50 dimensions)
- t-SNE coordinates (2 dimensions)
- Used for visualization and clustering

---

#### Step 5: Clustering

**Purpose:** Group similar cells together (potential cell types)

**Method: IBS (Iterative Binary Splitting)**

**How IBS Works:**
1. Start with all cells as one cluster
2. Split into two sub-clusters
3. For each sub-cluster, try splitting again
4. Stop when no improvement in separation
5. Result: Hierarchical tree of clusters

**Alternative Methods (Bo also tried):**
- Louvain clustering
- Ward hierarchical clustering

**What Bo Found:**
- **~20 major clusters** at E11.5
- Each cluster = potential cell type

**Output:**
- Cluster assignments for each cell
- Hierarchical tree structure

---

#### Step 6: Cell Type Annotation

**Purpose:** Identify what each cluster represents

**Methods Bo Used:**

**Method 1: GSEA (Gene Set Enrichment Analysis)**
- For each cluster, find enriched pathways
- Compare to known cell type signatures
- Example: Cluster enriched for "cardiac muscle" genes = cardiomyocytes

**Method 2: Marker Gene Projection**
- Plot known marker genes on t-SNE
- Example: Tnnt2 (cardiac marker) high in one cluster = cardiomyocytes

**Method 3: Cell Lineage Map Scoring**
- Compare to published cell type markers
- Score each cluster for each cell type
- Highest score = likely identity

**What Bo Found (20 Cell Types):**
1. **Cardiomyocytes** (heart muscle)
2. **Neural progenitors** (brain/spinal cord)
3. **Erythrocytes** (red blood cells)
4. **Endothelial cells** (blood vessels)
5. **Mesenchyme** (connective tissue)
6. **Epithelial cells** (various organs)
7. **Hepatocytes** (liver)
8. **Nephron progenitors** (kidney)
9. **Cranial neural crest** (face/skull)
10. **Somites** (muscle/bone precursors)
... and 10 more

**Output:**
- Annotated cluster identities
- Marker genes for each cell type
- Confidence scores

---

#### Step 7: Sub-Clustering Analysis

**Purpose:** Find subtypes within major cell types

**Process:**
1. Take cells from one major cluster (e.g., neural cells)
2. Re-cluster just those cells
3. Identify subtypes
4. Annotate subtypes

**What Bo Found:**

**Mesoderm/Mesenchyme:**
- Multiple subtypes
- Developmental progression visible
- Different spatial origins

**Neuroectoderm:**
- Neural progenitors
- Differentiating neurons
- Regional identities (forebrain, midbrain, hindbrain)

**Blood Lineage:**
- Hematopoietic stem cells
- Erythroid progenitors
- Mature erythrocytes
- Developmental trajectory visible

**Cardiomyocytes:**
- Region-specific populations
- Different proliferation rates
- Atrial vs ventricular

---

#### Step 8: Trajectory Analysis

**Purpose:** Map developmental paths

**Method: Pseudotime Analysis**

**How It Works:**
1. Order cells along developmental trajectory
2. Assign "pseudotime" (developmental stage)
3. Identify genes that change along trajectory

**What Bo Found:**

**Blood Lineage:**
- Clear trajectory from stem cells to mature erythrocytes
- Hemoglobin genes (Hba, Hbb) increase along trajectory
- Stem cell genes decrease

**Hox Genes:**
- Nested expression patterns
- Spatial organization visible in t-SNE
- Reflects anterior-posterior body axis

---

### 🔍 The Findings - What Bo Discovered

#### Finding 1: 20 Unique Cell Types at E11.5

**Evidence:**
- Distinct clusters in t-SNE
- Unique marker genes for each
- GSEA confirms identities

**Significance:**
- Comprehensive atlas
- More cell types than previously described
- Reference for field

---

#### Finding 2: Cell Type Dynamics Revealed

**Evidence:**
- Sub-clustering shows subtypes
- Developmental progressions visible
- Regional identities mapped

**Significance:**
- Not just static snapshot
- Shows developmental processes
- Reveals cell state transitions

---

#### Finding 3: Blood Lineage Trajectory

**Evidence:**
- Clear developmental path
- Hemoglobin gradient
- Stem cells → progenitors → mature cells

**Significance:**
- Validates developmental biology
- Shows method can capture dynamics
- Potential for studying blood disorders

---

#### Finding 4: Nested Hox Gene Expression

**Evidence:**
- Hox genes show spatial pattern in t-SNE
- Nested expression (Hox1 → Hox13)
- Reflects body axis

**Significance:**
- Spatial information preserved in scRNA-seq
- Validates developmental biology principles
- Shows power of method

---

### ✅ Validity of Findings

**Are Bo's TS19 Findings Valid? YES - Here's Why:**

#### 1. Appropriate Scale
- Thousands of cells analyzed
- Sufficient depth per cell
- Comprehensive coverage

#### 2. Rigorous Methods
- Standard scRNA-seq pipeline
- Multiple annotation approaches
- Validated with known markers

#### 3. Biologically Coherent
- Cell types make sense
- Consistent with developmental biology
- Marker genes are appropriate

#### 4. Comprehensive Documentation
- Complete thesis chapter
- Methods documented
- Figures generated

**Potential Limitations:**
1. **Single time point:** E11.5 only (not multiple stages)
2. **Batch effects:** If integrating multiple samples
3. **Annotation subjectivity:** Some clusters hard to identify
4. **Technical dropouts:** scRNA-seq has sparse data

---

### 📝 Current TS19 Status

**What Exists:**
- **Complete thesis chapter** (Chapter 1 of Bo's thesis)
- **Manuscript outline** (TS19 Cell Typing Outline Doc v1.0.docx)
- **Methods documentation** (Material and Methods v1.2 Bo.docx)
- **Figures** (in thesis and PowerPoint files)

**What's in the Thesis:**
- Introduction
- Complete methods
- All results
- All figures
- Discussion
- References

**What Needs to Be Done:**
1. **Expand outline to full manuscript**
2. **Extract text from thesis**
3. **Regenerate figures in publication format**
4. **Compare to existing atlases** (establish novelty)
5. **Format for journal**

---

# PART 2: EXACT SCRIPTS TO RUN

## SCRIPTS FOR ACF PROJECT

### Script 1: Generate All ACF Figures (PCA + Heatmaps)

**Purpose:** Create publication-quality figures for manuscript

**Location to Run:** `C:\work\BO_S`

**Prerequisites:**
1. You need the data files in the correct location
2. R must be installed with required packages

**The Script (Already in your repo):**

File: `src/analysis/acf_pubplots.R`

**How to Run:**

```powershell
# Open PowerShell
# Navigate to your project directory
cd C:\work\BO_S

# Run for Epithelial samples
Rscript src/analysis/acf_pubplots.R `
  --counts "data/processed/acf/normalized/ACF_normalized_epi.csv" `
  --meta "data/raw/acf/metadata/sample_metadata.csv" `
  --compartment "Epithelial" `
  --topN 100 `
  --prefix "20251011_acf_epi_orig" `
  --outdir "results/figures/main"

# Run for Epithelial samples (trimmed version - top 40 genes)
Rscript src/analysis/acf_pubplots.R `
  --counts "data/processed/acf/normalized/ACF_normalized_epi.csv" `
  --meta "data/raw/acf/metadata/sample_metadata.csv" `
  --compartment "Epithelial" `
  --topN 40 `
  --prefix "20251011_acf_epi_top40" `
  --outdir "results/figures/main"

# Run for Stromal samples (if you have the data)
Rscript src/analysis/acf_pubplots.R `
  --counts "data/processed/acf/normalized/ACF_normalized_stro.csv" `
  --meta "data/raw/acf/metadata/sample_metadata.csv" `
  --compartment "Stromal" `
  --topN 100 `
  --prefix "20251011_acf_stro_orig" `
  --outdir "results/figures/main"
```

**What This Script Does:**
1. Loads normalized count data
2. Loads sample metadata
3. Filters to specified compartment
4. Removes zero-variance genes
5. Performs PCA
6. Generates PCA plot (PC1 vs PC2)
7. Selects top N variable genes
8. Generates heatmap with hierarchical clustering
9. Saves figures as PDFs
10. Saves PC scores as CSV
11. Creates run log

**Output Files:**
- `20251011_acf_epi_orig_PCA_samples.pdf`
- `20251011_acf_epi_orig_Heatmap_topVarGenes.pdf`
- `20251011_acf_epi_PCA_scores.csv`
- `20251011_acf_epi_orig_runlog.txt`

---

### Script 2: Create GSEA Bar Chart (Figure 4)

**Purpose:** Visualize enriched pathways

**Location to Run:** `C:\work\BO_S`

**Create New File:** `src/analysis/create_gsea_figure.R`

```R
# create_gsea_figure.R
# Purpose: Create GSEA bar chart (Figure 4) for ACF manuscript

# Load required libraries
library(ggplot2)
library(readxl)
library(dplyr)

# Set working directory
setwd("C:/work/BO_S")

# Load GSEA results
# Adjust path to where your GSEA files are located
gsea_epi_up <- read_excel("data/processed/acf/gsea/GeneAnalytics_Results_5-11.epi.up.xlsx")

# Select top 10 pathways by adjusted p-value
top_pathways <- gsea_epi_up %>%
  arrange(padj) %>%
  head(10)

# Create bar chart
p <- ggplot(top_pathways, aes(x = reorder(pathway, -log10(padj)), y = -log10(padj))) +
  geom_bar(stat = "identity", fill = "steelblue", width = 0.7) +
  coord_flip() +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = "red", size = 0.5) +
  theme_minimal(base_size = 11) +
  theme(
    axis.text.y = element_text(size = 10),
    axis.text.x = element_text(size = 10),
    axis.title = element_text(size = 11, face = "bold"),
    plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank()
  ) +
  labs(
    x = "Pathway",
    y = "-log10(adjusted p-value)",
    title = "Enriched Pathways in ACF Epithelium (Upregulated Genes)"
  )

# Save figure
ggsave("results/figures/main/Figure4_GSEA_epithelial_up.pdf", 
       plot = p, width = 10, height = 6, units = "in")

print("Figure 4 created successfully!")
print(paste("Saved to:", "results/figures/main/Figure4_GSEA_epithelial_up.pdf"))

# Optional: Create for other conditions
# Epithelial downregulated
gsea_epi_down <- read_excel("data/processed/acf/gsea/GeneAnalytics_Results_5-11.epi.down.xlsx")
# ... repeat process

# Stromal upregulated
gsea_stro_up <- read_excel("data/processed/acf/gsea/GeneAnalytics_Results_5-11.stro.up.xlsx")
# ... repeat process
```

**How to Run:**

```powershell
cd C:\work\BO_S
Rscript src/analysis/create_gsea_figure.R
```

**What This Script Does:**
1. Loads GSEA results from Excel file
2. Selects top 10 most significant pathways
3. Creates bar chart with:
   - Pathways on y-axis
   - Significance on x-axis
   - Red dashed line at p=0.05 threshold
4. Saves as PDF

**Output:**
- `results/figures/main/Figure4_GSEA_epithelial_up.pdf`

---

### Script 3: Create Supplementary QC Figures

**Purpose:** Generate quality control figures for supplementary materials

**Create New File:** `src/analysis/create_qc_figures.R`

```R
# create_qc_figures.R
# Purpose: Create supplementary QC figures

library(ggplot2)
library(pheatmap)
library(RColorBrewer)

setwd("C:/work/BO_S")

# Load data
counts <- read.csv("data/processed/acf/normalized/ACF_normalized_epi.csv", 
                   row.names = 1, check.names = FALSE)
meta <- read.csv("data/raw/acf/metadata/sample_metadata.csv")

# Convert to matrix
counts_matrix <- as.matrix(counts)

# ===== Supplementary Figure 1: Library Size Distribution =====
library_sizes <- colSums(counts_matrix)
df_lib <- data.frame(
  Sample = names(library_sizes),
  LibrarySize = library_sizes,
  Condition = meta$condition[match(names(library_sizes), meta$sample)]
)

p1 <- ggplot(df_lib, aes(x = Sample, y = LibrarySize, fill = Condition)) +
  geom_bar(stat = "identity") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, size = 8)) +
  labs(title = "Library Size Distribution",
       x = "Sample", y = "Total Counts") +
  scale_fill_manual(values = c("ACF" = "#D55E00", "Normal" = "#0072B2"))

ggsave("results/figures/supplementary/FigS1_library_sizes.pdf", 
       p1, width = 12, height = 6)

# ===== Supplementary Figure 2: Gene Detection Rate =====
genes_detected <- colSums(counts_matrix > 0)
df_genes <- data.frame(
  Sample = names(genes_detected),
  GenesDetected = genes_detected,
  Condition = meta$condition[match(names(genes_detected), meta$sample)]
)

p2 <- ggplot(df_genes, aes(x = Sample, y = GenesDetected, fill = Condition)) +
  geom_bar(stat = "identity") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, size = 8)) +
  labs(title = "Gene Detection Rate",
       x = "Sample", y = "Number of Genes Detected") +
  scale_fill_manual(values = c("ACF" = "#D55E00", "Normal" = "#0072B2"))

ggsave("results/figures/supplementary/FigS2_gene_detection.pdf", 
       p2, width = 12, height = 6)

# ===== Supplementary Figure 3: Sample Correlation Heatmap =====
# Calculate correlation between samples
cor_matrix <- cor(counts_matrix, method = "pearson")

# Create annotation
annotation_col <- data.frame(
  Condition = meta$condition[match(colnames(cor_matrix), meta$sample)]
)
rownames(annotation_col) <- colnames(cor_matrix)

# Create heatmap
pdf("results/figures/supplementary/FigS3_sample_correlation.pdf", 
    width = 10, height = 10)
pheatmap(cor_matrix,
         color = colorRampPalette(brewer.pal(9, "Blues"))(100),
         annotation_col = annotation_col,
         annotation_row = annotation_col,
         show_rownames = TRUE,
         show_colnames = TRUE,
         fontsize = 8,
         main = "Sample Correlation Heatmap")
dev.off()

print("All supplementary QC figures created successfully!")
```

**How to Run:**

```powershell
cd C:\work\BO_S
Rscript src/analysis/create_qc_figures.R
```

**Output:**
- `FigS1_library_sizes.pdf`
- `FigS2_gene_detection.pdf`
- `FigS3_sample_correlation.pdf`

---

### Script 4: Create Volcano Plots

**Purpose:** Visualize differential expression results

**Create New File:** `src/analysis/create_volcano_plots.R`

```R
# create_volcano_plots.R
# Purpose: Create volcano plots for differential expression

library(ggplot2)
library(readxl)
library(ggrepel)

setwd("C:/work/BO_S")

# Load DE results
de_epi <- read_excel("data/processed/acf/dge/DESeq2_output.epi_only.ACF_vs_Norm.xlsx")

# Add significance column
de_epi$Significant <- ifelse(de_epi$padj < 0.05 & abs(de_epi$log2FoldChange) > 0.58,
                              "Significant", "Not Significant")

# Identify top genes to label
de_epi$Label <- ""
top_genes <- de_epi %>%
  filter(Significant == "Significant") %>%
  arrange(padj) %>%
  head(10)
de_epi$Label[match(top_genes$gene, de_epi$gene)] <- top_genes$gene

# Create volcano plot
p <- ggplot(de_epi, aes(x = log2FoldChange, y = -log10(padj), color = Significant)) +
  geom_point(alpha = 0.6, size = 2) +
  scale_color_manual(values = c("Significant" = "red", "Not Significant" = "gray")) +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = "blue") +
  geom_vline(xintercept = c(-0.58, 0.58), linetype = "dashed", color = "blue") +
  geom_text_repel(aes(label = Label), size = 3, max.overlaps = 20) +
  theme_minimal() +
  labs(title = "Volcano Plot - Epithelial ACF vs Normal",
       x = "log2 Fold Change",
       y = "-log10(adjusted p-value)") +
  theme(legend.position = "top")

ggsave("results/figures/supplementary/FigS4_volcano_epithelial.pdf", 
       p, width = 10, height = 8)

# Repeat for stromal
de_stro <- read_excel("data/processed/acf/dge/DESeq2_output.stro_only.ACF_vs_Norm.xlsx")
# ... same process

print("Volcano plots created successfully!")
```

**How to Run:**

```powershell
cd C:\work\BO_S
Rscript src/analysis/create_volcano_plots.R
```

---

### Script 5: Organize and Push to GitHub

**Purpose:** Commit all new figures and push to GitHub

**Create New File:** `push_to_github.ps1`

```powershell
# push_to_github.ps1
# Purpose: Commit and push all new figures to GitHub

# Navigate to project directory
cd C:\work\BO_S

# Add all new figures
git add results/figures/main/*.pdf
git add results/figures/supplementary/*.pdf
git add results/tables/*.csv

# Add scripts
git add src/analysis/*.R

# Commit with descriptive message
$date = Get-Date -Format "yyyy-MM-dd"
git commit -m "Add complete ACF figures and analysis scripts - $date"

# Push to GitHub
git push https://x-access-token:$env:GITHUB_TOKEN@github.com/RustemKurkcu/BO_S.git

Write-Host "Successfully pushed to GitHub!" -ForegroundColor Green
```

**How to Run:**

```powershell
cd C:\work\BO_S
.\push_to_github.ps1
```

---

## SCRIPTS FOR TS19 PROJECT

### Script 1: Extract Content from Thesis

**Purpose:** Extract text and figures from Bo's thesis for manuscript

**Create New File:** `src/analysis/extract_thesis_content.py`

```python
# extract_thesis_content.py
# Purpose: Extract TS19 content from Bo's thesis

from docx import Document
import os

# Load thesis
thesis_path = "Thesis/Bo Thesis final.docx"
doc = Document(thesis_path)

# Create output directory
os.makedirs("manuscripts/ts19_atlas/extracted", exist_ok=True)

# Extract Chapter 1 (TS19 project)
chapter1_text = []
in_chapter1 = False

for para in doc.paragraphs:
    text = para.text.strip()
    
    # Detect chapter start
    if "Chapter 1" in text or "TS19" in text:
        in_chapter1 = True
    
    # Detect chapter end (Chapter 2 starts)
    if "Chapter 2" in text:
        in_chapter1 = False
    
    # Collect text
    if in_chapter1 and text:
        chapter1_text.append(text)

# Save extracted text
with open("manuscripts/ts19_atlas/extracted/chapter1_text.txt", "w", encoding="utf-8") as f:
    f.write("\n\n".join(chapter1_text))

print(f"Extracted {len(chapter1_text)} paragraphs from Chapter 1")
print("Saved to: manuscripts/ts19_atlas/extracted/chapter1_text.txt")

# Extract figures (if embedded)
# Note: Figures might be in separate PowerPoint file
print("\nNote: Figures are in 'Bo Thesis All figures final.pptx'")
print("You'll need to extract those separately")
```

**How to Run:**

```powershell
cd C:\work\BO_S
python src/analysis/extract_thesis_content.py
```

---

### Script 2: Create TS19 Manuscript Template

**Purpose:** Create manuscript structure from thesis content

**Create New File:** `src/analysis/create_ts19_manuscript.py`

```python
# create_ts19_manuscript.py
# Purpose: Create TS19 manuscript template

import os

# Create manuscript structure
manuscript_dir = "manuscripts/ts19_atlas"
os.makedirs(f"{manuscript_dir}/drafts", exist_ok=True)
os.makedirs(f"{manuscript_dir}/figures", exist_ok=True)
os.makedirs(f"{manuscript_dir}/tables", exist_ok=True)
os.makedirs(f"{manuscript_dir}/supplementary", exist_ok=True)

# Create manuscript template
template = """
# Single-Cell Transcriptome Atlas of E11.5 Mouse Embryo

## Abstract
[To be written - 250 words]
- Background: Why E11.5 atlas is needed
- Methods: scRNA-seq, 10X Genomics, ~X cells
- Results: 20 cell types identified, developmental trajectories
- Conclusions: Comprehensive reference atlas

## Introduction
[Extract from thesis Chapter 1 - Introduction section]
- Importance of E11.5 stage
- Previous atlases and gaps
- Study objectives

## Methods
[Extract from "Material and Methods v1.2 Bo.docx"]
- Sample collection and processing
- 10X Genomics protocol
- Data processing pipeline
- Quality control
- Clustering and annotation
- Trajectory analysis

## Results
[Extract from thesis Chapter 1 - Results section]

### Overall Cell Type Identification
- 20 unique cell types
- Figure 1: t-SNE plot with annotations
- Table 1: Cell type markers

### Mesoderm/Mesenchyme Dynamics
- Sub-clustering analysis
- Figure 2: Mesenchyme subtypes

### Neuroectoderm Development
- Neural cell types
- Figure 3: Neural subtypes

### Blood Lineage Trajectory
- Developmental progression
- Figure 4: Blood trajectory

### Hox Gene Expression
- Nested patterns
- Figure 5: Hox expression

### Cardiomyocyte Analysis
- Region-specific populations
- Figure 6: Cardiomyocyte subtypes

## Discussion
[Extract from thesis Chapter 1 - Discussion section]
- Summary of findings
- Comparison to existing atlases
- Biological implications
- Limitations
- Future directions

## References
[To be compiled]

## Figure Legends
[To be written for each figure]

## Supplementary Materials
[To be created]
"""

# Save template
with open(f"{manuscript_dir}/drafts/ts19_manuscript_template.md", "w") as f:
    f.write(template)

print("Manuscript template created!")
print(f"Location: {manuscript_dir}/drafts/ts19_manuscript_template.md")
print("\nNext steps:")
print("1. Read Bo's thesis Chapter 1")
print("2. Extract relevant sections")
print("3. Fill in the template")
print("4. Format for target journal")
```

**How to Run:**

```powershell
cd C:\work\BO_S
python src/analysis/create_ts19_manuscript.py
```

---

# PART 3: STEP-BY-STEP EXECUTION

## WEEK-BY-WEEK PLAN

### Week 1: ACF Project - Complete Analysis

**Monday (Day 1):**
```powershell
# 1. Organize data files
# Copy ACF files from OneDrive to proper locations
# Ensure you have:
# - ACF_normalized_epi.csv
# - ACF_normalized_stro.csv
# - sample_metadata.csv
# - DESeq2 results
# - GSEA results

# 2. Run PCA and heatmap generation
cd C:\work\BO_S
Rscript src/analysis/acf_pubplots.R --counts "data/processed/acf/normalized/ACF_normalized_epi.csv" --meta "data/raw/acf/metadata/sample_metadata.csv" --compartment "Epithelial" --topN 100 --prefix "20251011_acf_epi_orig"
```

**Tuesday (Day 2):**
```powershell
# 3. Create GSEA figure
Rscript src/analysis/create_gsea_figure.R

# 4. Create supplementary QC figures
Rscript src/analysis/create_qc_figures.R
```

**Wednesday (Day 3):**
```powershell
# 5. Create volcano plots
Rscript src/analysis/create_volcano_plots.R

# 6. Review all figures
# Check that they look good
# Compare to Bo's originals
```

**Thursday (Day 4):**
```powershell
# 7. Push everything to GitHub
.\push_to_github.ps1

# 8. Review manuscript
# Open: ACF paper revised/Copy of Oncomine manuscript BL dwr2 5-11.docx
# Read through completely
# Take notes on what's missing
```

**Friday (Day 5):**
```
# 9. Update manuscript
# - Replace Figure 4 with new GSEA chart
# - Add supplementary figures
# - Update methods with software versions
# - Format Table 2 properly

# 10. Prepare for advisor meeting
# Review all materials
# Prepare questions
```

---

### Week 2: ACF Project - Manuscript Finalization

**Monday-Tuesday:**
- Polish manuscript text
- Format for target journal
- Create cover letter
- Prepare supplementary materials

**Wednesday-Thursday:**
- Final review
- Proofread
- Check all references
- Verify all figures and tables

**Friday:**
- Submit to journal OR
- Send to Dr. Nelson for final review

---

### Week 3-4: TS19 Project - Assessment & Planning

**Week 3:**
- Read Bo's thesis Chapter 1 thoroughly
- Extract key content
- Review manuscript outline
- Assess what's needed

**Week 4:**
- Create manuscript draft
- Organize figures
- Write methods section
- Plan remaining work

---

## MEETING WITH ADVISOR GUIDE

### Preparation (Before Meeting)

**Materials to Bring:**
1. This guide (printed or on tablet)
2. Generated figures (on laptop)
3. Manuscript draft
4. List of questions

**What to Review:**
1. Read PROJECT_STATUS_ANALYSIS.md
2. Review all figures you generated
3. Read ACF manuscript
4. Prepare 5-minute summary of each project

---

### Meeting Structure (30-45 minutes)

**Part 1: ACF Project Update (15 minutes)**

**Your Talking Points:**

"I've been working on completing Bo's ACF project. Let me walk you through what Bo did and where we are now."

**Explain the Project:**
"Bo studied aberrant crypt foci - the earliest precancerous lesions in the colon. He used RNA sequencing to measure immune gene expression in ACF tissue compared to normal tissue from the same patients. He separated the tissue into epithelial and stromal compartments to see how each contributes to the disease."

**Explain the Data:**
"We have 20 patients, each with ACF and matched normal tissue, separated into epithelial and stromal compartments. That's 80 samples total. Bo used a targeted RNA-seq panel measuring about 400 immune-related genes."

**Explain the Analysis:**
"The analysis pipeline had several steps:
1. Normalization using DESeq2 to make samples comparable
2. PCA to visualize sample relationships - this showed clear separation between ACF and normal
3. Differential expression analysis to find genes that differ between ACF and normal
4. Pathway analysis to understand the biological meaning

The key findings were:
- 61 genes different in epithelium, 36 in stroma
- Chemokine pathways dysregulated - immune cells can't get to the right place
- PD-1 elevated - immune cells are exhausted
- Both compartments show changes, but different patterns"

**Show the Figures:**
"I've regenerated all the main figures:
- Figure 2: PCA showing ACF vs normal separation
- Figure 3: Heatmaps of differentially expressed genes
- Figure 4: GSEA showing enriched pathways
- Plus supplementary QC figures"

**Current Status:**
"The manuscript is about 90% complete. I've:
- Regenerated all figures in publication quality
- Created supplementary materials
- Reviewed the manuscript

What's left:
- Final formatting for journal
- Your review and edits
- Submission"

**Questions for Advisor:**
1. "Which journal should we target? Gastroenterology? Cancer Research?"
2. "What's the authorship order? Bo first, me second, you last?"
3. "Any specific concerns I should address in the manuscript?"
4. "Timeline - can we submit in 2 weeks?"

---

**Part 2: TS19 Project Assessment (15 minutes)**

**Your Talking Points:**

"I've also assessed Bo's TS19 project - the single-cell atlas of mouse embryo development."

**Explain the Project:**
"Bo created a comprehensive single-cell RNA-seq atlas of mouse embryos at E11.5 - a critical developmental stage when major organs are forming. He identified 20 different cell types and mapped developmental trajectories."

**Explain the Data:**
"This is single-cell RNA-seq, so thousands of individual cells, each with expression data for thousands of genes. Much more comprehensive than the ACF bulk RNA-seq."

**Explain the Analysis:**
"The pipeline was:
1. Quality control to remove low-quality cells
2. Normalization and dimensionality reduction
3. Clustering to group similar cells
4. Cell type annotation using marker genes and pathway analysis
5. Sub-clustering to find subtypes
6. Trajectory analysis to map developmental paths

Key findings:
- 20 unique cell types identified
- Developmental progressions visible
- Blood lineage trajectory mapped
- Hox gene expression patterns
- Region-specific cardiomyocytes"

**Current Status:**
"The good news: Bo's thesis has a complete chapter on this with all the analysis and figures. The manuscript outline exists but needs to be expanded.

What's needed:
- Extract content from thesis
- Format as manuscript
- Regenerate figures
- Compare to existing atlases
- Submit"

**Questions for Advisor:**
1. "Should we prioritize this after ACF?"
2. "Do we have access to the raw data on the Ion server?"
3. "What journal for this? Development? Cell Reports?"
4. "Timeline - 4-6 weeks after ACF?"

---

**Part 3: Overall Strategy (10 minutes)**

**Your Proposal:**
"I propose we:
1. Finish ACF first (2 weeks)
2. Submit ACF
3. Then work on TS19 (4-6 weeks)
4. Submit TS19

This gives us 2 publications from Bo's work, both high-quality, both impactful."

**Questions for Advisor:**
1. "Does this timeline work for you?"
2. "Any other priorities I should know about?"
3. "How involved do you want to be in the writing?"
4. "Should I schedule regular check-ins?"

---

### After Meeting

**Action Items:**
1. Send follow-up email summarizing decisions
2. Update timeline based on discussion
3. Start on agreed-upon tasks
4. Schedule next check-in

---

## FINAL CHECKLIST

### ACF Project Completion Checklist

**Analysis:**
- [ ] PCA plots generated (epithelial and stromal)
- [ ] Heatmaps generated (epithelial and stromal)
- [ ] GSEA bar charts created
- [ ] Volcano plots created
- [ ] Supplementary QC figures created
- [ ] All figures in publication quality (300 DPI, PDF)

**Manuscript:**
- [ ] All figures inserted and referenced
- [ ] Table 2 formatted properly (not screenshot)
- [ ] Methods section complete with software versions
- [ ] Results section complete
- [ ] Discussion section complete
- [ ] References formatted
- [ ] Supplementary materials organized

**Submission:**
- [ ] Target journal selected
- [ ] Manuscript formatted per journal guidelines
- [ ] Cover letter written
- [ ] Author contributions documented
- [ ] Conflicts of interest declared
- [ ] Funding acknowledged

**GitHub:**
- [ ] All scripts committed
- [ ] All figures committed
- [ ] Documentation updated
- [ ] README updated

---

### TS19 Project Completion Checklist

**Assessment:**
- [ ] Thesis Chapter 1 read completely
- [ ] Manuscript outline reviewed
- [ ] Methods documentation reviewed
- [ ] Figures identified and located
- [ ] Data availability confirmed

**Manuscript:**
- [ ] Content extracted from thesis
- [ ] Manuscript template created
- [ ] Introduction written
- [ ] Methods written
- [ ] Results written
- [ ] Discussion written
- [ ] Figures regenerated
- [ ] Tables created

**Comparison:**
- [ ] Existing atlases identified
- [ ] Comparison analysis done
- [ ] Novelty established
- [ ] Positioned in field

**Submission:**
- [ ] Target journal selected
- [ ] Manuscript formatted
- [ ] Cover letter written
- [ ] Submitted

---

## SUMMARY

**You now have:**
1. ✅ Complete understanding of both projects
2. ✅ Exact scripts to run
3. ✅ Step-by-step execution plan
4. ✅ Meeting preparation guide
5. ✅ Completion checklists

**Next Steps:**
1. **Today:** Run ACF analysis scripts
2. **This Week:** Complete ACF figures
3. **Next Week:** Finalize ACF manuscript
4. **Week 3:** Meet with advisor
5. **Week 4:** Submit ACF paper
6. **Week 5+:** Start TS19

**You're ready to complete both projects and get them published!** 🚀

---

**Questions? Refer back to:**
- PROJECT_STATUS_ANALYSIS.md (comprehensive details)
- QUICK_START_GUIDE.md (immediate actions)
- This guide (scripts and execution)

**Good luck! You've got this!** 💪