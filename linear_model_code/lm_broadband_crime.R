# =============================================================================
# LINEAR MODEL: Broadband Download Speed vs Crime Rate (Drug Offences)
# ST5014CEM - Data Science for Developers
# Counties: Cheshire and Cumberland
# =============================================================================

# Load required libraries
library(tidyverse)
library(ggplot2)
library(scales)
library(broom)

# Set working directory path
base_path <- "."

# Load cleaned data
broadband_agg <- read_csv(file.path(base_path, "cleaned_data/broadband_aggregated.csv"),
                          show_col_types = FALSE)
crime_agg <- read_csv(file.path(base_path, "cleaned_data/crime_aggregated.csv"),
                      show_col_types = FALSE)

# Create Charts directory if not exists
if (!dir.exists(file.path(base_path, "Charts"))) {
  dir.create(file.path(base_path, "Charts"))
}

# =============================================================================
# PREPARE DATA
# =============================================================================

# Aggregate crime data for drug offences
drug_crime <- crime_agg %>%
  filter(crime_type == "Drugs") %>%
  group_by(county, town) %>%
  summarise(
    drug_offence_rate = mean(crime_rate_per_10k, na.rm = TRUE),
    total_drug_crimes = sum(crime_count, na.rm = TRUE),
    .groups = "drop"
  )

# Merge broadband with crime data
merged_broadband_crime <- broadband_agg %>%
  inner_join(drug_crime, by = c("county", "town"))

cat("\n=== Linear Model: Download Speed vs Drug Offence Rate ===\n")
cat("Data points:", nrow(merged_broadband_crime), "\n")

# =============================================================================
# FIT LINEAR MODEL
# =============================================================================

# Fit linear model: Download Speed ~ Drug Offence Rate
model_broadband_crime <- lm(avg_download_speed ~ drug_offence_rate, data = merged_broadband_crime)

# Print model summary
cat("\nModel Summary:\n")
print(summary(model_broadband_crime))

# Get tidy model results
model_results <- tidy(model_broadband_crime)
cat("\nCoefficients:\n")
print(model_results)

# Calculate R-squared
r_squared <- glance(model_broadband_crime)$r.squared
cat("\nR-squared:", round(r_squared, 4), "\n")

# Get confidence intervals
cat("\n95% Confidence Intervals:\n")
print(confint(model_broadband_crime))

# =============================================================================
# DIAGNOSTIC PLOTS
# =============================================================================

# Residuals analysis
cat("\nResiduals Summary:\n")
print(summary(model_broadband_crime$residuals))

# =============================================================================
# CREATE VISUALISATION
# =============================================================================

# Scatter plot with regression line
plot_broadband_crime <- ggplot(merged_broadband_crime, aes(x = drug_offence_rate, y = avg_download_speed, color = county)) +
  geom_point(alpha = 0.7, size = 3) +
  geom_smooth(method = "lm", se = TRUE, linetype = "dashed", color = "black", alpha = 0.3) +
  scale_y_continuous(labels = label_number(suffix = " Mbit/s")) +
  scale_color_manual(values = c("Cheshire" = "#2E86AB", "Cumberland" = "#A23B72")) +
  labs(
    title = "Download Speed vs Drug Offence Rate",
    subtitle = paste0("Linear Regression (R² = ", round(r_squared, 3), ")"),
    x = "Drug Offence Rate (per 10,000 population)",
    y = "Average Download Speed (Mbit/s)",
    color = "County",
    caption = "Data: Ofcom Broadband Data & UK Police Crime Data"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10, color = "grey40"),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

# Add regression equation if coefficients exist
if (!is.na(coef(model_broadband_crime)[2])) {
  plot_broadband_crime <- plot_broadband_crime +
    annotate("text", 
             x = max(merged_broadband_crime$drug_offence_rate, na.rm = TRUE) * 0.7,
             y = max(merged_broadband_crime$avg_download_speed, na.rm = TRUE) * 0.9,
             label = paste0("y = ", round(coef(model_broadband_crime)[1], 2), " + ", 
                           round(coef(model_broadband_crime)[2], 4), "x"),
             size = 4, fontface = "italic")
}

# Save plot
ggsave(
  filename = file.path(base_path, "Charts/linear_model_broadband_crime.png"),
  plot = plot_broadband_crime,
  width = 10,
  height = 7,
  dpi = 300
)

cat("\nSaved: Charts/linear_model_broadband_crime.png\n")

# =============================================================================
# MODEL INTERPRETATION
# =============================================================================

cat("\n=== Model Interpretation ===\n")
cat("This model examines the relationship between drug offence rates\n")
cat("and broadband download speeds in Cheshire and Cumberland.\n\n")

if (r_squared > 0.5) {
  cat("Strong relationship: R² =", round(r_squared, 3), "\n")
} else if (r_squared > 0.3) {
  cat("Moderate relationship: R² =", round(r_squared, 3), "\n")
} else {
  cat("Weak relationship: R² =", round(r_squared, 3), "\n")
}

# Check coefficient sign
if (!is.na(coef(model_broadband_crime)[2])) {
  if (coef(model_broadband_crime)[2] < 0) {
    cat("Negative correlation: Higher crime rates associated with slower broadband.\n")
  } else {
    cat("Positive correlation: Higher crime rates associated with faster broadband.\n")
  }
}

cat("\n=== Broadband vs Crime Model Complete! ===\n")
