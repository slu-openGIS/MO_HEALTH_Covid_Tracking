# create normal counties ####

library(dplyr)
library(tidycensus)
library(tigris)
library(sf)

vars <- c("B01003_001", "B02001_001", "B02001_003", "B19013_001", "B05010_001", "B05010_002")

counties <- get_acs(geography = "county", variables = vars, 
                    state = 29, output = "wide") %>%
  rename(
    pop = B01003_001E,
    median_inc = B19013_001E
  ) %>%
  mutate(
    pct_black = B02001_003E/B02001_001E*100,
    pct_poverty = B05010_002E/B05010_001E*100
  ) %>%
  select(GEOID, pop, median_inc, pct_black, pct_poverty)

counties_sf <- counties(state= 29) %>%
  select(GEOID, NAME)

counties_centroids <- st_transform(counties_sf, crs = 26915) %>%
  st_centroid() %>%
  select(GEOID)
  
districts <- st_read("data/source/mo_highway_districts.geojson") %>%
  st_transform(crs = 26915) %>%
  rename(district = distrct)

districts <- st_intersection(counties_centroids, districts)
st_geometry(districts) <- NULL

counties_sf <- left_join(counties_sf, districts, by = "GEOID") %>%
  mutate(district = ifelse(GEOID == "29069", "E", district))

out <- left_join(counties_sf, counties, by = "GEOID") %>%
  arrange(NAME) %>%
  mutate(NAME = ifelse(GEOID == "29510", "St. Louis City", NAME))

st_write(out, "data/source/mo_county.geojson", delete_dsn = TRUE)
