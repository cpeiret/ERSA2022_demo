
options(java.parameters = "-Xmx2G") # set up memory

# load libraries
library(osmextract)
library(sfarrow)
library(sf)
library(r5r)
library(dplyr)
library(tidyverse)
library(rgdal)

# load data
origins = st_read_parquet('./data/centroids.parquet') # load origins
hexagons = st_read_parquet('./data/hexagons.parquet') # load polygons layer


# clean data
origins = st_transform(origins, crs = 4326)
origins = origins %>% rename(id = X__index_level_0__)
origins <- origins %>%
  mutate(lon = unlist(map(origins$geometry,1)),
         lat = unlist(map(origins$geometry,2)))
origins = st_set_geometry(origins,NULL)

# r5r setup
r5r_core = setup_r5('./data/pbf', elevation = 'TOBLER', overwrite = F)

# set up parametres
departure_datetime <- as.POSIXct("13-05-2019 14:00:00",
                                 format = "%d-%m-%Y %H:%M:%S")

# routing analysis

ttm_adults <- travel_time_matrix(r5r_core = r5r_core,
                          origins = origins,
                          destinations = origins,
                          mode = 'WALK',
                          departure_datetime = departure_datetime,
                          max_walk_dist = 2000,
                          max_trip_duration = 15,
                          verbose = FALSE,
                          walk_speed = 4.5
)

ttm_seniors <- travel_time_matrix(r5r_core = r5r_core,
                                  origins = origins,
                                  destinations = origins,
                                  mode = 'WALK',
                                  departure_datetime = departure_datetime,
                                  max_walk_dist = 2000,
                                  max_trip_duration = 15,
                                  verbose = FALSE,
                                  walk_speed = 3.2
)

# accessibility score calculation

access_score_adults = ttm_adults %>% count(from_id) %>% rename(score_adults = n)
access_score_seniors = ttm_seniors %>% count(from_id) %>% rename(score_seniors = n)

# merge with the spatial data

results = merge(hexagons, access_score_adults, by.x = 'hex_id', by.y = 'from_id') # merge
results = merge(results, access_score_seniors, by.x = 'hex_id', by.y = 'from_id') # merge


st_write_parquet(results, './results/hexagons_access_test.parquet') # save to parquet


stop_r5(r5r_core)
rJava::.jgc(R.gc = TRUE)
