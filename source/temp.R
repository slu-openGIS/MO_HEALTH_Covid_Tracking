# dependencies ####
library(readr)
library(dplyr)

# metro counties by GEOID ####
metro_counties <- list(
  cape_girardeau = c("29031", "29017", "17003"),
  cape_girardeau_il = "17003",
  columbia = c("29019", "29007", "29175", "29053", "29089"),
  jeff_city = c("29051", "29027", "29135", "29151"),
  joplin = c("29097", "29145", "29512", "40115"),
  joplin_ok = "40115",
  kansas_city = c("20091", "20103", "20107", "20121", "20209",
                  "29013", "29025", "29037", "29047", "29049", 
                  "29095", "29107", "29165", "29177", "29511"),
  kansas_city_ks = c("20091", "20103", "20107", "20121", "20209"),
  kansas_city_mo = c("29013", "29025", "29037", "29047", "29049", 
                     "29095", "29107", "29165", "29177", "29511"),
  springfield = c("29077", "29043", "29225", "29167", "29225"),
  st_joseph = c("29003", "29021", "29063", "20043"),
  st_joseph_ks = "20043",
  st_louis = c("17005", "17013", "17027", "17083", "17117", 
               "17119", "17133", "17163", "29071", "29099", 
               "29113", "29183", "29189", "29219", "29510"),
  st_louis_il = c("17005", "17013", "17027", "17083", "17117", 
                  "17119", "17133", "17163"),
  st_louis_mo = c("29071", "29099", "29113", "29183", "29189", 
                  "29219", "29510")
)

# load and prep data ####
## region cases
region_prior <- read_csv("data/region/region_meso.csv") %>%
  filter(report_date == "2021-11-17") %>%
  select(report_date, region, case_avg, case_avg_rate)
region_meso <- read_csv("data/region/region_meso.csv") %>%
  filter(report_date >= "2021-11-19" & report_date <= "2021-11-24") %>%
  group_by(region) %>%
  summarise(case_avg = mean(new_cases))

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

rm(state_pop)

# calculate rates ####
region <- region_meso %>%
  left_join(., region_pop, by = "region") %>%
  mutate(case_avg_rate = case_avg/total_pop*100000) %>%
  mutate(report_date = "2021-11-24") %>%
  select(report_date, region, case_avg, case_avg_rate)

rm(region_meso, region_pop, metro_counties)


stl_hospital <- read_csv("data/metro/stl_hospital.csv") %>%
  filter(report_date == "2021-11-17" | report_date == "2021-11-24") %>%
  select(report_date, in_pt_avg, icu_avg, vent_avg)


