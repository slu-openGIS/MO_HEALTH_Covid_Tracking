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
  value = "Unknown, Race",
  first_dose = totals$first - sum(vaccine_race$first_dose),
  second_dose = totals$second - sum(vaccine_race$second_dose),
  total_dose = totals$total - sum(vaccine_race$total_dose)
)

vaccine_ethn_unknown <- tibble(
  value = "Unknown, Ethnicity",
  # first_dose = totals$first - sum(vaccine_race$first_dose),
  first_dose = NA,
  # second_dose = totals$second - sum(vaccine_race$second_dose),
  second_dose = NA,
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

## construct output
### scrape totals
# county <- get_vaccine(metric = "county")

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

## clean-up
rm(get_mo_vacc, get_tableau, get_vaccine)

