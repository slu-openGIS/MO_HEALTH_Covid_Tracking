# pull and process hospitalization data

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# load data ####
## covid data
## need to make this dynamic based on update date

update <- get_last_update(source = "HHS")
hosp <- read_csv(file = paste0("https://healthdata.gov/sites/default/files/reported_hospital_capacity_admissions_facility_level_weekly_average_timeseries_", gsub("-", "", as.character(update)), ".csv"))
