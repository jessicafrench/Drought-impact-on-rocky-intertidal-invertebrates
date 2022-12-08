library(tidyverse)
library(lubridate)

# set data directory
data_dir <- "/Users/jfrench/Documents/MEDS/eds-222/final_project/data"

# read in daily mean temp 
data <- read_csv(file.path(data_dir, "MARINe_daily_temperature_means_PST.csv"))

# Read in wrangled data that includes invert data with drought conditions
invert_data <- readRDS(file.path(data_dir, "shannon_group.RDS")) 

site_list <- c(unique(invert_data$intertidal_sitename))

sst_yearly_mean <- data |> 
  filter(marine_site_name %in% site_list) |> 
  group_by(marine_site_name, 
           year) |> 
  summarise("sst_mean" = mean(mean))

saveRDS(sst_yearly_mean, file = file.path(data_dir, "sst_yearly_mean.RDS"))
