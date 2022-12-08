library(tidyverse)
library(sf)
library(lubridate)

###########################################################################################
#The purpose of this script is to create a data frame that can be used to model drought impact on invert abundance and shannon diversity index. This script adds a column for shannon diversity index, a binary variable of drought condition, and a lag drought impact variable. It saves the resulting data frame to the data directory so it can be called later
###########################################################################################

# Set data directory, This is the same across all data wrangling r scripts and the r markdown.
data_dir <- "/Users/jfrench/Documents/MEDS/eds-222/final_project/data"

# Read in invert count data previously wrangled with drought condition added in invert_data_wrangle.R 
invert_data <- readRDS(file.path(data_dir, "invert_drought_data.RDS")) |> 
  rename("total_count" = "Sum(count)")

# Read in SST data to be added at the end. 
sst <- readRDS(file.path(data_dir, "sst_yearly_mean.RDS")) 

# Create a blank column for drought_max which will be the maximum value of the drought impact list for each observation. This list was added in the invert_data_wrangle.R script.
invert_data <- invert_data |> 
  mutate("drought_max" = "")

# Updates the values in the drought_max column to be the max drought impact experienced at that sight in the time frame the samples were taken. 

for (i in seq_along(invert_data$obs_id)) {
  if (length(invert_data$drought_impact[[i]]) > 0) {
    invert_data$drought_max[i] = max(unlist(invert_data$drought_impact[i])) + 1
  } else {
    invert_data$drought_max[i] = 0
  }
}

# Sets a new column where unusually dry (1) and no drought impacts (0) and all other designations are drought. This is a scaling of Drought Monitor designations that start at 0 for unusually dry and no drought as NA. Additionally, creates a blank column for sample year and filters out rows where the observed number of a species was 0. 
invert_data <- invert_data |> 
  mutate("drought_simple" = case_when(drought_max >= 2 ~ "drought",
                                      drought_max < 2 ~ "no_drought")) |> 
  mutate(drought_simple = as.factor(drought_simple), 
         "sample_year" = "") |> 
  filter(mean_number_per_plot > 0)

# Populate the sample year column with the year of the end date of the sample period. 
for (i in seq_along(invert_data$obs_id)) {
  invert_data$sample_year[i] = year(invert_data$end_date[i])
}


# Create a dataframe with the species totals grouped by site and by year. 
species_count_df <- invert_data |> 
  group_by(intertidal_sitename, sample_year, graph_classification) |> 
  summarise("species_total" = sum(total_count)) |> 
  st_drop_geometry()
# Create a data frame with the total number of organisms observed at each site grouped by site and by year. 
site_total <- invert_data |> 
  group_by(intertidal_sitename, sample_year) |> 
  summarise("site_total" = sum(total_count)) |> 
  st_drop_geometry()

# Calculates the Shannon Diversity index for each site and year. 
shannon_df <- left_join(species_count_df, site_total) |>
  mutate("proportion" = species_total/site_total) |>
  mutate("ln_prop" = log(proportion)) |>
  mutate("prop_X_ln_prop" = proportion*ln_prop) |>
  group_by(intertidal_sitename,
           sample_year,
           site_total) |>
  summarise("shannon_index" = sum(prop_X_ln_prop)*-1)

# Joins the Shannon Diversity index data to the invert data. 
invert_data_shannon <- left_join(invert_data, shannon_df)

# Simplifies the invert_data_shannon data frame. 
shannon_group <- invert_data_shannon |> 
  group_by(intertidal_sitename, 
           sample_year, 
           drought_simple, 
           drought_max, 
           shannon_index) |> 
  summarise("mean_org_per_plot" = sum(mean_number_per_plot)) 

# Creates a column of the drought_max value from the prior year at each site. 
shannon_lag_max <- shannon_group |> 
  group_by(intertidal_sitename) |> 
  mutate("drought_lag" = lag(drought_max, order_by = sample_year))

shannon_lag_simple <- shannon_lag_max |> 
  group_by(intertidal_sitename) |> 
  mutate("drought_lag_simple" = lag(drought_simple, order_by = sample_year),
         "sample_year" = as.numeric(sample_year)) 

# Left join the SST data to the shannon invert data frame
shannon_lag_sst <- left_join(shannon_lag_simple, sst, by = c("intertidal_sitename" = "marine_site_name", "sample_year" = "year"))
# 
# save file resulting data frame to file to be read into final r markdown. 
saveRDS(shannon_lag_sst, file = file.path(data_dir, "shannon_lag_sst.RDS"))
