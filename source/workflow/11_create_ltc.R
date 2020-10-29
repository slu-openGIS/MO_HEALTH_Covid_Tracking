# pull and process long term care / nursing home data

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# load data ####
## facility master list
master_list <- st_read("data/source/ltc/mo_xl_ltc_facilities.geojson")

## covid data
covid <- read_csv(file = "https://data.cms.gov/api/views/s2uc-8wxp/rows.csv?accessType=DOWNLOAD") %>%
  clean_names()

## county data
county <- read_csv(file = "data/county/county_full.csv")

## spatial data
mo_xl <- st_read("data/county/daily_snapshot_mo_xl.geojson") %>%
  select(GEOID, county)

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# initial tidy ####
## subset only to focal providers
covid <- filter(covid, federal_provider_number %in% master_list$p_id)

## tidy
covid %>%
  select(week_ending, federal_provider_number,
         submitted_data:total_number_of_occupied_beds, 
         total_resident_confirmed_covid_19_cases_per_1_000_residents,
         total_resident_covid_19_deaths_per_1_000_residents,
         staff_weekly_confirmed_covid_19:staff_total_covid_19_deaths) %>%
  rename(
    report_date = week_ending,
    p_id = federal_provider_number,
    p_submit = submitted_data,
    p_qa_pass = passed_quality_assurance_check,
    r_new_admit = residents_weekly_admissions_covid_19,
    r_admit = residents_total_admissions_covid_19,
    r_new_confirm = residents_weekly_confirmed_covid_19,
    r_confirm = residents_total_confirmed_covid_19,
    r_new_suspect = residents_weekly_suspected_covid_19,
    r_suspect = residents_total_suspected_covid_19,
    r_new_deaths_all = residents_weekly_all_deaths,
    r_deaths_all = residents_total_all_deaths,
    r_new_deaths_covid = residents_weekly_covid_19_deaths,
    r_deaths_covid = residents_total_covid_19_deaths,
    r_beds = number_of_all_beds,
    r_occupied_beds = total_number_of_occupied_beds,
    r_confirmed_rate = total_resident_confirmed_covid_19_cases_per_1_000_residents,
    r_deaths_rate = total_resident_covid_19_deaths_per_1_000_residents,
    s_new_confirm = staff_weekly_confirmed_covid_19,
    s_confirm = staff_total_confirmed_covid_19,
    s_new_suspect = staff_weekly_suspected_covid_19,
    s_suspect = staff_total_suspected_covid_19,
    s_new_deaths_covid = staff_weekly_covid_19_deaths,
    s_deaths_covid = staff_total_covid_19_deaths
  ) %>%
  mutate(report_date = mdy(report_date)) %>%
  arrange(p_id, report_date) -> covid

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# subset to most recent reports ####
## latest report
covid %>%
  group_by(p_id) %>%
  arrange(report_date) %>%
  filter(row_number() == n()) %>%
  select(report_date, p_id, r_confirm, r_suspect, r_deaths_covid, 
         s_confirm, s_suspect, s_deaths_covid)-> covid_latest_week

## latest report
covid %>%
  group_by(p_id) %>%
  arrange(report_date) %>%
  filter(row_number() %in% c(n()-1, n())) %>%
  select(p_id, r_new_confirm, r_new_suspect, r_new_deaths_covid,
         s_new_confirm, s_new_suspect, s_new_deaths_covid) -> covid_last_two

## clean-up
rm(covid)

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# calculate new cases and deaths over last two weeks ####
## group and summarise
covid_last_two %>%
  group_by(p_id) %>%
  summarise(
    r_new_confirm = sum(r_new_confirm, na.rm = TRUE), 
    r_new_suspect = sum(r_new_suspect, na.rm = TRUE), 
    r_new_deaths_covid = sum(r_new_deaths_covid, na.rm = TRUE),
    s_new_confirm = sum(s_new_confirm, na.rm = TRUE), 
    s_new_suspect = sum(s_new_suspect, na.rm = TRUE), 
    s_new_deaths_covid = sum(s_new_deaths_covid, na.rm = TRUE)
  ) -> covid_last_two

## combine with covid latest
covid_latest_week <- left_join(covid_latest_week, covid_last_two, by = "p_id")

## clean-up
rm(covid_last_two)

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# create final facility-level data ####
## calculate join resident and staff values
covid_latest_week %>%
  mutate(
    cases_all = r_confirm + s_confirm,
    new_cases_all = r_new_confirm + s_new_confirm,
    suspected_cases_all = r_suspect + s_suspect,
    deaths_all = r_deaths_covid + s_deaths_covid,
    new_deaths_all = r_new_deaths_covid + s_new_deaths_covid
  ) %>%
  select(report_date, p_id, cases_all, r_confirm, s_confirm, 
         new_cases_all, r_new_confirm, s_new_confirm, 
         suspected_cases_all, r_suspect, s_suspect,
         deaths_all, r_deaths_covid, s_deaths_covid,
         new_deaths_all, r_new_deaths_covid, s_new_deaths_covid) %>%
  rename(
    cases_res = r_confirm,
    cases_staff = s_confirm,
    new_cases_res = r_new_confirm,
    new_cases_staff = s_new_confirm,
    deaths_res = r_deaths_covid,
    deaths_staff = s_deaths_covid, 
    new_deaths_res = r_new_deaths_covid,
    new_deaths_staff = s_new_deaths_covid
  ) -> covid_latest_week

## join with master list
covid_latest_week <- left_join(master_list, covid_latest_week, by = "p_id")

## calculate rates
covid_latest_week %>%
  mutate(
    cases_rate_all = (cases_all / p_beds)*100,
    new_cases_rate_all = (new_cases_all / p_beds)*100,
    deaths_rate_all = (deaths_all / p_beds)*100,
    new_deaths_rate_all = (new_deaths_all / p_beds)*100
  ) %>%
  relocate(cases_rate_all, .before = "cases_all") %>%
  relocate(new_cases_rate_all, .before = "new_cases_all") %>%
  relocate(deaths_rate_all, .before = "deaths_all") %>%
  relocate(new_deaths_rate_all, .before = "new_deaths_all") -> covid_latest_week

## clean-up
rm(master_list)
  
# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# create county-level data ####
## subset
county_covid <- select(covid_latest_week, p_geoid, cases_all, cases_res, cases_staff, 
                       deaths_all, deaths_res, deaths_staff)
st_geometry(county_covid) <- NULL

## group and summarise
county_covid %>%
  group_by(p_geoid) %>%
  summarise(
    cases_ltc_all = sum(cases_all, na.rm = TRUE), 
    cases_ltc_res = sum(cases_res, na.rm = TRUE), 
    cases_ltc_staff = sum(cases_staff, na.rm = TRUE), 
    deaths_ltc_all = sum(deaths_all, na.rm = TRUE),
    deaths_ltc_res = sum(deaths_res, na.rm = TRUE),
    deaths_ltc_staff = sum(deaths_staff, na.rm = TRUE)
  ) %>%
  rename(geoid = p_geoid) -> county_covid

## prep county data
county %>% 
  filter(geoid %in% mo_xl$GEOID) %>%
  group_by(geoid) %>%
  arrange(report_date) %>%
  filter(row_number() == n()) %>%
  select(report_date, geoid, county, state, cases, deaths) -> county

## combine county and ltc covid data ####
left_join(county, county_covid, by = "geoid") %>%
  mutate(cases_ltc_pct = cases_ltc_all/cases*100,
         deaths_ltc_pct = deaths_ltc_all/deaths*100) %>%
  mutate(cases_ltc_pct = ifelse(is.nan(cases_ltc_pct) == TRUE, NA, cases_ltc_pct),
         deaths_ltc_pct = ifelse(is.nan(deaths_ltc_pct) == TRUE, NA, deaths_ltc_pct)) %>%
  mutate(cases_ltc_pct = ifelse(is.infinite(cases_ltc_pct) == TRUE, 100, cases_ltc_pct),
         deaths_ltc_pct = ifelse(is.infinite(deaths_ltc_pct) == TRUE, 100, deaths_ltc_pct)) -> county_covid

## add county geometry
mo_xl <- select(mo_xl, GEOID)

## combine covid data to county geometry
county_covid <- left_join(mo_xl, county_covid, by = c("GEOID" = "geoid"))

## clean-up
rm(county, mo_xl)

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# write data ####
st_write(covid_latest_week, "data/nursing_home_ltc/mo_xl_ltc_full.geojson", 
         delete_dsn = TRUE)
st_write(county_covid, "data/nursing_home_ltc/mo_xl_ltc_county.geojson", 
         delete_dsn = TRUE)

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# write last update ####
last_date <- unique(covid_latest_week$report_date, na.rm = TRUE)
last_date <- na.omit(last_date)

last_update <- list(
  last_date = last_date,
  statewide_date = date,
  current_date = date+1
)

save(last_update, file = "data/source/ltc/last_update.rda")

## final clean-up
rm(county_covid, covid_latest_week, last_update, last_date)
