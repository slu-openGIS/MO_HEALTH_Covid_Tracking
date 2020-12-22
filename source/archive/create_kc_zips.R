# create KC zip geometry ####

# dependencies ####
## tidyverse
library(dplyr)
library(readr)

## spatial
library(areal)
library(nngeo)
library(sf)
library(tidycensus)
library(tigris)

# load and geoprocess boundary data ####
## create KC metro boundaries
kc_metro <- st_read("data/county/daily_snapshot_mo_xl.geojson", crs = 4269) %>%
  filter(GEOID %in% c("29047", "29095", "20091", "29511", "29165", "20209")) %>%
  mutate(region = "Kansas City Metro") %>%
  select(region) %>%
  group_by(region) %>%
  summarise() %>%
  # st_collection_extract(type = "POLYGON") %>%
  st_transform(crs = "+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs ") %>%
  select(region) %>%
  st_remove_holes()

## create ZCTA boundaries for KC metro only
kc_zips <- zctas(year = 2019, class = "sf") %>%
  st_transform(crs = "+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs ") 

kc_zips_clipped <- kc_zips %>%
  st_intersection(., kc_metro) %>%
  select(GEOID10) %>%
  st_collection_extract(type = "POLYGON")

kc_zips_clipped <- kc_zips_clipped %>%
  mutate(sq_km = measurements::conv_unit(as.numeric(st_area(geometry)), from = "m2", "km2")) %>%
  select(GEOID10, sq_km) %>%
  filter(sq_km > .01)

kc_zips <- filter(kc_zips, GEOID10 %in% kc_zips_clipped$GEOID10)


# load population data ####
kc_pop <- get_acs(geography = "zcta", year = 2018, variable = "B01003_001") %>%
  filter(GEOID %in% kc_zips$GEOID10) %>%
  select(GEOID, estimate, moe) %>%
  rename(
    GEOID10 = GEOID,
    total_pop = estimate
  ) %>%
  mutate(total_pop = ifelse(total_pop == 0, moe, total_pop)) %>%
  select(-moe)

# combine geoids and population ####
kc_zips <- left_join(kc_zips, kc_pop, by = "GEOID10") %>%
  select(GEOID10, total_pop)

kc_zips_clipped <- select(kc_zips_clipped, -sq_km)

out <- aw_interpolate(kc_zips_clipped, tid = "GEOID10", source = kc_zips, sid = "GEOID10", weight = "total",
                             output = "sf", extensive = "total_pop") %>%
  rename(GEOID_ZCTA = GEOID10)

st_transform(out, crs = 4326) %>%
  st_write(., "data/source/kc_zips/kc_metro_zip.geojson")

st_geometry(out) <- NULL

write_csv(out, "data/source/kc_zips/kc_metro_zip.csv")

