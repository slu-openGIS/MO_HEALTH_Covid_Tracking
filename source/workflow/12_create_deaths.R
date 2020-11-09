
deaths_actual <- get_state(state = 29, metric = "deaths, actual")

deaths_reported <- read_csv("data/state/state_full.csv") %>%
  filter(state == "Missouri") %>%
  select(report_date, new_deaths) %>%
  rename(
    date = report_date,
    count = new_deaths
  ) %>%
  mutate(value = "Deaths, Reported") %>%
  mutate(avg = rollmean(count, k = 7, align = "right", fill = NA)) %>%
  select(date, value, count, avg) %>%
  filter(date >= "2020-03-18")

deaths <- bind_rows(deaths_actual, deaths_reported)

write_csv(deaths, "data/state/mo_deaths.csv")

rm(deaths, deaths_actual, deaths_reported, get_mo_deaths)