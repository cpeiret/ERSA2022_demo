options(java.parameters = "-Xmx2G")

# load libraries
library(osmextract)
library(sfarrow)
library(sf)
library(r5r)
library(dplyr)
library(tidyverse)
library(rgdal)

# load/get data
sa_buf = st_read_parquet('./data/sa_buf.parquet') # study area boundaries
centroids = st_read_parquet('./data/centroids.parquet') # our origins and destinations
#caen = oe_get('Caen, France', boundary = sa_buf, download_directory = './data/pbf')


# data pre-processing

centroids = st_transform(centroids, crs = 4326)
centroids = centroids %>% rename(id = X__index_level_0__)
centroids <- centroids %>%
  mutate(lon = unlist(map(centroids$geometry,1)),
         lat = unlist(map(centroids$geometry,2)))
centroids = st_set_geometry(centroids,NULL)


# r5r setup
r5r_core <- setup_r5('./data/pbf')

# accessibility analysis

# set inputs
mode <- c("WALK")
max_walk_dist <- 800
max_trip_duration <- 10
departure_datetime <- as.POSIXct("13-05-2019 14:00:00",
                                 format = "%d-%m-%Y %H:%M:%S")

# calculate a travel time matrix
ttm <- travel_time_matrix(r5r_core = r5r_core,
                          origins = centroids,
                          destinations = centroids,
                          mode = mode,
                          departure_datetime = departure_datetime,
                          max_walk_dist = max_walk_dist,
                          max_trip_duration = max_trip_duration,
                          verbose = FALSE)

head(ttm)

# accessibility score based on how many points can be accessed within 20 min
access_score_seniors = as.data.frame(table(ttm$from_id))

# merge access score with polygons layer
hexagons = st_read_parquet('./data/hexagons.parquet') # load polygons layer
hexagons = merge(hexagons, access_score_seniors, by.x = 'hex_id', by.y = 'Var1') # merge
hexagons = hexagons %>% rename('access_seniors' = 'Freq') # rename variable
st_write_parquet(hexagons, './results/hexagons_access.parquet') # save to parquet

# detailed itineraries
dit <- detailed_itineraries(r5r_core = r5r_core,
                            origins = centroids[27,],
                            destinations = centroids[25,],
                            mode = 'WALK',
                            departure_datetime = departure_datetime,
                            max_walk_dist = 10000,
                            shortest_path = FALSE,
                            verbose = FALSE)
head(dit)

# extract OSM network
street_net <- street_network_to_sf(r5r_core)

# plot
ggplot() +
  geom_sf(data = street_net$edges, color='gray85') +
  geom_sf(data = dit, aes(color=mode)) +
  facet_wrap(.~option) + 
  theme_void()











stop_r5(r5r_core)
rJava::.jgc(R.gc = TRUE)

