# create meso region data ####

## temporary data load
state_data <- read_csv("data/state/state_full.csv")
county_data <- read_csv("data/county/county_full.csv")

# subset ####
state_data <- state_data %>%
  filter(state == "Missouri") %>%
  select(report_date, new_cases, case_avg) # case_avg_rate

county_data <- county_data %>%
  filter(state == "Missouri") %>%
  select(report_date, geoid, county, new_cases)

# create trends ####
region_data <- county_data %>%
  mutate(region = case_when(
    geoid %in% metro_counties$st_louis_mo ~ "St. Louis",
    geoid %in% metro_counties$kansas_city_mo ~ "Kansas City",
    geoid %in% c(metro_counties$st_louis_mo, metro_counties$kansas_city_mo) == FALSE ~ "Outstate"
  )) %>%
  group_by(region, report_date) %>%
  summarise(new_cases = sum(new_cases, na.rm = TRUE), .groups = "drop_last") %>%
  mutate(case_avg = rollmean(new_cases, k = 7, align = "right", fill = NA)) %>%
  ungroup() %>%
  select(report_date, region, new_cases, case_avg) %>%
  mutate(case_avg = ifelse(report_date < "2020-01-30", 0, case_avg))

# modify state ####
state_data <- state_data %>%
  mutate(region = "Missouri") %>%
  select(report_date, region, new_cases, case_avg)

# combine ####
region_data <- bind_rows(region_data, state_data) %>%
  arrange(region, report_date)

# write data #### 
write_csv(region_data, "data/region/region_meso.csv")

# clean-up ####
rm(county_data, metro_counties, region_data, state_data)
