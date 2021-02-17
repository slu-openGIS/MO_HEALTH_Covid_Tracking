
library(dplyr)
library(readr)
library(stringr)

library(censusxy)
library(sf)

source("source/functions/get_last_update.R")

update <- get_last_update(source = "HHS")
hosp <- read_csv(file = paste0("https://healthdata.gov/sites/default/files/reported_hospital_capacity_admissions_facility_level_weekly_average_timeseries_", gsub("-", "", as.character(update)), ".csv")) %>%
  select(hospital_pk, hospital_name, address, city, zip, state, fips_code) %>%
  distinct(hospital_pk, .keep_all = TRUE)

counties <- unlist(list(cape_girardeau_il = "17003",
                        joplin_ok = "40115",
                        kansas_city_ks = c("20091", "20103", "20107", "20121", "20209"),
                        st_louis_il = c("17005", "17013", "17027", "17083", "17117", 
                                        "17119", "17133", "17163"),
                        st_joseph_ks = "20043"))

hosp_mo <- filter(hosp, state == "MO")
hosp_mo_xl <- filter(hosp, fips_code %in% counties)

hosp_mo <- bind_rows(hosp_mo, hosp_mo_xl) %>%
  arrange(fips_code)

hosp_mo %>%
  mutate(address = str_to_title(address)) %>%
  mutate(address = str_replace(string = address, pattern = "^One", replace = "1")) %>%
  tidyr::separate(col = "address", into = c("address", "po_box"), sep = ",") %>%f
  mutate(city = str_to_title(city)) -> hosp_mo_2

hosp_mo_geo <- cxy_geocode(hosp_mo_2, id = "hospital_pk", street = "address", 
                           city = "city", state = "state", zip = "zip")

hosp_mo_geo_2 <- filter(hosp_mo_geo, is.na(cxy_lat) == FALSE)
hosp_mo_geo_2 <- st_as_sf(hosp_mo_geo_2, coords = c("cxy_lon", "cxy_lat"), crs = 4269)

write_csv(hosp_mo_geo, "data/source/hospitals/hospital_working_list.csv")

