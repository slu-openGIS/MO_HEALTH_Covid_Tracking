# pull and process hospitalization data

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# load data ####
## covid data
## need to make this dynamic based on update date
covid <- read_csv(file = "https://healthdata.gov/sites/default/files/reported_hospital_capacity_admissions_facility_level_weekly_average_timeseries_20201228.csv")
