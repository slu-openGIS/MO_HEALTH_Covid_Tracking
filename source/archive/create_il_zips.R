# create IL zip geometry ####

# dependencies ####
## tidyverse
library(dplyr)
library(readr)

## spatial
library(sf)
library(tidycensus)
library(tigris)

# load and geoprocess boundary data ####
## create state of illinois boundary
il <- states(class = "sf") %>%
  filter(GEOID == "17") %>%
  select(GEOID) %>%
  st_transform(crs = "+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs ")

## create ZCTA boundaries for IL only
il_zips <- zctas(year = 2018, class = "sf") %>%
  st_transform(crs = "+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs ") %>%
  st_intersection(., il) %>%
  select(GEOID10) %>%
  st_collection_extract(type = "POLYGON")

## create metro east boundaries
metro_east <- st_read("data/county/daily_snapshot_mo_xl.geojson", crs = 4269) %>%
  filter(state == "Illinois" & GEOID != "17003") %>%
  select(state) %>%
  group_by(state) %>%
  summarise() %>%
  # st_collection_extract(type = "POLYGON") %>%
  st_transform(crs = "+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs ") %>%
  mutate(region = "Metro East") %>%
  select(region)
  
## intersect IL ZCTAs with metro east boundary to create list of ZIPs to include
intersect_zips <- st_intersection(il_zips, metro_east) %>%
  st_collection_extract(type = "POLYGON")

## create metro east zip geometry, 
metro_east_zips <- filter(il_zips, GEOID10 %in% c(intersect_zips$GEOID10, "62092", "62016", "62098"))

## clean-up
rm(il, metro_east, intersect_zips)

# download population ####
metro_east_pop <- get_acs(geography = "zcta", year = 2018, variable = "B01003_001") %>%
  filter(GEOID %in% metro_east_zips$GEOID10) %>%
  select(GEOID, estimate) %>%
  rename(
    GEOID10 = GEOID,
    total_pop = estimate
  )

il_pop <- get_acs(geography = "zcta", year = 2018, variable = "B01003_001") %>%
  filter(GEOID %in% il_zips$GEOID10) %>%
  select(GEOID, estimate) %>%
  rename(
    GEOID10 = GEOID,
    total_pop = estimate
  )

# combine geoids and population ####
metro_east_zips <- left_join(metro_east_zips, metro_east_pop, by = "GEOID10") 
il_zips <- left_join(il_zips, il_pop, by = "GEOID10")

# prepare to write ####
metro_east_zips <- rename(metro_east_zips, zip = GEOID10)
il_zips <- rename(il_zips, zip = GEOID10)

metro_east_zips <- st_transform(metro_east_zips, crs = 4326)
il_zips <- st_transform(il_zips, crs = 4326)

# write data ####
st_write(il_zips, "data/source/stl_zips/il_zip.geojson")
st_write(metro_east_zips, "data/source/stl_zips/metro_east_zip.geojson")

st_geometry(il_zips) <- NULL
st_geometry(metro_east_zips) <- NULL

write_csv(il_zips, "data/source/stl_zips/il_zip.csv")
write_csv(metro_east_zips, "data/source/stl_zips/metro_east_zip.csv")
