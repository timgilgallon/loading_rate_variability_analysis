# Poincare Analysis of Vertical Ground Reaction Force Loading Rates
# Methods Reference: Gait & Posture 110 (2024) 17-22

library(readxl)
library(writexl)
library(ggplot2)

# --- User Inputs ---

import_path <- "data/analyzed_data.xlsx"
export_dir  <- "output/"
leg <- "Left"  # "Left" or "Right"

plot_width  <- 8
plot_height <- 7
plot_dpi    <- 300

# --- Column Mapping ---

loading_rate_cols <- list(
  Left  = "Left_Loading_Rate_BW_s",
  Right = "Right_Loading_Rate_BW_s"
)

# --- Data Import ---

raw_data <- read_excel(import_path)

participant_id <- tools::file_path_sans_ext(basename(import_path))
participant_id <- sub("_analyzed_data$", "", participant_id)

if (!leg %in% names(loading_rate_cols)) {
  stop("Invalid leg selection. Choose 'Left' or 'Right'.")
}

lr_col <- loading_rate_cols[[leg]]
if (!lr_col %in% names(raw_data)) {
  stop(paste0("Column '", lr_col, "' not found in data.\n",
              "Available columns: ", paste(names(raw_data), collapse = ", ")))
}

loading_rate <- as.numeric(raw_data[[lr_col]])
loading_rate <- loading_rate[!is.na(loading_rate)]

cat("=== Poincare Analysis ===\n")
cat("Participant:", participant_id, "\n")
cat("Leg:", leg, "\n")
cat("Number of strides:", length(loading_rate), "\n\n")

# --- Poincare Analysis ---

# Mean-center the time series for comparison across subjects
lr_mean     <- mean(loading_rate)
lr_centered <- loading_rate - lr_mean

# Create Poincare pairs: x(n) vs x(n+1)
n   <- length(lr_centered)
xn  <- lr_centered[1:(n - 1)]
xn1 <- lr_centered[2:n]

# SD1: short-term (stride-to-stride) variability
# SD2: long-term variability across the trial
diff_series <- xn1 - xn
sum_series  <- xn1 + xn

SD1 <- sd(diff_series) / sqrt(2)
SD2 <- sd(sum_series)  / sqrt(2)

SD_overall <- sd(loading_rate)
SD_ratio <- SD1 / SD2

cat("--- Results ---\n")
cat("Mean Loading Rate (BW/s):", round(lr_mean, 4), "\n")
cat("SD of Loading Rate (BW/s):", round(SD_overall, 4), "\n")
cat("SD1 (short-term variability):", round(SD1, 4), "\n")
cat("SD2 (long-term variability):", round(SD2, 4), "\n")
cat("SD1/SD2 ratio:", round(SD_ratio, 4), "\n\n")

# --- Fitting Ellipse ---

# Ellipse centered at origin, rotated 45° (SD1 perpendicular to identity line, SD2 along it)
theta          <- seq(0, 2 * pi, length.out = 360)
rotation_angle <- pi / 4

ellipse_x_raw <- SD1 * cos(theta)
ellipse_y_raw <- SD2 * sin(theta)

ellipse_x <- ellipse_x_raw * cos(rotation_angle) - ellipse_y_raw * sin(rotation_angle)
ellipse_y <- ellipse_x_raw * sin(rotation_angle) + ellipse_y_raw * cos(rotation_angle)

ellipse_df <- data.frame(x = ellipse_x, y = ellipse_y)

# SD1/SD2 axis lines
sd1_line <- data.frame(
  x = c(-SD1 * cos(rotation_angle),  SD1 * cos(rotation_angle)),
  y = c( SD1 * cos(rotation_angle), -SD1 * cos(rotation_angle))
)

sd2_line <- data.frame(
  x = c(-SD2 * cos(rotation_angle), SD2 * cos(rotation_angle)),
  y = c(-SD2 * cos(rotation_angle), SD2 * cos(rotation_angle))
)

# --- Plot ---

poincare_df <- data.frame(xn = xn, xn1 = xn1)

max_range   <- max(abs(c(xn, xn1, ellipse_x, ellipse_y))) * 1.15
axis_limits <- c(-max_range, max_range)

p <- ggplot() +
  geom_path(data = ellipse_df, aes(x = x, y = y),
            color = "red", linewidth = 1, linetype = "solid") +
  geom_line(data = sd1_line, aes(x = x, y = y),
            color = "blue", linewidth = 0.8, linetype = "dashed") +
  geom_line(data = sd2_line, aes(x = x, y = y),
            color = "darkgreen", linewidth = 0.8, linetype = "dashed") +
  geom_abline(intercept = 0, slope = 1, color = "gray60",
              linewidth = 0.4, linetype = "dotted") +
  geom_point(data = poincare_df, aes(x = xn, y = xn1),
             color = "black", size = 2, alpha = 0.7) +
  annotate("text",
           x = max_range * 0.50, y = -max_range * 0.85,
           label = paste0("SD1 = ", round(SD1, 3), " BW/s"),
           color = "blue", size = 4.2, fontface = "bold", hjust = 0) +
  annotate("text",
           x = max_range * 0.50, y = -max_range * 0.95,
           label = paste0("SD2 = ", round(SD2, 3), " BW/s"),
           color = "darkgreen", size = 4.2, fontface = "bold", hjust = 0) +
  labs(
    title = paste0("Poincare Plot - ", participant_id, " (", leg, " Limb)"),
    subtitle = "Vertical GRF Loading Rate Variability (Mean-Centered)",
    x = expression(LR[n] ~ "(BW/s, mean-centered)"),
    y = expression(LR[n+1] ~ "(BW/s, mean-centered)")
  ) +
  coord_fixed(ratio = 1, xlim = axis_limits, ylim = axis_limits) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title       = element_text(face = "bold", size = 14),
    plot.subtitle    = element_text(size = 11, color = "gray40"),
    axis.title       = element_text(size = 12),
    panel.grid.minor = element_blank(),
    plot.background  = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA)
  )

print(p)

# --- Export ---

if (!dir.exists(export_dir)) {
  dir.create(export_dir, recursive = TRUE)
}

plot_filename <- paste0(participant_id, "_", leg, "_poincare_plot.png")
plot_path     <- file.path(export_dir, plot_filename)

ggsave(plot_path, plot = p,
       width = plot_width, height = plot_height, dpi = plot_dpi,
       bg = "white")
cat("Plot saved to:", plot_path, "\n")

results_df <- data.frame(
  Participant_ID       = participant_id,
  Leg                  = leg,
  N_Strides            = length(loading_rate),
  Mean_Loading_Rate    = round(lr_mean, 4),
  SD_Loading_Rate      = round(SD_overall, 4),
  SD1_Short_Term       = round(SD1, 4),
  SD2_Long_Term        = round(SD2, 4),
  SD1_SD2_Ratio        = round(SD_ratio, 4)
)

results_filename <- paste0(participant_id, "_", leg, "_poincare_results.xlsx")
results_path     <- file.path(export_dir, results_filename)

write_xlsx(results_df, results_path)
cat("Results saved to:", results_path, "\n")

cat("\n=== Analysis Complete ===\n")
