# convert state vaccination tables ####
system(paste0("iconv -f utf-16le -t utf-8 ",
              downloads_path, "/Initiated_Vaccinations_by_Race_data.csv", " > ", 
              here::here(), "/data/source/mo_vaccines/Initiated_Vaccinations_by_Race_data.txt"))

rm(downloads_path)

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# load data ####
initiated_race <- read_tsv(file = "data/source/mo_vaccines/Initiated_Vaccinations_by_Race_data.txt") %>%
  clean_names() %>%
  rename(
    report_date = date_administered_1_1_1_1_1_1_1_1_copy, # date_administered,
    value = race_1_copy, # race,
    initiated = covid_19_doses_administered, # covid_19_doses_administered
    jurisdiction = jurisdiction_1_1_1_1_1_1_1_1_copy
  )

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #


initiated_race <- initiated_race %>%
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
  mutate(report_date = mdy(report_date)) %>%
  filter(jurisdiction == "St. Louis City")

black <- filter(initiated_race, value == "Black") %>%
  arrange(report_date) %>%
  mutate(initiated_avg = rollmean(initiated, k = 7, align = "right", fill = NA))

others <- filter(initiated_race, value != "White") %>%
  arrange(report_date) %>%
  group_by(report_date) %>%
  summarise(initiated = sum(initiated, na.rm = TRUE)) %>%
  mutate(initiated_avg = rollmean(initiated, k = 7, align = "right", fill = NA))
