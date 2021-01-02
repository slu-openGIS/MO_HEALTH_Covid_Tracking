
## download
covid <- read_csv(file = "https://healthdata.gov/sites/default/files/reported_hospital_capacity_admissions_facility_level_weekly_average_timeseries_20201228.csv") %>%
  filter(state %in% c("MO", "IL", "KS", "OK")) %>%
  select(hospital_pk:zip)
