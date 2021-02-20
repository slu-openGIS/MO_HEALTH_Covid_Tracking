# race in Region C

library(dplyr)
library(tidycensus)
library(readr)

# Pike, Lincoln, Warren, St. Charles, Franklin, STL County, STL City,
# Jefferson, Washington, St. Francois, Ste. Genevive, Perry

counties <- c("071", "099", "113", "157", "163",
              "183", "186", "187", "189", "219",
              "221", "510")

race <- get_acs(year = 2018, geography = "county", table = "B02001", 
                state = 29, county = counties)

race %>% 
  mutate(variable = case_when(
    variable == "B02001_002" ~ "White",
    variable == "B02001_003" ~ "Black",
    variable == "B02001_004" ~ "Native",
    variable == "B02001_005" ~ "Asian",
    variable == "B02001_006" ~ "Pacific Islander",
    variable == "B02001_007" ~ "Other",
    variable == "B02001_008" ~ "Two or More"
  )) %>%
  filter(is.na(variable) == FALSE) %>%
  select(GEOID, variable, estimate) %>%
  rename(
    geoid = GEOID,
    value = variable,
    pop = estimate
  ) %>%
  group_by(value) %>%
  summarise(pop = sum(pop)) %>%
  mutate(region = "C", .before = value) -> race

write_csv(race, "data/source/region_c_race.csv")

