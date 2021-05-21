# process vaccination data

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# convert state vaccination tables ####
system(paste0("iconv -f utf-16le -t utf-8 ",
              downloads_path, "/Initiated_Vaccinations_by_Race_data.csv", " > ", 
              here::here(), "/data/source/mo_vaccines/Initiated_Vaccinations_by_Race_data.txt"))

system(paste0("iconv -f utf-16le -t utf-8 ",
              downloads_path, "/Completed_Vaccinations_by_Race_data.csv", " > ", 
              here::here(), "/data/source/mo_vaccines/Completed_Vaccinations_by_Race_data.txt"))

system(paste0("iconv -f utf-16le -t utf-8 ",
              downloads_path, "/Initiated_Vaccinations_by_Ethnicity_data.csv", " > ", 
              here::here(), "/data/source/mo_vaccines/Initiated_Vaccinations_by_Ethnicity_data.txt"))

system(paste0("iconv -f utf-16le -t utf-8 ",
              downloads_path, "/Completed_Vaccinations_by_Ethnicity_data.csv", " > ", 
              here::here(), "/data/source/mo_vaccines/Completed_Vaccinations_by_Ethnicity_data.txt"))

rm(downloads_path)

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# load data ####
initiated_race <- read_tsv(file = "data/source/mo_vaccines/Initiated_Vaccinations_by_Race_data.txt") %>%
  clean_names() %>%
  rename(
    report_date = date_administered,
    value = race,
    initiated = covid_19_doses_administered
  )

completed_race <- read_tsv(file = "data/source/mo_vaccines/Completed_Vaccinations_by_Race_data.txt") %>%
  clean_names() %>%
  rename(
    report_date = date_administered,
    value = race,
    completed = covid_19_doses_administered
  )

initiated_latino <- read_tsv(file = "data/source/mo_vaccines/Initiated_Vaccinations_by_Ethnicity_data.txt") %>%
  clean_names() %>%
  rename(
    report_date = date_administered,
    value = ethnicity,
    initiated = covid_19_doses_administered
  )

completed_latino <- read_tsv(file = "data/source/mo_vaccines/Completed_Vaccinations_by_Ethnicity_data.txt") %>%
  clean_names() %>%
  rename(
    report_date = date_administered,
    value = ethnicity,
    completed = covid_19_doses_administered
  )

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# calculate totals ####

## calculate initiated vaccinations
initiated_race %>%
  mutate(category = case_when(
    jurisdiction == "Unknown Jurisdiction" ~ "Missouri, Unknown Jurisdiction",
    jurisdiction == "Unknown State" ~ "No Address Given",
    jurisdiction == "Out-of-State" ~ "Out-of-State",
    TRUE ~ "Missouri, Known Jurisdiction"
  )) %>%
  group_by(category) %>%
  summarise(initiated = sum(initiated, na.rm = TRUE)) %>%
  mutate(initiated_pct = initiated/sum(initiated)) -> x
  
## calculate completed vaccinatios
completed_race %>%
  mutate(category = case_when(
    jurisdiction == "Unknown Jurisdiction" ~ "Missouri, Unknown Jurisdiction",
    jurisdiction == "Unknown State" ~ "No Address Given",
    jurisdiction == "Out-of-State" ~ "Out-of-State",
    TRUE ~ "Missouri, Known Jurisdiction"
  )) %>%
  group_by(category) %>%
  summarise(completed = sum(completed, na.rm = TRUE)) %>%
  mutate(completed_pct = completed/sum(completed)) -> y

## combine
race_totals <- left_join(x, y, by = "category") %>%
  mutate(report_date = date, .before = category)

rm(x, y)

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# unit test latino data ####

## calculate initiated vaccinations
initiated_latino %>%
  mutate(category = case_when(
    jurisdiction == "Unknown Jurisdiction" ~ "Missouri, Unknown Jurisdiction",
    jurisdiction == "Unknown State" ~ "No Address Given",
    jurisdiction == "Out-of-State" ~ "Out-of-State",
    TRUE ~ "Missouri, Known Jurisdiction"
  )) %>%
  group_by(category) %>%
  summarise(initiated = sum(initiated, na.rm = TRUE)) %>%
  mutate(initiated_pct = initiated/sum(initiated)) -> x

## calculate completed vaccinatios
completed_latino %>%
  mutate(category = case_when(
    jurisdiction == "Unknown Jurisdiction" ~ "Missouri, Unknown Jurisdiction",
    jurisdiction == "Unknown State" ~ "No Address Given",
    jurisdiction == "Out-of-State" ~ "Out-of-State",
    TRUE ~ "Missouri, Known Jurisdiction"
  )) %>%
  group_by(category) %>%
  summarise(completed = sum(completed, na.rm = TRUE)) %>%
  mutate(completed_pct = completed/sum(completed)) -> y

expect_equal(race_totals$initiated, x$initiated)
expect_equal(race_totals$completed, y$completed)

rm(x,y)

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# write totals ####

write_csv(race_totals, file = paste0("data/source/mo_daily_vaccines/mo_total_vaccines_", date, ".csv"))

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# create race and ethnicity object ####

## initiated vaccinations
initiated_race %>%
  filter(jurisdiction %in% c("Unknown State", "Out-of-State") == FALSE) %>%
  group_by(value) %>%
  summarise(initiated = sum(initiated, na.rm = TRUE)) %>%
  mutate(value = ifelse(value == "Unknown", "Unknown, Race", value)) -> x

expect_equal(sum(race_totals[1:2,]$initiated), sum(x$initiated))

initiated_latino %>%
  filter(jurisdiction %in% c("Unknown State", "Out-of-State") == FALSE) %>%
  group_by(value) %>%
  summarise(initiated = sum(initiated, na.rm = TRUE)) %>%
  mutate(value = ifelse(value == "Unknown", "Unknown, Ethnicity", value)) -> y

expect_equal(sum(race_totals[1:2,]$initiated), sum(y$initiated))

y <- filter(y, value != "Not Hispanic or Latino")

vaccine_race_ethnic <- bind_rows(x,y) %>%
  arrange(value)

## completed vaccinations
completed_race %>%
  filter(jurisdiction %in% c("Unknown State", "Out-of-State") == FALSE) %>%
  group_by(value) %>%
  summarise(completed = sum(completed, na.rm = TRUE)) %>%
  mutate(value = ifelse(value == "Unknown", "Unknown, Race", value)) -> x

expect_equal(sum(race_totals[1:2,]$completed), sum(x$completed))

completed_latino %>%
  filter(jurisdiction %in% c("Unknown State", "Out-of-State") == FALSE) %>%
  group_by(value) %>%
  summarise(completed = sum(completed, na.rm = TRUE)) %>%
  mutate(value = ifelse(value == "Unknown", "Unknown, Ethnicity", value)) -> y

expect_equal(sum(race_totals[1:2,]$completed), sum(y$completed))

y <- filter(y, value != "Not Hispanic or Latino")

vaccine_race_ethnic_completed <- bind_rows(x,y) %>%
  arrange(value)

## combine
vaccine_race_ethnic <- left_join(vaccine_race_ethnic, vaccine_race_ethnic_completed, by = "value")

rm(x, y, vaccine_race_ethnic_completed, initiated_race, initiated_latino,
   completed_race, completed_latino)

## finishing prepping data
vaccine_race_ethnic <- vaccine_race_ethnic %>%
  mutate(value = case_when(
    value == "American Indian or Alaska Nati" ~ "Native",
    value == "Asian" ~ "Asian",
    value == "Black or African-American" ~ "Black",
    value == "Hispanic or Latino" ~ "Latino",
    value == "Multi-racial" ~ "Two or More",
    value == "Native Hawaiian or Other Pacif" ~ "Pacific Islander",
    value == "Other Race" ~ "Other Race",
    value == "Unknown, Ethnicity" ~ "Unknown, Ethnicity",
    value == "Unknown, Race" ~ "Unknown, Race",
    value == "White" ~ "White"
  )) %>%
  arrange(value)

vaccine_race_ethnic <- vaccine_race_ethnic %>% 
  mutate(report_date = date, .before = value) %>%
  mutate(geoid = 29, .before = value)

## calculate rates
### load source data
race <- read_csv("data/source/mo_race.csv") %>%
  mutate(geoid = as.character(geoid))

### calculate rates
race %>%
  select(-geoid) %>%
  left_join(vaccine_race_ethnic, ., by = "value") %>%
  mutate(initiated_rate = initiated/pop*100000, .after = initiated) %>%
  mutate(completed_rate = completed/pop*100000, .after = completed) %>%
  select(-pop) -> vaccine_race_ethnic

## write data
write_csv(vaccine_race_ethnic, "data/individual/mo_vaccine_race_rates.csv")

## clean-up
rm(race, race_totals, vaccine_race_ethnic)

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# county vaccine rates ####

## load data
county_sf <- st_read("data/source/mo_county_plus_vaccine.geojson")

county_tbl <- select(county_sf, GEOID, NAME, total_pop)
st_geometry(county_tbl) <- NULL

county_sf %>%
  select(-NAME, -total_pop, -district) %>%
  rename(geoid = GEOID) -> county_sf

## construct output
### scrape totals
county <- get_vaccine(metric = "county")

### initial tidy
county %>%
  arrange(county) %>%
  mutate(report_date = date, .before = county) %>%
  mutate(state = "Missouri", .after = county) %>%
  left_join(., county_tbl, by = c("county" = "NAME")) %>%
  select(report_date, GEOID, everything()) %>%
  rename(geoid = GEOID) %>%
  mutate(initiated_rate = initiated/total_pop*1000, .after = initiated) %>%
  mutate(complete_rate = complete/total_pop*1000, .after = complete) %>%
  mutate(last7_rate = last7/total_pop*1000, .after = last7) %>%
  select(-total_pop) -> county
  
### write daily data
write_csv(county, paste0("data/source/mo_daily_vaccines/mo_daily_vaccines_", date, ".csv"))

### create daily snapshot
county_daily <- left_join(county_sf, county, by = "geoid") %>%
  select(report_date, geoid, county, state, everything())

### write daily snapshot data
county_daily <- st_transform(county_daily, crs = 4326)

st_write(county_daily, "data/county/daily_snapshot_mo_vaccines.geojson", delete_dsn = TRUE)

### clean-up
rm(county, county_sf, county_tbl)

## calculate patrol areas
### prep vaccines
county_daily <- select(county_daily, report_date, geoid, initiated, complete, last7)
st_geometry(county_daily) <- NULL

### re-load data
county_sf <- st_read("data/source/mo_county_plus_vaccine.geojson") %>%
  select(GEOID, district, total_pop)
st_geometry(county_sf) <- NULL

### combine
left_join(county_daily, county_sf, by = c("geoid" = "GEOID")) %>%
  group_by(district) %>%
  summarise(
    report_date = first(report_date),
    initiated = sum(initiated),
    complete = sum(complete),
    last7 = sum(last7),
    total_pop = sum(total_pop)
  ) %>%
  mutate(initiated_rate = initiated/total_pop*1000, .after = initiated) %>%
  mutate(complete_rate = complete/total_pop*1000, .after = complete) %>%
  mutate(last7_rate = last7/total_pop*1000, .after = last7) %>%
  select(report_date, everything()) -> district_daily

write_csv(district_daily, "data/district/daily_snapshot_mo_vaccines.csv")

### clean-up
rm(county_daily, county_sf, district_daily)

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

## clean-up
rm(get_mo_vacc, get_tableau, get_vaccine)
