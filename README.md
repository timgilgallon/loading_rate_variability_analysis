# loading_rate_variability_analysis

# Poincare Analysis of Gait Loading Rate Variability

R script for quantifying stride-to-stride variability in vertical ground reaction force loading rates during walking. Generates a Poincare plot with SD1/SD2 fitting ellipse and exports numerical results.

## Background

Poincare analysis plots each stride's loading rate against the subsequent stride, revealing the structure of gait variability. The fitting ellipse captures two components:

| Metric | Meaning |
|--------|---------|
| **SD1** | Short-term (stride-to-stride) variability — ellipse width |
| **SD2** | Long-term variability across the trial — ellipse length |
| **SD1/SD2** | Ratio characterizing variability structure |

Lower SD1 suggests more consistent stride-to-stride control. The ratio provides insight into neuromuscular regulation of gait.

Based on methods from: *Gait & Posture* 110 (2024) 17–22

## Requirements

```r
install.packages(c("readxl", "writexl", "ggplot2"))
```

## Usage

1. Place your analyzed gait data in the `data/` folder
2. Open `poincare_analysis.R` and modify the user inputs:

```r
import_path <- "data/analyzed_data.xlsx"
export_dir  <- "output/"
leg <- "Left"  # "Left" or "Right"
```

3. Run the script

## Input Format

Excel file with a column for loading rate values per stride:

| Required Column | Description |
|-----------------|-------------|
| `Left_Loading_Rate_BW_s` | Left limb loading rate in BW/s |
| `Right_Loading_Rate_BW_s` | Right limb loading rate in BW/s |

Each row represents one stride.

## Output

| File | Contents |
|------|----------|
| `[id]_[leg]_poincare_plot.png` | Poincare plot with SD1/SD2 ellipse overlay |
| `[id]_[leg]_poincare_results.xlsx` | Numerical results (mean, SD, SD1, SD2, ratio) |

## Example Output

![Poincare Plot](output/example_poincare.png)

## License

MIT
