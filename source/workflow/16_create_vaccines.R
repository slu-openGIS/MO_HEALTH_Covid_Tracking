# process vaccination data

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# scrape race data (state)
## load source data

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# county vaccine rates ####

## load data
county_sf <- st_read("data/source/mo_county_plus_vaccine.geojson")

county_tbl <- select(county_sf, GEOID, NAME, total_pop)
st_geometry(county_tbl) <- NULL

county_sf %>%
  select(-NAME, -total_pop, -district) %>%
  rename(geoid = GEOID) -> county_sf

## construct output
### scrape totals
county <- get_vaccine(metric = "county")

### initial tidy
county %>%
  arrange(county) %>%
  mutate(report_date = date, .before = county) %>%
  mutate(state = "Missouri", .after = county) %>%
  left_join(., county_tbl, by = c("county" = "NAME")) %>%
  select(report_date, GEOID, everything()) %>%
  rename(geoid = GEOID) %>%
  mutate(initiated_rate = initiated/total_pop*1000, .after = initiated) %>%
  mutate(complete_rate = complete/total_pop*1000, .after = complete) %>%
  mutate(last7_rate = last7/total_pop*1000, .after = last7) %>%
  select(-total_pop) -> county
  
### write daily data
write_csv(county, paste0("data/source/mo_daily_vaccines/mo_daily_vaccines_", date, ".csv"))

### create daily snapshot
county_daily <- left_join(county_sf, county, by = "geoid") %>%
  select(report_date, geoid, county, state, everything())

### write daily snapshot data
county_daily <- st_transform(county_daily, crs = 4326)

st_write(county_daily, "data/county/daily_snapshot_mo_vaccines.geojson", delete_dsn = TRUE)

### clean-up
rm(county, county_sf, county_tbl)

## calculate patrol areas
### prep vaccines
county_daily <- select(county_daily, report_date, geoid, initiated, complete, last7)
st_geometry(county_daily) <- NULL

### re-load data
county_sf <- st_read("data/source/mo_county_plus_vaccine.geojson") %>%
  select(GEOID, district, total_pop)
st_geometry(county_sf) <- NULL

### combine
left_join(county_daily, county_sf, by = c("geoid" = "GEOID")) %>%
  group_by(district) %>%
  summarise(
    report_date = first(report_date),
    initiated = sum(initiated),
    complete = sum(complete),
    last7 = sum(last7),
    total_pop = sum(total_pop)
  ) %>%
  mutate(initiated_rate = initiated/total_pop*1000, .after = initiated) %>%
  mutate(complete_rate = complete/total_pop*1000, .after = complete) %>%
  mutate(last7_rate = last7/total_pop*1000, .after = last7) %>%
  select(report_date, everything()) -> district_daily

write_csv(district_daily, "data/district/daily_snapshot_mo_vaccines.csv")

### clean-up
rm(county_daily, county_sf, district_daily)

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

## clean-up
rm(get_mo_vacc, get_tableau, get_vaccine)
