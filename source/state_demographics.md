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