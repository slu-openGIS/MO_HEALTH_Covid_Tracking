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

out <- left_join(counties_sf, counties, by = "GEOID") %>%
  arrange(NAME) %>%
  mutate(NAME = ifelse(GEOID == "29510", "St. Louis City", NAME))

st_write(out, "data/source/mo_county.geojson")
