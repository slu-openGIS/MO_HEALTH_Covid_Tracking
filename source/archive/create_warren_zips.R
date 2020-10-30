# create warren county zip code estimates

# dependencies
library(areal)
library(dplyr)
library(readr)
library(sf)
library(tidycensus)
library(tigris)

# download zips
zip <- zctas(year = 2018, class = "sf") %>%
  st_transform(crs = 26915)

# geoprocess St. Louis County Zips
counties <- counties(state = 29, year = 2018, class = "sf") %>%
  filter(COUNTYFP %in% c("219")) %>%
  st_transform(crs = 26915)

county <- st_intersection(zip, counties) %>%
  rename(zip = GEOID10) %>%
  select(zip) %>%
  group_by(zip) %>%
  summarise() %>%
  st_collection_extract(., "POLYGON")

## make mini objects
county_63348a <- filter(county, zip == "63348") %>%
  filter(row_number() == 1)

county_63348b <- filter(county, zip == "63348") %>%
  filter(row_number() == 2)

county_63351a <- filter(county, zip == "63351") %>%
  filter(row_number() == 1)

county_63351b <- filter(county, zip == "63351") %>%
  filter(row_number() == 2)

county <- filter(county, zip %in% c("63348", "63351") == FALSE)
county <- rbind(county, county_63348a, county_63351a)

rm(county_63348a, county_63351a)

# get zcta data
total_pop <- get_acs(year = 2018, geography = "zcta", variables = "B01003_001") %>%
  select(GEOID, estimate) %>%
  filter(GEOID %in% county$zip) %>%
  rename(total_pop = estimate)

# combine zcta data with zcta geometry
zip %>%
  filter(GEOID10 %in% county$zip) %>%
  select(GEOID10) %>%
  rename(GEOID = GEOID10) %>%
  st_transform(crs = 26915) %>%
  left_join(., total_pop, by = "GEOID") -> county_demo

rm(total_pop)

# interpolate
county %>%
  aw_interpolate(tid = "zip", source = county_demo, sid = "GEOID", weight = "total", output = "sf", 
                 extensive = "total_pop") %>%
  mutate(total_pop = round(total_pop)) %>%
  select(zip, total_pop) -> county_result

county_63348b %>%
  aw_interpolate(tid = "zip", source = county_demo, sid = "GEOID", weight = "total", output = "sf", 
                 extensive = "total_pop") %>%
  mutate(total_pop = round(total_pop)) %>%
  select(zip, total_pop) -> county_63348b_result

county_63351b %>%
  aw_interpolate(tid = "zip", source = county_demo, sid = "GEOID", weight = "total", output = "sf", 
                 extensive = "total_pop") %>%
  mutate(total_pop = round(total_pop)) %>%
  select(zip, total_pop) -> county_63351b_result

county_result <- rbind(county_result, county_63348b_result, county_63351b_result)

# save data
county_result %>%
  st_transform(crs = 4326) %>%
  st_write("data/source/stl_zips/warren_county_zip.geojson", delete_dsn = TRUE)

st_geometry(county_result) <- NULL

county_result %>%
  select(zip, total_pop) %>%
  write_csv("data/source/stl_zips/warren_county_zip.csv")
