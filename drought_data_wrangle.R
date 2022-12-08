#############################################
########Wrangling the drought shape files####
#############################################

library(sf)
library(lubridate)
library(tidyverse)

# Read in the shape file
ecoregions_shape <- read_sf(dsn = file.path(data_dir,"/epa_ecoareas/NA_CEC_Eco_Level3.shp"),
                            layer = "NA_CEC_Eco_Level3") |> 
                            st_transform("EPSG:4955")

# Limiting to the Marine West Coast Forest Ecoregion, level 3
# Add buffer to capture sites that are a little too far seaward to fall within the ecoregion polygon. 
ecoregion <- ecoregions_shape |> 
  dplyr::filter(NA_L3CODE == "7.1.8") |> 
  st_buffer(25)

# Need to add all shape files in /Users/jfrench/Documents/MEDS/eds-222/final_project/data/drought_shape_files
# create an empty data frame 
drought_df <- data.frame()

# Create list of all file names in drought shape files
drought_files <- list.files(path = file.path(data_dir,"drought_shape_files"),
                            pattern = "[.]shp$")

# This works but there has to be another way that doesn't take forever. 
for (i in drought_files) {
  file <- st_read(file.path(data_dir, "drought_shape_files", i)) |> 
    st_transform("EPSG:4955") |> 
    mutate("file_name" = i) 
  drought_df <- rbind(drought_df, file)  
}

# Need to add a date column 
# test <- str_sub(drought_df$file_name[[1]], 6, 13)
# print(test)

# Puts date information that was in the file names in to date time format
drought_df_date <- drought_df |> 
  mutate("date_string" = str_sub(drought_df$file_name, 6, 13))

# Add dates as date time column and make invalid geometries valid
drought_df_date <- drought_df_date |> 
  mutate("date" = lubridate::ymd(drought_df_date$date_string)) |> 
  st_make_valid() 
  
# Create bounding box of ecoregions to be used in crop
ecoregion_bbox <- ecoregion |> 
  sf::st_bbox()

# This has something to do with an update to sf but made the crop work 
sf_use_s2(FALSE)

## Actual crop
drought_df_crop <- st_crop(drought_df_date, ecoregion_bbox)


###############################################################################################
# save to csv and read back in, maybe this will make it so don't have to run for loop to render
###############################################################################################

st_write(drought_df_crop, dsn = file.path(data_dir, "drought_df_crop.shp"))
