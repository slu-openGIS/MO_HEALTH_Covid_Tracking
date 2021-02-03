# pull and process demographic data

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# st. louis city and county, race/ethnicity
## load source data
race <- read_csv("data/source/stl_race.csv") %>%
  mutate(geoid = as.character(geoid))

## scrape data
city_race <- get_demographics(state = "MO", county = "St. Louis City", metric = "race")
city_latino <- get_demographics(state = "MO", county = "St. Louis City", metric = "ethnicity")
county_race <- get_demographics(state = "MO", county = "St. Louis County", metric = "race")
county_latino <- get_demographics(state = "MO", county = "St. Louis County", metric = "ethnicity")

## construct final data object
covid_race <- bind_rows(county_race, county_latino, city_race, city_latino) %>%
  left_join(., race, by = c("geoid", "value")) %>%
  mutate(
    case_rate = cases/pop*1000,
    mortality_rate = deaths/pop*1000
  ) %>%
  select(geoid, county, value, cases, case_rate, deaths, mortality_rate) %>%
  mutate(report_date = date)

## write data
write_csv(covid_race, "data/individual/stl_race_rates.csv")

## clean-up
rm(race, city_race, county_race, city_latino, county_latino, covid_race)

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# st. louis city, race by sex
## load source data
race_gender <- read_csv("data/source/stl_race_gender.csv") %>%
  mutate(geoid = as.character(geoid)) %>%
  filter(geoid == "29510")

## scrape data
city_race_gender <- get_demographics(state = "MO", county = "St. Louis City", metric = "race by sex")

# construct final data object
covid_race_gender <- left_join(city_race_gender, race_gender, by = c("geoid", "value", "sex")) %>%
  mutate(
    case_rate = cases/pop*1000,
    mortality_rate = deaths/pop*1000
  ) %>%
  select(geoid, county, value, sex, cases, case_rate, deaths, mortality_rate) %>%
  mutate(report_date = date)

## write data
write_csv(covid_race_gender, "data/individual/stl_race_gender_rates.csv")

## clean-up
rm(race_gender, city_race_gender, covid_race_gender)

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# scrape race data (state)
## load source data
race <- read_csv("data/source/mo_race.csv") %>%
  mutate(geoid = as.character(geoid))

## enter most recent values
mo_totals <- get_cases(state = "MO", metric = "totals")

## scrape
state_race <- get_demographics(state = "MO", county = NULL, metric = "race")

## estimate number of cases
state_race %>%
  mutate(cases_est = mo_totals$total_cases*cases_prop) %>%
  mutate(deaths_est = mo_totals$total_deaths*deaths_prop) %>%
  select(state, value, cases_est, cases_prop, deaths_est, deaths_prop) -> state_race

rm(mo_totals)

## construct final data object
left_join(state_race, race, by = "value") %>%
  mutate(
    case_rate = cases_est/pop*100000,
    mortality_rate = deaths_est/pop*100000,
    cases_pct = cases_prop*100,
    deaths_pct = deaths_prop*100
  ) %>%
  select(geoid, state, value, cases_est, case_rate, cases_pct,
         deaths_est, mortality_rate, deaths_pct) %>%
  mutate(geoid = 29) %>%
  mutate(report_date = date, .before = "geoid") -> mo_covid_race

## write data
write_csv(mo_covid_race, "data/individual/mo_race_rates.csv")

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# clean-up
rm(get_demographics, get_city_demos, get_county_demos, get_city_scrape,
   get_case_totals, get_cases, get_esri, get_state_data_scrape, get_state_demos,
   get_state_demos_scrape, get_state_race, mo_covid_race, race, state_race)
