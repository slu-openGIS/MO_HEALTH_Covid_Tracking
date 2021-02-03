
## download
covid <- read_csv(file = "https://healthdata.gov/sites/default/files/reported_hospital_capacity_admissions_facility_level_weekly_average_timeseries_20201228.csv") %>%
  filter(state %in% c("MO", "IL", "KS", "OK")) %>%
  select(hospital_pk:zip) %>%
  mutate(hospital_name = stringr::str_to_title(hospital_name))

mo <- filter(covid, state == "MO")
mo <- distinct(mo, hospital_name, .keep_all = TRUE)

master <- sf::st_read("/Users/chris/Downloads/MO_2020_Hospitals_Oct_Update_shp/") %>%
  select(Facility, Address, City, ZIP, Latitude, Longitude) %>%
  mutate(Facility = stringr::str_to_title(Facility))

sf::st_geometry(master) <- NULL

mo_join <- left_join(mo, master, by = c("hospital_name" = "Facility"))
