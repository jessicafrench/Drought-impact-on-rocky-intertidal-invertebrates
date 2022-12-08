# Adding column of drought conditions for invert observations
# Define data directory
data_dir <- "/Users/jfrench/Documents/MEDS/eds-222/final_project/data"

# Read in Motile invertebrate counts
invert_count <- read_csv(file.path(data_dir, "motile_counts.csv"))

# Read in Site location data
site_loc_file <- read_csv(file.path(data_dir, "site_coords.csv")) 

ecoregions_shape <- read_sf(dsn = file.path(data_dir,"/epa_ecoareas/NA_CEC_Eco_Level3.shp"),
                            layer = "NA_CEC_Eco_Level3") |> 
  st_transform("EPSG:4955")

# Convert lat and long to point object.
site_loc <- st_as_sf(site_loc_file, 
                     coords = c("longitude", "latitude"), 
                     crs = "EPSG:4269")

# Limiting to the Marine West Coast Forest Ecoregion, level 3
# Add buffer to capture sites that are a little too far seaward to fall within the ecoregion polygon. 
ecoregion <- ecoregions_shape |> 
  dplyr::filter(NA_L3CODE == "7.1.8") |> 
  st_buffer(25) |> 
  st_transform("EPSG:4955")

# read in drought data
drought_data <- st_read(file.path(data_dir, "drought_df_crop.shp")) |> 
  st_transform("EPSG: 4955") |> 
  st_buffer(25)

# Add the site location data to the invert count dataframe and convert to sf
invert_count_loc <- left_join(invert_count, site_loc, by = "intertidal_sitename") |> 
  st_as_sf() |> 
  st_transform("EPSG:4955")

# Check that the coordinate reference system is the same as above. 
#st_crs(invert_count_loc)

# filter sites by ecoregion
invert_count_site_df <- st_filter(invert_count_loc, ecoregion,
                                  .predicate = st_intersects)

# Filter to exclude summer
invert_count_df <- invert_count_site_df |> 
  filter(!grepl('SU', SamplingSeasonCode))

# Need to bring out the year and date range from the sampling season code column 
# create column for date

invert_count_df_date <- mutate(invert_count_df, "start_date" = NA)
invert_count_df_date <- mutate(invert_count_df_date, "end_date" = NA)
# Fall year-10-01 : following year-01-31
# for loop 
#start_year = stringr::str_sub(invert_count_df_date$SamplingSeasonCode[1], 3,4)

# add start and end date columns for 1999
for (i in seq_along(invert_count_df_date$SamplingSeasonCode)) {
  season <- substring(invert_count_df_date$SamplingSeasonCode[i], 0,2)
  if (season == "FA" & invert_count_df_date$SamplingSeasonCode[i] == "FA99") {
    year = stringr::str_sub(invert_count_df_date$SamplingSeasonCode[i],3,4)
    
    start_year <- (paste0("19", year))
    end_year <- as.numeric((paste0("20", "00")))
    
    start_date <- paste0(start_year, "1001") |>
      ymd()
    invert_count_df_date$start_date[i] = start_date
    
    end_date <- paste0(end_year, "0131") |>
      ymd()
    invert_count_df_date$end_date[i] = end_date
  }
}

# add date for all other fall sampling years that are not 1999
for (i in seq_along(invert_count_df_date$SamplingSeasonCode)) {
  season <- substring(invert_count_df_date$SamplingSeasonCode[i], 0,2)      
  if (season == "FA" & invert_count_df_date$SamplingSeasonCode[i] != "FA99") {
    year = stringr::str_sub(invert_count_df_date$SamplingSeasonCode[i],3,4)
    
    start_year <- (paste0("20", year))
    end_year <- as.numeric((paste0("20", year))) + 1
    as.character(end_year)
    
    start_date <- paste0(start_year, "1001") |>
      ymd()
    invert_count_df_date$start_date[i] = start_date
    
    end_date <- paste0(end_year, "0131") |>
      ymd()
    invert_count_df_date$end_date[i] = end_date
  }
} 

# Add spring
for (i in seq_along(invert_count_df_date$SamplingSeasonCode)) {
  season <- substring(invert_count_df_date$SamplingSeasonCode[i], 0,2)      
  if (season == "SP") {
    year = stringr::str_sub(invert_count_df_date$SamplingSeasonCode[i],3,4)
    
    start_year <- (paste0("20", year))
    end_year <- (paste0("20", year))
    
    start_date <- paste0(start_year, "0201") |>
      ymd()
    invert_count_df_date$start_date[i] = start_date
    
    end_date <- paste0(end_year, "0531") |>
      ymd()
    invert_count_df_date$end_date[i] = end_date
  }
} 

# Add summer
for (i in seq_along(invert_count_df_date$SamplingSeasonCode)) {
  season <- substring(invert_count_df_date$SamplingSeasonCode[i], 0,2)      
  if (season == "SU") {
    year = stringr::str_sub(invert_count_df_date$SamplingSeasonCode[i],3,4)
    
    start_year <- (paste0("20", year))
    end_year <- (paste0("20", year))
    
    start_date <- paste0(start_year, "0601") |>
      ymd()
    invert_count_df_date$start_date[i] = start_date
    
    end_date <- paste0(end_year, "0930") |>
      ymd()
    invert_count_df_date$end_date[i] = end_date
  }
} 

# Need to convert the start and end date columns to date format
invert_date <- invert_count_df_date |> 
  mutate("start_date" = as.Date(invert_count_df_date$start_date, origin = '1970-01-01'),
         "end_date" = as.Date(invert_count_df_date$end_date, origin = '1970-01-01'),
         "obs_id" = "",
         "drought_impact" = "")

# add id to iterate over
for (i in seq_along(invert_date$obs_id)) {
  invert_date$obs_id[i] = i
}

drought_date_range <- interval(ymd("1999-10-01"), ymd("2017-05-31"))

drought_data <- drought_data |> 
  filter(drought_data$date %within% drought_date_range)

#Trying to add the drought designation to the invert data
counter <- 0
for (obs in seq_along(invert_date$obs_id)){
  drought_impact_list <- list()
  start_date <- invert_date$start_date[obs]
  end_date <- invert_date$end_date[obs]
  date_range <- interval(start_date, end_date)
  for (i in seq_along(drought_data$geometry)) {
    drought_date <- drought_data$date[i]
    if (st_within(invert_date$geometry[obs],
                  drought_data$geometry[i]) |>
        lengths() > 0
        & drought_date %within% date_range) {
      drought_impact_list <- append(drought_impact_list,
                                    drought_data$DM[i])

    }
  }
  invert_date$drought_impact[obs] = list(drought_impact_list)
  counter <- counter + 1
  print(counter)
}


# Uncomment to save file to computer
#saveRDS(invert_date, file = "invert_drought_data.RDS")