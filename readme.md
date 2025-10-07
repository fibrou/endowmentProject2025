# Endowment Portfolio Analysis - Modular Structure

## Project Overview

This project implements a comprehensive endowment portfolio analysis framework using vine copula methodology and traditional portfolio optimization techniques. The document is structured as a Quarto book with modular chapters for easier maintenance and development.

## File Structure

```
project/
├── _quarto.yml                    # Main configuration file
├── _common.R                      # Global setup and shared objects
├── index.qmd                      # Abstract and front matter
├── references.bib                 # Bibliography file
├── latestEndowData.rds           # Raw data file (required)
├── data/                          # Created automatically
│   ├── processed_data.rds        # Processed datasets
│   ├── portfolio_objects.rds     # Portfolio optimization results
│   └── vine_results.rds          # Vine copula simulation results
├── Core Chapters/
│   ├── 01-introduction.qmd
│   ├── 02-literature-review.qmd
│   ├── 03-data-analysis.qmd
│   ├── 04-portfolio-optimization.qmd
│   ├── 05-vine-copula-analysis.qmd
│   └── 06-conclusions.qmd
└── Appendices/
    ├── A1-vine-copula-details.qmd
    ├── A2-performance-attribution.qmd
    └── A3-technical-appendix.qmd
```

## Installation Steps

### 1. Prerequisites

Ensure you have:
- R (version 4.0 or higher)
- RStudio (recommended)
- Quarto CLI installed
- LaTeX distribution (TinyTeX recommended)

### 2. Install Required R Packages

```r
# Install core packages
install.packages(c(
  "tidyverse", "xts", "timeSeries", "fPortfolio",
  "PerformanceAnalytics", "Hmisc", "pastecs",
  "kableExtra", "moments"
))

# Install copula packages
install.packages(c(
  "copula", "VineCopula", "rvinecopulib"
))

# Install ESGtoolkit
install.packages("esgtoolkit")
```

### 3. Install Quarto

If not already installed:
```bash
# Visit https://quarto.org/docs/get-started/
# Or use R:
install.packages("quarto")
```

### 4. Install TinyTeX (for PDF output)

```r
install.packages("tinytex")
tinytex::install_tinytex()
```

### 5. Project Setup

1. Create a new directory for your project
2. Copy all 13 files from the artifacts into this directory
3. Ensure `latestEndowData.rds` is in the project root
4. Ensure you have a `references.bib` file (even if empty initially)

### 6. First Render

```bash
# In terminal/command prompt, navigate to project directory
cd path/to/your/project

# Render the entire book
quarto render
```

Or in RStudio:
- Open the project
- Click "Render" button
- Or use: Build > Render Book

## How the Modular System Works

### Data Flow

1. **`_common.R`** runs first and:
   - Loads all required libraries
   - Reads `latestEndowData.rds`
   - Creates processed datasets
   - Runs portfolio optimizations
   - Runs vine copula simulations
   - Saves results to `data/` folder
   - Makes all objects globally available

2. **Each chapter**:
   - Sources `_common.R` at the beginning
   - Has access to all pre-computed objects
   - Renders independently (after initial data processing)

### Computational Efficiency

- **First render**: Takes 15-30 minutes (computes everything)
- **Subsequent renders**: 2-5 minutes (uses cached results)
- **Individual chapter edits**: Only re-renders that chapter

### Cached Objects

The system caches expensive computations:

| File | Contents | Computation Time |
|------|----------|------------------|
| `processed_data.rds` | Basic data transformations | ~5 seconds |
| `portfolio_objects.rds` | Efficient frontiers, MVP, tangency | ~30 seconds |
| `vine_results.rds` | Vine copula fitting & simulation | ~10-15 minutes |

To force recalculation, delete the relevant `.rds` file from `data/` folder.

## Rendering Options

### Render Entire Book
```bash
quarto render
```

### Render Single Chapter
```bash
quarto render 03-data-analysis.qmd
```

### Preview While Editing
```bash
quarto preview
```

### Render to Different Formats

In `_quarto.yml`, add formats:
```yaml
format:
  pdf:
    # PDF settings
  html:
    # HTML settings
  docx:
    # Word settings
```

## Troubleshooting

### "Object not found" errors

**Problem**: Chapter can't find objects like `endow_data`, `mvp`, etc.

**Solution**: 
- Ensure `source("_common.R")` is at the top of each chapter
- Check that `data/` folder exists and contains the `.rds` files
- Try deleting cached files and re-rendering

### "Package not found" errors

**Problem**: R can't find required packages

**Solution**:
```r
# Run this to check what's missing
required_packages <- c("tidyverse", "xts", "timeSeries", "fPortfolio",
                       "PerformanceAnalytics", "Hmisc", "pastecs",
                       "kableExtra", "moments", "copula", "VineCopula",
                       "esgtoolkit", "rvinecopulib")

missing_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]
if(length(missing_packages)) install.packages(missing_packages)
```

### Long render times

**Problem**: First render takes 20+ minutes

**Solution**: This is normal. Vine copula fitting is computationally expensive. Subsequent renders use cached results and are much faster.

To reduce time during development:
- Work on individual chapters
- Use `cache: true` in chunk options (already set)
- Don't delete `data/*.rds` files unless necessary

### LaTeX errors

**Problem**: PDF generation fails with LaTeX errors

**Solution**:
```r
# Reinstall TinyTeX
tinytex::reinstall_tinytex()

# Or install missing packages
tinytex::tlmgr_install("package-name")
```

### Memory issues

**Problem**: R runs out of memory during vine copula fitting

**Solution**:
- Close other applications
- Increase R memory limit:
```r
# Windows
memory.limit(size = 16000)  # 16GB

# macOS/Linux (set in .Renviron)
R_MAX_VSIZE=16Gb
```

## Customization

### Modify which chapters are included

Edit `_quarto.yml`:
```yaml
chapters:
  - index.qmd
  - 01-introduction.qmd
  # Comment out chapters you don't want:
  # - 02-literature-review.qmd
  - 03-data-analysis.qmd
```

### Change figure sizes globally

Edit `_common.R`:
```r
knitr::opts_chunk$set(
  fig.width = 8,   # Change this
  fig.height = 6   # Change this
)
```

### Add new chapters

1. Create new `.qmd` file (e.g., `07-new-analysis.qmd`)
2. Start with:
```markdown
---
title: "Your Chapter Title"
---

```{r}
#| label: setup-ch7
#| include: false
source("_common.R")
```

# Your content here
```
3. Add to `_quarto.yml` chapters list

### Modify optimization parameters

Edit `_common.R` to change portfolio specifications:
```r
# Example: Change risk-free rate
setRiskFreeRate(spec_long) <- 0.02  # Change from 0 to 2%

# Example: Add constraints
setMaxsumW(spec_long) <- c("SP500" = 0.30)  # Max 30% in S&P 500
```

## Working with the Modular Structure

### Best Practices

1. **Never edit `_common.R` and individual chapters simultaneously**
   - Changes to `_common.R` affect all chapters
   - Test changes by rendering one chapter first

2. **Use descriptive chunk labels**
   - Already done in provided files
   - Format: `#| label: descriptive-name`

3. **Keep chapters focused**
   - Each chapter should have a clear purpose
   - Move detailed analyses to appendices

4. **Document dependencies**
   - If a chapter needs specific objects, note it at the top
   - Example: `# Requires: result, vine_fit (from _common.R)`

### Workflow for Development

1. **Adding new analysis**:
   - Add computation to `_common.R` if expensive
   - Add visualization/table to appropriate chapter
   - Test render of that chapter only

2. **Modifying existing analysis**:
   - If changing data/computation → edit `_common.R`
   - If changing presentation → edit chapter file
   - Delete cached `.rds` if data changed

3. **Before final submission**:
   - Delete all files in `data/` folder
   - Delete `_freeze/` folder if it exists
   - Run `quarto render` for clean build
   - Review PDF for consistency

## Performance Benchmarks

Expected render times (on modern laptop):

| Operation | First Run | Subsequent |
|-----------|-----------|------------|
| Data processing | ~5 sec | <1 sec |
| Portfolio optimization | ~30 sec | <1 sec |
| Vine copula fitting | ~10 min | <1 sec |
| Full document | ~25 min | ~3 min |
| Single chapter | ~15 min | ~30 sec |

## File Size Management

Generated files can be large:

- `vine_results.rds`: ~50-100 MB
- `portfolio_objects.rds`: ~5-10 MB
- Final PDF: ~2-5 MB

Consider:
- Adding `data/` to `.gitignore`
- Using Git LFS for large data files
- Compressing PDF for distribution

## Citation Management

Bibliography is managed through `references.bib`:

1. Add entries in BibTeX format
2. Cite in text: `[@author2020]`
3. Multiple citations: `[@author2020; @author2021]`
4. In-text: `@author2020 showed that...`

## Version Control Recommendations

Suggested `.gitignore`:
```
# Quarto outputs
_output/
_freeze/
*.pdf

# R artifacts
.Rhistory
.RData
.Rproj.user

# Data (regenerated from _common.R)
data/*.rds

# Keep the raw data
!latestEndowData.rds

# LaTeX intermediate files
*.aux
*.log
*.out
```

## Getting Help

1. **Quarto issues**: https://quarto.org/docs/
2. **R package documentation**: `?function_name` in R
3. **Vine copulas**: `vignette("rvinecopulib")`
4. **fPortfolio**: `vignette("fPortfolio")`

## Next Steps

After successful installation:

1. Render the full document once to create all cached objects
2. Read through each chapter to understand the flow
3. Modify individual chapters as needed
4. Use appendices for additional technical details
5. Update `references.bib` with your citations

## Maintenance Notes

- Cache files in `data/` are safe to delete (will regenerate)
- Never commit large `.rds` files to version control
- Test major changes on a single chapter first
- Keep `_common.R` focused on shared objects only

---

**Project Structure Version**: 1.0  
**Last Updated**: 2024  
**Authors**: John Paul Broussard, G. Geoffrey Booth, Ryan Timmer