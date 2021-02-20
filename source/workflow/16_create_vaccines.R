# process vaccination data

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# Region C, race/ethnicity
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

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #