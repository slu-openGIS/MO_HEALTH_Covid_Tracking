# pull and process hospitalization data

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# create list with vectors of metro counties by GEOID
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

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# load data ####
## covid data
# hosp_sf <- sf::st_read(dsn = "https://beta.healthdata.gov/api/geospatial/anag-cw7u?method=export&format=GeoJSON")
hosp <- read_csv(file = "https://beta.healthdata.gov/api/views/anag-cw7u/rows.csv",
                 col_types = cols(collection_week = col_date(format = "")))

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

## subset
hosp <- select(hosp, hospital_pk, collection_week, state, fips_code,
               all_adult_hospital_inpatient_beds_7_day_avg,
               all_adult_hospital_inpatient_bed_occupied_7_day_avg,
               total_adult_patients_hospitalized_confirmed_and_suspected_covid_7_day_avg,
               total_pediatric_patients_hospitalized_confirmed_and_suspected_covid_7_day_avg,
               staffed_adult_icu_bed_occupancy_7_day_avg,
               total_staffed_adult_icu_beds_7_day_avg,
               staffed_icu_adult_patients_confirmed_and_suspected_covid_7_day_avg)

hosp <- rename(hosp,
               id = hospital_pk,
               report_date = collection_week,
               geoid = fips_code,
               staffed_beds = all_adult_hospital_inpatient_beds_7_day_avg,
               occupied_beds = all_adult_hospital_inpatient_bed_occupied_7_day_avg,
               adult_covid = total_adult_patients_hospitalized_confirmed_and_suspected_covid_7_day_avg,
               pediatric_covid = total_pediatric_patients_hospitalized_confirmed_and_suspected_covid_7_day_avg,
               staffed_icu_beds = total_staffed_adult_icu_beds_7_day_avg,
               occupied_icu_beds = staffed_adult_icu_bed_occupancy_7_day_avg,
               adult_covid_icu = staffed_icu_adult_patients_confirmed_and_suspected_covid_7_day_avg)
               
hosp <- filter(hosp, state == "MO" | 
                 geoid %in% c("17003","40115","20091", "20103", "20107", 
                              "20121", "20209","20043","17005", "17013", 
                              "17027", "17083", "17117", "17119", "17133", "17163"))

hosp <- mutate(hosp,
               staffed_beds = ifelse(staffed_beds == -999999, NA, staffed_beds),
               occupied_beds = ifelse(occupied_beds == -999999, NA, occupied_beds),
               adult_covid = ifelse(adult_covid == -999999, NA, adult_covid),
               pediatric_covid = ifelse(pediatric_covid == -999999, NA, pediatric_covid),
               staffed_icu_beds = ifelse(staffed_icu_beds == -999999, NA, staffed_icu_beds),
               occupied_icu_beds = ifelse(occupied_icu_beds == -999999, NA, occupied_icu_beds),
               adult_covid_icu = ifelse(adult_covid_icu == -999999, NA, adult_covid_icu))

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

hosp %>%
  mutate(short_name = case_when(
    geoid %in% metro_counties$cape_girardeau ~ "Cape Girardeau",
    geoid %in% metro_counties$columbia ~ "Columbia",
    geoid %in% metro_counties$jeff_city ~ "Jefferson City",
    geoid %in% metro_counties$joplin ~ "Joplin",
    geoid %in% metro_counties$kansas_city ~ "Kansas City",
    geoid %in% metro_counties$springfield ~ "Springfield",
    geoid %in% metro_counties$st_joseph ~ "St. Joseph",
    geoid %in% metro_counties$st_louis ~ "St. Louis"
  )) %>%
  filter(is.na(short_name) == FALSE) %>%
  group_by(short_name, report_date) %>%
  summarise(
    staffed_beds = sum(staffed_beds, na.rm = TRUE),
    occupied_beds = sum(occupied_beds, na.rm = TRUE),
    adult_covid = sum(adult_covid, na.rm = TRUE),
    pediatric_covid = sum(pediatric_covid, na.rm = TRUE),
    occupied_icu_beds = sum(occupied_icu_beds, na.rm = TRUE),
    staffed_icu_beds = sum(staffed_icu_beds, na.rm = TRUE),
    adult_covid_icu = sum(adult_covid_icu, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  mutate(geoid = case_when(
    short_name == "Cape Girardeau" ~ "16020",
    short_name == "Columbia" ~ "17860",
    short_name == "Jefferson City" ~ "27620",
    short_name == "Joplin" ~ "27900",
    short_name == "Kansas City" ~ "28140",
    short_name == "Springfield" ~ "44180",
    short_name == "St. Joseph" ~ "41140",
    short_name == "St. Louis" ~ "41180"
  )) %>%
  select(report_date, geoid, short_name, everything()) %>%
  mutate(covid_per_cap = adult_covid/staffed_beds*1000, .after = adult_covid) -> hosp_metro

write_csv(hosp_metro, "data/metro_all/metro_hospital.csv")

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

hosp %>%
  mutate(region = case_when(
    geoid %in% metro_counties$st_louis_mo ~ "St. Louis",
    geoid %in% metro_counties$kansas_city_mo ~ "Kansas City",
    geoid %in% c(metro_counties$st_louis_mo, metro_counties$kansas_city_mo) == FALSE ~ "Outstate"
  )) %>%
  filter(is.na(region) == FALSE) %>%
  group_by(region, report_date) %>%
  summarise(
    staffed_beds = sum(staffed_beds, na.rm = TRUE),
    occupied_beds = sum(occupied_beds, na.rm = TRUE),
    adult_covid = sum(adult_covid, na.rm = TRUE),
    pediatric_covid = sum(pediatric_covid, na.rm = TRUE),
    occupied_icu_beds = sum(occupied_icu_beds, na.rm = TRUE),
    staffed_icu_beds = sum(staffed_icu_beds, na.rm = TRUE),
    adult_covid_icu = sum(adult_covid_icu, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  select(report_date, region, everything()) %>%
  mutate(covid_per_cap = adult_covid/staffed_beds*1000, .after = adult_covid) -> hosp_region

hosp %>%
  filter(state == "MO") %>%
  mutate(region = "Missouri") %>% 
  group_by(region, report_date) %>%
  summarise(
    staffed_beds = sum(staffed_beds, na.rm = TRUE),
    occupied_beds = sum(occupied_beds, na.rm = TRUE),
    adult_covid = sum(adult_covid, na.rm = TRUE),
    pediatric_covid = sum(pediatric_covid, na.rm = TRUE),
    occupied_icu_beds = sum(occupied_icu_beds, na.rm = TRUE),
    staffed_icu_beds = sum(staffed_icu_beds, na.rm = TRUE),
    adult_covid_icu = sum(adult_covid_icu, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  select(report_date, region, everything()) %>%
  mutate(covid_per_cap = adult_covid/staffed_beds*1000, .after = adult_covid) -> hosp_state

hosp_region <- bind_rows(hosp_region, hosp_state) %>%
  arrange(region, report_date)

write_csv(hosp_region, "data/region/region_meso_hospital.csv")

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# write last update ####
last_update <- list(
  last_date = sort(unique(hosp$report_date, na.rm = TRUE), decreasing = TRUE)[1],
  statewide_date = date,
  current_date = date+1
)

save(last_update, file = "data/source/hhs/last_update.rda")

rm(hosp, hosp_metro, hosp_region, hosp_state, metro_counties, last_update)
