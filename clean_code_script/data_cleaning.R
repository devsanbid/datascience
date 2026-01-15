# =============================================================================
# DATA CLEANING SCRIPT
# ST5014CEM - Data Science for Developers
# Counties: Cheshire and Cumberland (Cumbria)
# =============================================================================

# Load required libraries
library(tidyverse)
library(lubridate)

# Set working directory path
base_path <- "."

# =============================================================================
# 1. LOAD AND CLEAN HOUSE PRICE DATA
# =============================================================================

clean_house_price_data <- function() {
  cat("Loading house price data...\n")
  
  # Define column names for house price data (Land Registry format)
  col_names <- c(
    "transaction_id", "price", "date_of_transfer", "postcode",
    "property_type", "old_new", "duration", "paon", "saon",
    "street", "locality", "town", "district", "county", "ppd_cat", "record_status"
  )
  
  # Load data for each year
  hp_2022 <- read_csv(
    file.path(base_path, "obtained_data/house_price/2022/pp-2022.csv"),
    col_names = col_names,
    show_col_types = FALSE
  )
  
  hp_2023 <- read_csv(
    file.path(base_path, "obtained_data/house_price/2023/pp-2023.csv"),
    col_names = col_names,
    show_col_types = FALSE
  )
  
  hp_2024 <- read_csv(
    file.path(base_path, "obtained_data/house_price/2024/pp-2024.csv"),
    col_names = col_names,
    show_col_types = FALSE
  )
  
  # Combine all years
  house_price_all <- bind_rows(
    hp_2022 %>% mutate(year = 2022),
    hp_2023 %>% mutate(year = 2023),
    hp_2024 %>% mutate(year = 2024)
  )
  
  # Filter for Cheshire and Cumberland (Cumbria) counties only
  cheshire_districts <- c("CHESHIRE EAST", "CHESHIRE WEST AND CHESTER")
  cumberland_districts <- c("CUMBERLAND", "ALLERDALE", "CARLISLE", "COPELAND")
  
  house_price_filtered <- house_price_all %>%
    mutate(
      county = toupper(county),
      district = toupper(district),
      town = toupper(town)
    ) %>%
    filter(
      county %in% c("CHESHIRE", "CUMBRIA") |
      district %in% c(cheshire_districts, cumberland_districts)
    ) %>%
    mutate(
      county_group = case_when(
        county == "CHESHIRE" | district %in% cheshire_districts ~ "Cheshire",
        county == "CUMBRIA" | district %in% cumberland_districts ~ "Cumberland",
        TRUE ~ NA_character_
      )
    ) %>%
    filter(!is.na(county_group))
  
  # Clean and standardize
  house_price_clean <- house_price_filtered %>%
    select(
      transaction_id,
      price,
      date_of_transfer,
      postcode,
      town,
      district,
      county = county_group,
      year
    ) %>%
    filter(!is.na(price), price > 0) %>%
    mutate(
      price = as.numeric(price),
      postcode = str_trim(postcode),
      town = str_to_title(town)
    )
  
  cat("House price data cleaned. Rows:", nrow(house_price_clean), "\n")
  return(house_price_clean)
}

# =============================================================================
# 2. LOAD AND CLEAN BROADBAND SPEED DATA
# =============================================================================

clean_broadband_data <- function() {
  cat("Loading broadband data...\n")
  
  # Load broadband performance data
  broadband_raw <- read_csv(
    file.path(base_path, "obtained_data/broadband_speed/201805_fixed_pc_performance_r03.csv"),
    show_col_types = FALSE
  )
  
  # Load postcode to LSOA mapping for county identification
  postcode_lsoa <- read_csv(
    file.path(base_path, "obtained_data/LSOA/postcode_to_lsoa.csv"),
    show_col_types = FALSE
  )
  
  # Clean column names
  broadband_clean <- broadband_raw %>%
    rename(
      postcode = 1,
      postcode_space = 2,
      postcode_area = 3,
      median_download_speed = 4,
      avg_download_speed = 5,
      min_download_speed = 6,
      max_download_speed = 7
    ) %>%
    select(
      postcode,
      postcode_space,
      avg_download_speed,
      max_download_speed
    ) %>%
    filter(!is.na(avg_download_speed))
  
  # Join with LSOA data to get county information
  postcode_lsoa_clean <- postcode_lsoa %>%
    select(pcds, ladnm) %>%
    rename(postcode = pcds, local_authority = ladnm) %>%
    mutate(postcode = str_replace_all(postcode, " ", ""))
  
  # Define Cheshire and Cumberland local authorities
  cheshire_la <- c("Cheshire East", "Cheshire West and Chester")
  cumberland_la <- c("Cumberland", "Allerdale", "Carlisle", "Copeland")
  
  # Join and filter
  broadband_filtered <- broadband_clean %>%
    mutate(postcode_join = str_replace_all(postcode, " ", "")) %>%
    left_join(postcode_lsoa_clean, by = c("postcode_join" = "postcode")) %>%
    filter(
      local_authority %in% c(cheshire_la, cumberland_la)
    ) %>%
    mutate(
      county = case_when(
        local_authority %in% cheshire_la ~ "Cheshire",
        local_authority %in% cumberland_la ~ "Cumberland",
        TRUE ~ NA_character_
      )
    ) %>%
    filter(!is.na(county))
  
  # Extract town from postcode area (approximate)
  broadband_final <- broadband_filtered %>%
    select(
      postcode = postcode_space,
      avg_download_speed,
      max_download_speed,
      local_authority,
      county
    ) %>%
    rename(town = local_authority) %>%
    mutate(
      avg_download_speed = as.numeric(avg_download_speed),
      max_download_speed = as.numeric(max_download_speed)
    ) %>%
    filter(!is.na(avg_download_speed))
  
  cat("Broadband data cleaned. Rows:", nrow(broadband_final), "\n")
  return(broadband_final)
}

# =============================================================================
# 3. LOAD AND CLEAN CRIME DATA
# =============================================================================

clean_crime_data <- function() {
  cat("Loading crime data...\n")
  
  # Get all crime data directories
  crime_base <- file.path(base_path, "obtained_data/crime")
  crime_dirs <- list.dirs(crime_base, recursive = FALSE)
  
  # Function to load crime files from a directory
  load_crime_files <- function(dir_path) {
    files <- list.files(dir_path, pattern = "\\.csv$", full.names = TRUE)
    
    # Filter for cheshire and cumbria files only
    cheshire_files <- files[grepl("cheshire", files, ignore.case = TRUE)]
    cumbria_files <- files[grepl("cumbria", files, ignore.case = TRUE)]
    
    all_files <- c(cheshire_files, cumbria_files)
    
    if (length(all_files) == 0) return(NULL)
    
    map_dfr(all_files, function(f) {
      tryCatch({
        read_csv(f, show_col_types = FALSE) %>%
          mutate(
            source_file = basename(f),
            county = case_when(
              grepl("cheshire", f, ignore.case = TRUE) ~ "Cheshire",
              grepl("cumbria", f, ignore.case = TRUE) ~ "Cumberland",
              TRUE ~ NA_character_
            )
          )
      }, error = function(e) NULL)
    })
  }
  
  # Load all crime data
  crime_all <- map_dfr(crime_dirs, load_crime_files)
  
  # Clean and filter crime data
  crime_clean <- crime_all %>%
    select(
      crime_id = `Crime ID`,
      month = Month,
      longitude = Longitude,
      latitude = Latitude,
      location = Location,
      lsoa_code = `LSOA code`,
      lsoa_name = `LSOA name`,
      crime_type = `Crime type`,
      outcome = `Last outcome category`,
      county
    ) %>%
    filter(!is.na(crime_type)) %>%
    mutate(
      year = as.integer(substr(month, 1, 4)),
      month_num = as.integer(substr(month, 6, 7)),
      # Extract town from LSOA name
      town = str_extract(lsoa_name, "^[^\\d]+") %>% str_trim()
    )
  
  # Filter for required crime types only
  crime_filtered <- crime_clean %>%
    filter(crime_type %in% c("Drugs", "Vehicle crime", "Robbery"))
  
  cat("Crime data cleaned. Rows:", nrow(crime_filtered), "\n")
  return(crime_filtered)
}

# =============================================================================
# 4. LOAD POPULATION DATA FOR RATE CALCULATIONS
# =============================================================================

clean_population_data <- function() {
  cat("Loading population data...\n")
  
  population_raw <- read_csv(
    file.path(base_path, "obtained_data/population/Population2011_1656567141570.csv"),
    show_col_types = FALSE
  )
  
  # Clean population data
  population_clean <- population_raw %>%
    rename(postcode = Postcode, population = Population) %>%
    mutate(
      population = as.numeric(str_replace_all(population, ",", ""))
    ) %>%
    filter(!is.na(population))
  
  cat("Population data cleaned. Rows:", nrow(population_clean), "\n")
  return(population_clean)
}

# =============================================================================
# 5. CREATE AGGREGATED DATASETS
# =============================================================================

# Aggregate house prices by town, county, and year
aggregate_house_prices <- function(house_price_data) {
  house_price_agg <- house_price_data %>%
    group_by(county, town, year) %>%
    summarise(
      avg_house_price = mean(price, na.rm = TRUE),
      median_house_price = median(price, na.rm = TRUE),
      max_house_price = max(price, na.rm = TRUE),
      min_house_price = min(price, na.rm = TRUE),
      n_transactions = n(),
      .groups = "drop"
    )
  return(house_price_agg)
}

# Aggregate broadband by town and county
aggregate_broadband <- function(broadband_data) {
  broadband_agg <- broadband_data %>%
    group_by(county, town) %>%
    summarise(
      avg_download_speed = mean(avg_download_speed, na.rm = TRUE),
      max_download_speed = max(max_download_speed, na.rm = TRUE),
      n_postcodes = n(),
      .groups = "drop"
    )
  return(broadband_agg)
}

# Aggregate crime data
aggregate_crime <- function(crime_data, population_data) {
  # Aggregate crime counts by town, county, year, and month
  crime_agg <- crime_data %>%
    group_by(county, town, year, month_num, crime_type) %>%
    summarise(
      crime_count = n(),
      .groups = "drop"
    )
  
  # Calculate crime rate per 10,000 people (using approximate population)
  # We'll use county-level population estimates
  county_pop <- data.frame(
    county = c("Cheshire", "Cumberland"),
    population = c(1000000, 500000)  # Approximate values
  )
  
  crime_rate <- crime_agg %>%
    left_join(county_pop, by = "county") %>%
    mutate(
      crime_rate_per_10k = (crime_count / population) * 10000
    )
  
  return(crime_rate)
}

# =============================================================================
# 6. MAIN EXECUTION - CLEAN AND SAVE ALL DATA
# =============================================================================

main <- function() {
  cat("=== Starting Data Cleaning Process ===\n\n")
  
  # Clean individual datasets
  house_price_data <- clean_house_price_data()
  broadband_data <- clean_broadband_data()
  crime_data <- clean_crime_data()
  population_data <- clean_population_data()
  
  # Create aggregated datasets
  cat("\nCreating aggregated datasets...\n")
  house_price_agg <- aggregate_house_prices(house_price_data)
  broadband_agg <- aggregate_broadband(broadband_data)
  crime_agg <- aggregate_crime(crime_data, population_data)
  
  # Save cleaned data
  cat("\nSaving cleaned datasets...\n")
  
  write_csv(house_price_data, file.path(base_path, "cleaned_data/house_price_cleaned.csv"))
  write_csv(house_price_agg, file.path(base_path, "cleaned_data/house_price_aggregated.csv"))
  write_csv(broadband_data, file.path(base_path, "cleaned_data/broadband_cleaned.csv"))
  write_csv(broadband_agg, file.path(base_path, "cleaned_data/broadband_aggregated.csv"))
  write_csv(crime_data, file.path(base_path, "cleaned_data/crime_cleaned.csv"))
  write_csv(crime_agg, file.path(base_path, "cleaned_data/crime_aggregated.csv"))
  write_csv(population_data, file.path(base_path, "cleaned_data/population_cleaned.csv"))
  
  cat("\n=== Data Cleaning Complete! ===\n")
  cat("All cleaned datasets saved to 'cleaned_data/' folder.\n")
  
  # Return summary
  list(
    house_price = house_price_data,
    house_price_agg = house_price_agg,
    broadband = broadband_data,
    broadband_agg = broadband_agg,
    crime = crime_data,
    crime_agg = crime_agg,
    population = population_data
  )
}

# Run the main function
cleaned_data <- main()
