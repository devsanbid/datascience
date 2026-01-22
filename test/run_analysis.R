# =============================================================================
# MAIN RUNNER SCRIPT
# ST5014CEM - Data Science for Developers
# Run this script to execute the entire analysis pipeline
# =============================================================================

# Set working directory to project root
# Uncomment and modify the path if needed
# setwd("/path/to/datascience_assignment")

cat("
================================================================================
  ST5014CEM - DATA SCIENCE FOR DEVELOPERS
  Counties: Cheshire and Cumberland
================================================================================
")

# Install required packages if not available
required_packages <- c("tidyverse", "ggplot2", "scales", "lubridate", "broom")

install_if_missing <- function(packages) {
  new_packages <- packages[!(packages %in% installed.packages()[, "Package"])]
  if (length(new_packages) > 0) {
    cat("Installing missing packages:", paste(new_packages, collapse = ", "), "\n")
    install.packages(new_packages, repos = "https://cloud.r-project.org/")
  }
}

cat("\nChecking required packages...\n")
install_if_missing(required_packages)

# =============================================================================
# STEP 1: DATA CLEANING
# =============================================================================

cat("\n")
cat("================================================================================\n")
cat("STEP 1: DATA CLEANING\n")
cat("================================================================================\n")

source("clean_code_script/data_cleaning.R")

# =============================================================================
# STEP 2: EDA - HOUSE PRICE VISUALISATIONS
# =============================================================================

cat("\n")
cat("================================================================================\n")
cat("STEP 2: EDA - HOUSE PRICE VISUALISATIONS\n")
cat("================================================================================\n")

source("EDA_code/eda_house_price.R")

# =============================================================================
# STEP 3: EDA - BROADBAND SPEED VISUALISATIONS
# =============================================================================

cat("\n")
cat("================================================================================\n")
cat("STEP 3: EDA - BROADBAND SPEED VISUALISATIONS\n")
cat("================================================================================\n")

source("EDA_code/eda_broadband.R")

# =============================================================================
# STEP 4: EDA - CRIME RATE VISUALISATIONS
# =============================================================================

cat("\n")
cat("================================================================================\n")
cat("STEP 4: EDA - CRIME RATE VISUALISATIONS\n")
cat("================================================================================\n")

source("EDA_code/eda_crime.R")

# =============================================================================
# STEP 5: LINEAR MODEL - House Price vs Broadband
# =============================================================================

cat("\n")
cat("================================================================================\n")
cat("STEP 5: LINEAR MODEL - House Price vs Broadband\n")
cat("================================================================================\n")

source("linear_model_code/lm_house_price_broadband.R")

# =============================================================================
# STEP 6: LINEAR MODEL - House Price vs Crime
# =============================================================================

cat("\n")
cat("================================================================================\n")
cat("STEP 6: LINEAR MODEL - House Price vs Crime\n")
cat("================================================================================\n")

source("linear_model_code/lm_house_price_crime.R")

# =============================================================================
# STEP 7: LINEAR MODEL - Broadband vs Crime
# =============================================================================

cat("\n")
cat("================================================================================\n")
cat("STEP 7: LINEAR MODEL - Broadband vs Crime\n")
cat("================================================================================\n")

source("linear_model_code/lm_broadband_crime.R")

# =============================================================================
# FINAL SUMMARY
# =============================================================================

cat("\n")
cat("================================================================================\n")
cat("ANALYSIS COMPLETE!\n")
cat("================================================================================\n")
cat("\n")
cat("Output Files Generated:\n")
cat("------------------------\n")
cat("\nCleaned Data (cleaned_data/):\n")
cat("  - house_price_cleaned.csv\n")
cat("  - house_price_aggregated.csv\n")
cat("  - broadband_cleaned.csv\n")
cat("  - broadband_aggregated.csv\n")
cat("  - crime_cleaned.csv\n")
cat("  - crime_aggregated.csv\n")
cat("  - population_cleaned.csv\n")

cat("\nCharts (Charts/):\n")
cat("  - house_price_boxplot_2023.png\n")
cat("  - house_price_bar_2022.png\n")
cat("  - house_price_trend_2022_2024.png\n")
cat("  - broadband_boxplot_cheshire.png\n")
cat("  - broadband_boxplot_cumberland.png\n")
cat("  - broadband_stacked_bar_cheshire.png\n")
cat("  - broadband_stacked_bar_cumberland.png\n")
cat("  - crime_drug_boxplot.png\n")
cat("  - crime_vehicle_radar.png\n")
cat("  - crime_robbery_pie.png\n")
cat("  - crime_drug_trend.png\n")
cat("  - linear_model_hp_broadband.png\n")
cat("  - linear_model_hp_crime.png\n")
cat("  - linear_model_broadband_crime.png\n")

cat("\nReport Structure (Report/):\n")
cat("  - report_outline.txt\n")

cat("\n================================================================================\n")
cat("All tasks completed successfully!\n")
cat("================================================================================\n")
