setwd('C:/Users/b9066009/Documents/PhD/01_access_morphometrics/ERSA2022_demo')

options(java.parameters = "-Xmx2G")

# load libraries
library(osmextract)
library(sfarrow)
library(sf)
library(r5r)
library(dplyr)
library(tidyverse)
library(rgdal)

# load data
centroids = st_read_parquet('./data/centroids.parquet') # our origins and destinations

# clean data
centroids = st_transform(centroids, crs = 4326)
centroids = centroids %>% rename(id = X__index_level_0__)
centroids <- centroids %>%
  mutate(lon = unlist(map(centroids$geometry,1)),
         lat = unlist(map(centroids$geometry,2)))
centroids = st_set_geometry(centroids,NULL)

# r5r setup
r5r_core = setup_r5('./data/pbf', elevation = 'TOBLER', overwrite = T)

# set up parametres
departure_datetime <- as.POSIXct("13-05-2019 14:00:00",
                                 format = "%d-%m-%Y %H:%M:%S")

# routing analysis

ttm <- travel_time_matrix(r5r_core = r5r_core,
                          origins = centroids,
                          destinations = centroids,
                          mode = 'WALK',
                          departure_datetime = departure_datetime,
                          max_walk_dist = 2000,
                          max_trip_duration = 15,
                          verbose = FALSE,
                          walk_speed = 4.5
                          )
access_score_adults = as.data.frame(table(ttm$from_id))


ttm_seniors <- travel_time_matrix(r5r_core = r5r_core,
                          origins = centroids,
                          destinations = centroids,
                          mode = 'WALK',
                          departure_datetime = departure_datetime,
                          max_walk_dist = 2000,
                          max_trip_duration = 15,
                          verbose = FALSE,
                          walk_speed = 3.2
)
access_score_seniors = as.data.frame(table(ttm_seniors$from_id))


# merge access score with polygons layer
hexagons = st_read_parquet('./data/hexagons.parquet') # load polygons layer

hexagons = merge(hexagons, access_score_adults, by.x = 'hex_id', by.y = 'Var1') # merge
hexagons = hexagons %>% rename('access_adults' = 'Freq') # rename variable

hexagons = merge(hexagons, access_score_seniors, by.x = 'hex_id', by.y = 'Var1') # merge
hexagons = hexagons %>% rename('access_seniors' = 'Freq') # rename variable


st_write_parquet(hexagons, './results/hexagons_access.parquet') # save to parquet
