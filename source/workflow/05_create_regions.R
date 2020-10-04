# create meso region data ####

# load reference data ###
## state populations
state_pop <- read_csv("data/source/state_pop.csv") %>%
  filter(NAME == "Missouri") %>%
  rename(region = NAME)

## county populations
region_pop <- read_csv("data/source/mo_county_plus/mo_county_plus.csv",
                       col_types = cols(GEOID = col_double())) %>%
  select(-NAME) %>%
  mutate(GEOID = as.character(GEOID)) %>%
  mutate(region = case_when(
    GEOID %in% metro_counties$st_louis_mo ~ "St. Louis",
    GEOID %in% metro_counties$kansas_city_mo ~ "Kansas City",
    GEOID %in% c(metro_counties$st_louis_mo, metro_counties$kansas_city_mo) == FALSE ~ "Outstate"
  )) %>%
  group_by(region) %>%
  summarise(total_pop = sum(total_pop, na.rm = TRUE), .groups = "drop_last") %>%
  bind_rows(., state_pop)

## clean-up
rm(state_pop)

# subset ####
state_data <- state_data %>%
  ungroup() %>%
  filter(state == "Missouri") %>%
  select(report_date, new_cases, case_avg, new_deaths, deaths_avg)

county_data <- county_data %>%
  ungroup() %>%
  filter(state == "Missouri") %>%
  select(report_date, geoid, county, new_cases, new_deaths)

# create trends ####
region_data <- county_data %>%
  mutate(region = case_when(
    geoid %in% metro_counties$st_louis_mo ~ "St. Louis",
    geoid %in% metro_counties$kansas_city_mo ~ "Kansas City",
    geoid %in% c(metro_counties$st_louis_mo, metro_counties$kansas_city_mo) == FALSE ~ "Outstate"
  )) %>%
  group_by(region, report_date) %>%
  summarise(
    new_cases = sum(new_cases, na.rm = TRUE), 
    new_deaths = sum(new_deaths, na.rm = TRUE), 
    .groups = "drop_last") 

region_data <- region_data %>%
  mutate(case_avg = rollmean(new_cases, k = 7, align = "right", fill = NA)) %>%
  mutate(deaths_avg = rollmean(new_deaths, k = 7, align = "right", fill = NA)) %>%
  ungroup() %>%
  select(report_date, region, new_cases, case_avg, new_deaths, deaths_avg) %>%
  mutate(case_avg = ifelse(report_date < "2020-01-30", 0, case_avg)) %>%
  mutate(deaths_avg = ifelse(report_date < "2020-01-30", 0, deaths_avg))
    
# modify state ####
state_data <- state_data %>%
  mutate(region = "Missouri") %>%
  select(report_date, region, new_cases, case_avg, new_deaths, deaths_avg)

# combine ####
region_data <- bind_rows(region_data, state_data) %>%
  arrange(region, report_date)

# add per capita rates ####
region_data %>%
  left_join(., region_pop, by = "region") %>%
  mutate(case_avg_rate = case_avg/total_pop*100000) %>%
  mutate(deaths_avg_rate = deaths_avg/total_pop*100000) %>%
  select(report_date, region, new_cases, case_avg, case_avg_rate,
         new_deaths, deaths_avg, deaths_avg_rate) -> region_data

# write data #### 
write_csv(region_data, "data/region/region_meso.csv")

# clean-up ####
rm(county_data, metro_counties, region_data, state_data, region_pop)
