# process vaccination data

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# Region C, race/ethnicity

if (region_c_update == TRUE){
  
  ## load source data
  region_c_race <- read_csv("data/source/region_c_race.csv") 
  
  ## combine with vaccination data
  race <- left_join(region_c_vaccines, region_c_race, by = "value") %>%
    mutate(region = "C", .before = value) %>%
    mutate(vaccine_est = region_c_total_vaccines*(pct/100)) %>%
    mutate(vaccine_rate = vaccine_est/pop*1000) %>%
    rename(vaccine_pct = pct) %>%
    select(region, value, vaccine_pct, vaccine_est, vaccine_rate) %>%
    mutate(report_date = date, .before = region)
  
  ## write data
  write_csv(race, "data/individual/region_c_race_vaccine.csv")
  
  ## clean-up
  rm(race, region_c_race, region_c_vaccines, region_c_total_vaccines)
  
} else if (region_c_update == FALSE){
  
  rm(region_c_vaccines, region_c_total_vaccines)
  
}

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# scrape race data (state)
## load source data
race <- read_csv("data/source/mo_race.csv") %>%
  mutate(geoid = as.character(geoid))

## construct output
### scrape totals
totals <- get_vaccine(metric = "totals")

### scrape breakdowns
vaccine_race <- get_vaccine(metric = "race")
vaccine_ethn <- get_vaccine(metric = "ethnicity")

### add count of unknown
vaccine_race_unkown <- tibble(
  value = "Unknown Race",
  first_dose = totals$first - sum(vaccine_race$first_dose),
  second_dose = totals$second - sum(vaccine_race$second_dose),
  total_dose = totals$total - sum(vaccine_race$total_dose)
)

vaccine_ethn_unknown <- tibble(
  value = "Unknown Ethnicity",
  first_dose = totals$first - sum(vaccine_race$first_dose),
  second_dose = totals$second - sum(vaccine_race$second_dose),
  total_dose = totals$total - sum(vaccine_ethn$total_dose)
)

### remove not latino
vaccine_ethn <- filter(vaccine_ethn, value == "Latino")

### bind
vaccine_race_ethnic <- bind_rows(vaccine_race, vaccine_ethn, vaccine_race_unkown,
                                 vaccine_ethn_unknown)

### clean-up
rm(vaccine_race, vaccine_ethn, vaccine_race_unkown,
   vaccine_ethn_unknown, totals)

### calculate rates
left_join(vaccine_race_ethnic, race, by = "value") %>%
  mutate(
    first_dose_rate = first_dose/pop*100000,
    second_dose_rate = second_dose/pop*100000,
    total_dose_rate = total_dose/pop*100000
  ) %>%
  select(geoid, value, first_dose, first_dose_rate,
         second_dose, second_dose_rate, total_dose, total_dose_rate) %>%
  mutate(geoid = 29) %>%
  mutate(report_date = date, .before = "geoid") -> vaccine_race_ethnic

## write data
write_csv(vaccine_race_ethnic, "data/individual/mo_vaccine_race_rates.csv")

## clean-up
rm(race, vaccine_race_ethnic)

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# county vaccine rates ####

## load data
county_sf <- st_read("data/source/mo_county.geojson")

county_tbl <- select(county_sf, GEOID, NAME, pop)
st_geometry(county_tbl) <- NULL

county_sf %>%
  select(-NAME, -pop, -district) %>%
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
  mutate(first_dose_rate = first_dose/pop*1000, .after = first_dose) %>%
  mutate(second_dose_rate = second_dose/pop*1000, .after = second_dose) %>%
  mutate(total_dose_rate = total_dose/pop*1000, .after = total_dose) %>%
  mutate(prior_week_rate = prior_week_dose/pop*1000, .after = prior_week_dose) %>%
  select(-pop) -> county
  
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

## caclulate patrol areas
### prep vaccines
county_daily <- select(county_daily, report_date, geoid, first_dose)
st_geometry(county_daily) <- NULL

### re-load data
county_sf <- st_read("data/source/mo_county.geojson") %>%
  select(GEOID, district, pop)
st_geometry(county_sf) <- NULL

### combine
left_join(county_daily, county_sf, by = c("geoid" = "GEOID")) %>%
  group_by(district) %>%
  summarise(
    report_date = first(report_date),
    first_dose = sum(first_dose),
    pop = sum(pop)
  ) %>%
  mutate(frist_dose_rate = first_dose/pop*1000) %>%
  select(report_date, everything()) -> district_daily

write_csv(district_daily, "data/district/daily_snapshop_mo_vaccines.csv")

### clean-up
rm(county_daily, county_sf, district_daily)

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

## clean-up
rm(get_mo_vacc, get_tableau, get_vaccine)
