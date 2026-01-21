# Calculate Real Statistics from Project Data
# This script extracts actual statistics for the documentation

library(tidyverse)

base_path <- "."

# Load all cleaned data
house_price <- read_csv(file.path(base_path, "cleaned_data/house_price_cleaned.csv"), show_col_types = FALSE)
broadband <- read_csv(file.path(base_path, "cleaned_data/broadband_cleaned.csv"), show_col_types = FALSE)
crime <- read_csv(file.path(base_path, "cleaned_data/crime_cleaned.csv"), show_col_types = FALSE)
crime_agg <- read_csv(file.path(base_path, "cleaned_data/crime_aggregated.csv"), show_col_types = FALSE)

cat("\n========================================\n")
cat("REAL STATISTICS FROM YOUR PROJECT DATA\n")
cat("========================================\n\n")

# =============================================================================
# 1. HOUSE PRICE STATISTICS
# =============================================================================
cat("=== HOUSE PRICE STATISTICS ===\n\n")

# Overall counts
cat("Total transactions:", nrow(house_price), "\n")
cat("Cheshire transactions:", nrow(filter(house_price, county == "Cheshire")), "\n")
cat("Cumberland transactions:", nrow(filter(house_price, county == "Cumberland")), "\n\n")

# By county
hp_by_county <- house_price %>%
  group_by(county) %>%
  summarise(
    mean_price = mean(price, na.rm = TRUE),
    median_price = median(price, na.rm = TRUE),
    min_price = min(price, na.rm = TRUE),
    max_price = max(price, na.rm = TRUE),
    sd_price = sd(price, na.rm = TRUE),
    n = n()
  )
cat("House Price by County:\n")
print(hp_by_county)

# By year and county
hp_by_year <- house_price %>%
  group_by(county, year) %>%
  summarise(
    mean_price = mean(price, na.rm = TRUE),
    median_price = median(price, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  )
cat("\nHouse Price by Year and County:\n")
print(hp_by_year)

# T-test for house prices
hp_ttest <- t.test(price ~ county, data = house_price)
cat("\nT-Test House Prices (Cheshire vs Cumberland):\n")
cat("t-statistic:", round(hp_ttest$statistic, 2), "\n")
cat("df:", round(hp_ttest$parameter, 0), "\n")
cat("p-value:", format(hp_ttest$p.value, scientific = TRUE), "\n")

# =============================================================================
# 2. BROADBAND STATISTICS
# =============================================================================
cat("\n=== BROADBAND STATISTICS ===\n\n")

cat("Total postcode records:", nrow(broadband), "\n")
cat("Cheshire postcodes:", nrow(filter(broadband, county == "Cheshire")), "\n")
cat("Cumberland postcodes:", nrow(filter(broadband, county == "Cumberland")), "\n\n")

bb_by_county <- broadband %>%
  group_by(county) %>%
  summarise(
    mean_download = mean(avg_download_speed, na.rm = TRUE),
    median_download = median(avg_download_speed, na.rm = TRUE),
    max_download = max(max_download_speed, na.rm = TRUE),
    min_download = min(avg_download_speed, na.rm = TRUE),
    sd_download = sd(avg_download_speed, na.rm = TRUE),
    n = n()
  )
cat("Broadband Speed by County:\n")
print(bb_by_county)

# T-test for broadband
bb_ttest <- t.test(avg_download_speed ~ county, data = broadband)
cat("\nT-Test Broadband Speed (Cheshire vs Cumberland):\n")
cat("t-statistic:", round(bb_ttest$statistic, 2), "\n")
cat("df:", round(bb_ttest$parameter, 0), "\n")
cat("p-value:", format(bb_ttest$p.value, scientific = TRUE), "\n")

# =============================================================================
# 3. CRIME STATISTICS
# =============================================================================
cat("\n=== CRIME STATISTICS ===\n\n")

cat("Total crime records:", nrow(crime), "\n")
cat("Cheshire crimes:", nrow(filter(crime, county == "Cheshire")), "\n")
cat("Cumberland crimes:", nrow(filter(crime, county == "Cumberland")), "\n\n")

crime_by_county_type <- crime %>%
  group_by(county, crime_type) %>%
  summarise(
    total_crimes = n(),
    .groups = "drop"
  )
cat("Crime Counts by County and Type:\n")
print(crime_by_county_type)

# Drug offences aggregated
drug_rates <- crime_agg %>%
  filter(crime_type == "Drugs") %>%
  group_by(county) %>%
  summarise(
    mean_rate = mean(crime_rate_per_10k, na.rm = TRUE),
    total_crimes = sum(crime_count, na.rm = TRUE),
    .groups = "drop"
  )
cat("\nDrug Offence Rates by County (per 10,000):\n")
print(drug_rates)

# T-test for crime rates
drug_data <- crime_agg %>% filter(crime_type == "Drugs")
if(nrow(drug_data) > 0) {
  crime_ttest <- t.test(crime_rate_per_10k ~ county, data = drug_data)
  cat("\nT-Test Crime Rate (Cheshire vs Cumberland):\n")
  cat("t-statistic:", round(crime_ttest$statistic, 2), "\n")
  cat("df:", round(crime_ttest$parameter, 0), "\n")
  cat("p-value:", format(crime_ttest$p.value, scientific = TRUE), "\n")
}

# =============================================================================
# 4. CORRELATION ANALYSIS
# =============================================================================
cat("\n=== CORRELATION ANALYSIS ===\n\n")

# Aggregate data for correlation
hp_agg <- house_price %>%
  group_by(county, town) %>%
  summarise(avg_price = mean(price, na.rm = TRUE), .groups = "drop")

bb_agg <- broadband %>%
  group_by(county, town) %>%
  summarise(avg_speed = mean(avg_download_speed, na.rm = TRUE), .groups = "drop")

drug_agg <- crime_agg %>%
  filter(crime_type == "Drugs") %>%
  group_by(county, town) %>%
  summarise(drug_rate = mean(crime_rate_per_10k, na.rm = TRUE), .groups = "drop")

# Merge for correlations
merged_1 <- inner_join(hp_agg, bb_agg, by = c("county", "town"))
merged_2 <- inner_join(hp_agg, drug_agg, by = c("county", "town"))
merged_3 <- inner_join(bb_agg, drug_agg, by = c("county", "town"))

# Correlation 1: House Price vs Broadband
if(nrow(merged_1) >= 3) {
  cor_hp_bb <- cor.test(merged_1$avg_price, merged_1$avg_speed)
  cat("Correlation: House Price vs Broadband Speed\n")
  cat("  r =", round(cor_hp_bb$estimate, 4), "\n")
  cat("  p-value =", format(cor_hp_bb$p.value, scientific = TRUE), "\n")
  cat("  95% CI: [", round(cor_hp_bb$conf.int[1], 4), ",", round(cor_hp_bb$conf.int[2], 4), "]\n")
  cat("  Data points:", nrow(merged_1), "\n\n")
}

# Correlation 2: House Price vs Crime
if(nrow(merged_2) >= 3) {
  cor_hp_crime <- cor.test(merged_2$avg_price, merged_2$drug_rate)
  cat("Correlation: House Price vs Drug Crime Rate\n")
  cat("  r =", round(cor_hp_crime$estimate, 4), "\n")
  cat("  p-value =", format(cor_hp_crime$p.value, scientific = TRUE), "\n")
  cat("  95% CI: [", round(cor_hp_crime$conf.int[1], 4), ",", round(cor_hp_crime$conf.int[2], 4), "]\n")
  cat("  Data points:", nrow(merged_2), "\n\n")
}

# Correlation 3: Broadband vs Crime
if(nrow(merged_3) >= 3) {
  cor_bb_crime <- cor.test(merged_3$avg_speed, merged_3$drug_rate)
  cat("Correlation: Broadband Speed vs Drug Crime Rate\n")
  cat("  r =", round(cor_bb_crime$estimate, 4), "\n")
  cat("  p-value =", format(cor_bb_crime$p.value, scientific = TRUE), "\n")
  cat("  95% CI: [", round(cor_bb_crime$conf.int[1], 4), ",", round(cor_bb_crime$conf.int[2], 4), "]\n")
  cat("  Data points:", nrow(merged_3), "\n\n")
}

# =============================================================================
# 5. LINEAR REGRESSION RESULTS
# =============================================================================
cat("\n=== LINEAR REGRESSION MODELS ===\n\n")

# Model 1: House Price ~ Broadband
if(nrow(merged_1) >= 3) {
  lm1 <- lm(avg_price ~ avg_speed, data = merged_1)
  cat("Linear Model: House Price ~ Broadband Speed\n")
  cat("  R-squared:", round(summary(lm1)$r.squared, 4), "\n")
  cat("  Adj R-squared:", round(summary(lm1)$adj.r.squared, 4), "\n")
  cat("  F-statistic:", round(summary(lm1)$fstatistic[1], 2), "\n\n")
}

# Model 2: House Price ~ Crime
if(nrow(merged_2) >= 3) {
  lm2 <- lm(avg_price ~ drug_rate, data = merged_2)
  cat("Linear Model: House Price ~ Drug Crime Rate\n")
  cat("  R-squared:", round(summary(lm2)$r.squared, 4), "\n")
  cat("  Adj R-squared:", round(summary(lm2)$adj.r.squared, 4), "\n")
  cat("  F-statistic:", round(summary(lm2)$fstatistic[1], 2), "\n\n")
}

# Model 3: Broadband ~ Crime
if(nrow(merged_3) >= 3) {
  lm3 <- lm(avg_speed ~ drug_rate, data = merged_3)
  cat("Linear Model: Broadband Speed ~ Drug Crime Rate\n")
  cat("  R-squared:", round(summary(lm3)$r.squared, 4), "\n")
  cat("  Adj R-squared:", round(summary(lm3)$adj.r.squared, 4), "\n")
  cat("  F-statistic:", round(summary(lm3)$fstatistic[1], 2), "\n\n")
}

# =============================================================================
# 6. SUMMARY FOR DOCUMENTATION
# =============================================================================
cat("\n========================================\n")
cat("SUMMARY FOR DOCUMENTATION\n")
cat("========================================\n\n")

cheshire_hp <- filter(hp_by_county, county == "Cheshire")
cumberland_hp <- filter(hp_by_county, county == "Cumberland")
cheshire_bb <- filter(bb_by_county, county == "Cheshire")
cumberland_bb <- filter(bb_by_county, county == "Cumberland")

cat("HOUSE PRICES:\n")
cat("  Cheshire Mean: £", format(round(cheshire_hp$mean_price), big.mark=","), "\n", sep="")
cat("  Cheshire Median: £", format(round(cheshire_hp$median_price), big.mark=","), "\n", sep="")
cat("  Cumberland Mean: £", format(round(cumberland_hp$mean_price), big.mark=","), "\n", sep="")
cat("  Cumberland Median: £", format(round(cumberland_hp$median_price), big.mark=","), "\n", sep="")
cat("  Price Difference: £", format(round(cheshire_hp$mean_price - cumberland_hp$mean_price), big.mark=","), "\n", sep="")
cat("  Price Premium: ", round((cheshire_hp$mean_price / cumberland_hp$mean_price - 1) * 100, 1), "%\n\n", sep="")

cat("BROADBAND:\n")
cat("  Cheshire Mean Speed:", round(cheshire_bb$mean_download, 1), "Mbit/s\n")
cat("  Cumberland Mean Speed:", round(cumberland_bb$mean_download, 1), "Mbit/s\n\n")

cat("T-TEST RESULTS:\n")
cat("  House Price: t =", round(hp_ttest$statistic, 2), ", df =", round(hp_ttest$parameter, 0), 
    ", p =", format(hp_ttest$p.value, scientific = TRUE), "\n")
cat("  Broadband: t =", round(bb_ttest$statistic, 2), ", df =", round(bb_ttest$parameter, 0),
    ", p =", format(bb_ttest$p.value, scientific = TRUE), "\n")

cat("\nDone! Use these values in your documentation.\n")
