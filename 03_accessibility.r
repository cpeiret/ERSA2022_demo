
options(java.parameters = "-Xmx8G") # set up memory

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
destinations = st_read_parquet('./data/amenities.parquet') # load destinations

# clean data
origins = st_transform(origins, crs = 4326)
origins = origins %>% rename(id = X__index_level_0__)
origins <- origins %>%
  mutate(lon = unlist(map(origins$geometry,1)),
         lat = unlist(map(origins$geometry,2)))
origins = st_set_geometry(origins,NULL)

destinations = st_transform(destinations, crs = 4326)
destinations = destinations %>% rename(id = index)
destinations <- destinations %>%
  mutate(lon = unlist(map(destinations$geometry,1)),
         lat = unlist(map(destinations$geometry,2)))
destinations = st_set_geometry(destinations,NULL)
destinations$id = as.character(destinations$id)

amenities_names = c('bank','school','post_box','cafe','pharmacy','atm','kindergarten','doctors','marketplace','driving_school',
 'dentist', 'college','community_centre','place_of_worship','library','theatre','university','cinema','arts_centre','language_school',
 'hospital','exhibition_centre','clinic','childcare') # select amenities

destinations = destinations %>% dplyr::filter(amenity %in% amenities_names) # filter by selection

# r5r setup
r5r_core = setup_r5('./data/pbf', elevation = 'TOBLER', overwrite = F)

# set up parametres
departure_datetime <- as.POSIXct("13-05-2019 14:00:00",
                                 format = "%d-%m-%Y %H:%M:%S")

# routing analysis

ttm <- travel_time_matrix(r5r_core = r5r_core,
                          origins = origins,
                          destinations = destinations,
                          mode = 'WALK',
                          departure_datetime = departure_datetime,
                          max_walk_dist = 2000,
                          max_trip_duration = 15,
                          verbose = FALSE,
                          walk_speed = 4.5
                          )




ttm_seniors <- travel_time_matrix(r5r_core = r5r_core,
                          origins = origins,
                          destinations = destinations,
                          mode = 'WALK',
                          departure_datetime = departure_datetime,
                          max_walk_dist = 2000,
                          max_trip_duration = 15,
                          verbose = FALSE,
                          walk_speed = 3.2
)

# add amenity label
ttm = merge(ttm, destinations[,c('id','amenity')], by.x = 'to_id', by.y = 'id')
ttm_seniors = merge(ttm_seniors, destinations[,c('id','amenity')], by.x = 'to_id', by.y = 'id')

# accessibility score
i_1_adults = ttm %>% count(from_id) # number of amenities accessible from each origin
i_1_adults$i_1 = (i_1_adults$n - min(i_1_adults$n)) / (max(i_1_adults$n) - min(i_1_adults$n))

i_2_adults = ttm %>% count(from_id, amenity, sort = T) %>% distinct(from_id, amenity) %>% group_by(from_id) %>% summarise("variety" = n()) # variety of amenities
i_2_adults$i_2 = (i_2_adults$variety  - min(i_2_adults$variety)) / (max(i_2_adults$variety) - min(i_2_adults$variety))

i_3_adults = ttm %>% group_by(from_id) %>% summarise_at(vars(travel_time_p50), list(name = mean)) # average distance to amenity
i_3_adults$i_3 = (i_3_adults$name  - min(i_3_adults$name)) / (max(i_3_adults$name) - min(i_3_adults$name))

access_score_adults = merge(i_1_adults[,c('from_id','i_1')], i_2_adults[,c('from_id','i_2')], by.x = 'from_id', by.y = 'from_id')
access_score_adults = merge(access_score_adults, i_3_adults[,c('from_id','i_3')])

access_score_adults$i = sqrt(access_score_adults$i_1 * access_score_adults$i_2 / (access_score_adults$i_3 + 0.01))

# merge access score with polygons layer
hexagons = st_read_parquet('./data/hexagons.parquet') # load polygons layer

hexagons = merge(hexagons, access_score_adults, by.x = 'hex_id', by.y = 'Var1') # merge
hexagons = hexagons %>% rename('access_adults' = 'Freq') # rename variable

hexagons = merge(hexagons, access_score_seniors, by.x = 'hex_id', by.y = 'Var1') # merge
hexagons = hexagons %>% rename('access_seniors' = 'Freq') # rename variable


#st_write_parquet(hexagons, './results/hexagons_access.parquet') # save to parquet

stop_r5(r5r_core)
rJava::.jgc(R.gc = TRUE)
