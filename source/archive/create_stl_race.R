library(tidycensus)
library(dplyr)
library(readr)

race <- get_acs(year = 2018, geography = "county", table = "B02001", 
                state = 29, county = c("189", "510"))

race %>% 
  mutate(variable = case_when(
    variable == "B02001_002" ~ "White",
    variable == "B02001_003" ~ "Black",
    variable == "B02001_004" ~ "Native",
    variable == "B02001_005" ~ "Asian",
    variable == "B02001_008" ~ "Two or More"
  )) %>%
  filter(is.na(variable) == FALSE) %>%
  select(GEOID, variable, estimate) %>%
  rename(
    geoid = GEOID,
    value = variable,
    pop = estimate
  ) -> race

latino <- get_acs(year = 2018, geography = "county", variables = "B03003_003", 
                state = 29, county = c("189", "510"))

latino %>%
  mutate(variable = "Latino") %>%
  select(GEOID, variable, estimate) %>%
  rename(
    geoid = GEOID,
    value = variable,
    pop = estimate
  ) -> latino

out <- bind_rows(race, latino) %>%
  arrange(geoid, value)

write_csv(out, "data/source/stl_race.csv")
