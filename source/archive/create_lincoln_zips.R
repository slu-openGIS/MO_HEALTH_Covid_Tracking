# create lincoln county zip code estimates

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
  filter(COUNTYFP %in% c("113")) %>%
  st_transform(crs = 26915)

county <- st_intersection(zip, counties) %>%
  rename(zip = GEOID10) %>%
  select(zip) %>%
  group_by(zip) %>%
  summarise() %>%
  st_collection_extract(., "POLYGON") %>%
  mutate(primary = TRUE, .after = "zip")

## make mini objects
county_63383a <- filter(county, zip == "63383") %>%
  filter(row_number() == 1)

county_63383b <- filter(county, zip == "63383") %>%
  filter(row_number() == 2) %>%
  mutate(primary = FALSE)

county <- filter(county, zip %in% "63383" == FALSE)
county <- rbind(county, county_63383a)

rm(county_63383a)

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
  select(zip, total_pop, primary) -> county_result

county_63383b %>%
  aw_interpolate(tid = "zip", source = county_demo, sid = "GEOID", weight = "total", output = "sf", 
                 extensive = "total_pop") %>%
  mutate(total_pop = round(total_pop)) %>%
  select(zip, total_pop, primary) -> county_63383b_result

county_result <- rbind(county_result, county_63383b_result)

# save data
county_result %>%
  st_transform(crs = 4326) %>%
  st_write("data/source/stl_zips/lincoln_county_zip.geojson", delete_dsn = TRUE)

st_geometry(county_result) <- NULL

county_result %>%
  select(zip, total_pop) %>%
  write_csv("data/source/stl_zips/lincoln_county_zip.csv")
