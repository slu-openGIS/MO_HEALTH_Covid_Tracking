# Build ZIP Code Data ####

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# confirm Franklin County data ####
q <- usethis::ui_yeah("Have you updated the filename for the latest Franklin County ZIP code data?")

if (q == FALSE){
  stop("Please update the filename before proceeding!")
}

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#


# load ZIP data ####
stl_city <- st_read("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/geometries/STL_ZCTA_St_Louis_City.geojson", 
                           crs = 4326, stringsAsFactors = FALSE)
stl_county <- st_read("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/geometries/STL_ZCTA_St_Louis_County.geojson", 
                    crs = 4326, stringsAsFactors = FALSE)
st_charles <- st_read("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/geometries/STL_ZCTA_St_Charles_County.geojson", 
                      crs = 4326, stringsAsFactors = FALSE)
jeffco <- st_read("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/geometries/STL_ZCTA_Jefferson_County.geojson", 
                      crs = 4326, stringsAsFactors = FALSE)
# lincoln <- st_read("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/geometries/STL_ZCTA_Lincoln_County.geojson", 
#                  crs = 4326, stringsAsFactors = FALSE)
warren <- st_read("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/geometries/STL_ZCTA_Warren_County.geojson", 
                  crs = 4326, stringsAsFactors = FALSE)
franklin <- st_read("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/geometries/STL_ZCTA_Franklin_County.geojson", 
                  crs = 4326, stringsAsFactors = FALSE)

city_county <- st_read("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/geometries/STL_ZCTA_City_County.geojson", 
                       crs = 4326, stringsAsFactors = FALSE)
region <- st_read("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/geometries/STL_ZCTA_Metro_West.geojson", 
                       crs = 4326, stringsAsFactors = FALSE)
metro_east <- st_read("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/geometries/STL_ZCTA_Metro_East.geojson", 
                  crs = 4326, stringsAsFactors = FALSE)

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# build county-level ZIP data for MO ####
## Define Dates
city_dates <- c(seq(as.Date("2020-04-01"), as.Date("2020-05-18"), by="days"), seq(as.Date("2020-05-20"), date, by="days"))
county_dates <- c(seq(as.Date("2020-04-06"), as.Date("2020-05-18"), by="days"), seq(as.Date("2020-05-20"), date, by="days"))
st_charles_dates <- seq(as.Date("2020-07-14"), date, by="days")
jeffco_dates <- seq(as.Date("2020-07-23"), date, by="days")
lincoln_dates <- seq(as.Date("2020-10-28"), date, by="days")
warren_dates <- seq(as.Date("2020-10-28"), date, by="days")
franklin_dates <- seq(as.Date("2020-03-23"), date-1, by="days")
metro_east_dates <- seq(as.Date("2020-10-27"), date, by="days")

## Process Individual Jurisdictions
city_data <- process_zip(county = 510, dates = city_dates)
county_data <- process_zip(county = 189, dates = county_dates)
st_charles_data <- process_zip(county = 183, dates = st_charles_dates)
jeffco_data <- process_zip(county = 99, dates = jeffco_dates)
# lincoln_data <- process_zip(county = 113, dates = lincoln_dates)
warren_data <- process_zip(county = 219, dates = warren_dates)
metro_east_data <- process_zip(county = 17, dates = metro_east_dates)

### Process Franklin County
franklin_tbl <- franklin
st_geometry(franklin_tbl) <- NULL

franklin_dates %>%
  unlist() %>%
  map_df(~historic_expand(ref = franklin_tbl, date = .x)) -> franklin_dates

franklin_data <- read_excel(paste0("/Users/chris/Downloads/", franklin_path)) %>%
  filter(Delete %in% "x" == FALSE) %>%
  select(Date, Zip) %>%
  filter(is.na(Date) == FALSE & is.na(Zip) == FALSE) %>%
  group_by(Date, Zip) %>%
  summarise(new_cases = n()) %>%
  rename(
    report_date = Date,
    GEOID_ZCTA = Zip
  ) %>%
  mutate(
    report_date = as.Date(report_date),
    GEOID_ZCTA = as.character(GEOID_ZCTA))

franklin_data <- left_join(franklin_dates, franklin_data, by = c("report_date", "GEOID_ZCTA"))

franklin_data %>% 
  mutate(new_cases = ifelse(is.na(new_cases) == TRUE, 0, new_cases)) %>%
  group_by(GEOID_ZCTA) %>% 
  mutate(cases = cumsum(new_cases)) %>%
  mutate(cases = ifelse(cases < 5, NA, cases),
    new_cases = ifelse(cases < 5, NA, new_cases)) %>%
  ungroup() -> franklin_data

first_date <- filter(franklin_data, is.na(cases) == FALSE) %>%
  slice(1) %>%
  select(report_date) %>%
  pull()

franklin_data %>%
  filter(report_date >= first_date) %>%
  select(report_date, GEOID_ZCTA, cases, new_cases) %>%
  rename(zip = GEOID_ZCTA) %>%
  mutate(geoid = "29071", .after = "zip") %>%
  mutate(county = "Lincoln", .after = "geoid") %>%
  mutate(state = "Missouri", .after = "county") -> franklin_data

franklin_pop <- readr::read_csv("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/demographics/STL_ZCTA_Franklin_County_Total_Pop.csv",
                       col_types = cols(
                         GEOID_ZCTA = col_character(),
                         total_pop = col_double()
                       )) 

franklin_data %>%
  group_by(zip) %>%
  mutate(case_avg = rollmean(new_cases, k = 14, align = "right", fill = NA)) %>%
  ungroup() %>%
  left_join(., franklin_pop, by = c("zip" = "GEOID_ZCTA")) %>%
  mutate(case_rate = cases/total_pop*1000) %>%
  mutate(case_avg_rate = case_avg/total_pop*10000) %>%
  select(-total_pop) -> franklin_data

## Clean-up
rm(city_dates, county_dates, st_charles_dates, jeffco_dates, lincoln_dates, 
   warren_dates, metro_east_dates, franklin_dates, franklin_pop, franklin_tbl,
   franklin_path, first_date)

## Save Individual Jurisdictions
write_csv(city_data, "data/zip/zip_stl_city.csv")
write_csv(county_data, "data/zip/zip_stl_county.csv")
write_csv(st_charles_data, "data/zip/zip_st_charles_county.csv")
write_csv(jeffco_data, "data/zip/zip_jefferson_county.csv")
# write_csv(lincoln_data, "data/zip/zip_lincoln_county.csv")
write_csv(warren_data, "data/zip/zip_warren_county.csv")
write_csv(franklin_data, "data/zip/zip_franklin_county.csv")

metro_east_data %>%
  select(report_date, zip, cases) %>%
  write_csv(., "data/zip/zip_illinois.csv")

metro_east_data <- filter(metro_east_data, zip %in% metro_east$GEOID_ZCTA)
write_csv(metro_east_data, "data/zip/zip_metro_east.csv")

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# unit test county-level data for MO ####
## St. Louis City
stl_city_test <- filter(city_data, report_date %in% c(date, date-1)) %>%
  mutate(period = ifelse(report_date == date, "current", "prior")) %>%
  select(period, zip, cases) %>%
  pivot_wider(names_from = period, values_from = cases)

stl_city_test <- all(stl_city_test$current == stl_city_test$prior, na.rm = TRUE)

stl_city_test2 <- filter(city_data, report_date %in% c(date, date-2)) %>%
  mutate(period = ifelse(report_date == date, "current", "prior")) %>%
  select(period, zip, cases) %>%
  pivot_wider(names_from = period, values_from = cases)

stl_city_test2 <- all(stl_city_test2$current == stl_city_test2$prior, na.rm = TRUE)

## St. Louis County
stl_county_test <- filter(county_data, report_date %in% c(date, date-1)) %>%
  mutate(period = ifelse(report_date == date, "current", "prior")) %>%
  select(period, zip, cases) %>%
  pivot_wider(names_from = period, values_from = cases)

stl_county_test <- all(stl_county_test$current == stl_county_test$prior, na.rm = TRUE)

stl_county_test2 <- filter(county_data, report_date %in% c(date, date-2)) %>%
  mutate(period = ifelse(report_date == date, "current", "prior")) %>%
  select(period, zip, cases) %>%
  pivot_wider(names_from = period, values_from = cases)

stl_county_test2 <- all(stl_county_test2$current == stl_county_test2$prior, na.rm = TRUE)

## St. Charles County
stl_charles_test <- filter(st_charles_data, report_date %in% c(date, date-1)) %>%
  mutate(period = ifelse(report_date == date, "current", "prior")) %>%
  select(period, zip, cases) %>%
  pivot_wider(names_from = period, values_from = cases)

stl_charles_test <- all(stl_charles_test$current == stl_charles_test$prior, na.rm = TRUE)

stl_charles_test2 <- filter(st_charles_data, report_date %in% c(date, date-2)) %>%
  mutate(period = ifelse(report_date == date, "current", "prior")) %>%
  select(period, zip, cases) %>%
  pivot_wider(names_from = period, values_from = cases)

stl_charles_test2 <- all(stl_charles_test2$current == stl_charles_test2$prior, na.rm = TRUE)

## Jefferson County
jeffco_test <- filter(jeffco_data, report_date %in% c(date, date-1)) %>%
  mutate(period = ifelse(report_date == date, "current", "prior")) %>%
  select(period, zip, cases) %>%
  pivot_wider(names_from = period, values_from = cases)

jeffco_test <- all(jeffco_test$current == jeffco_test$prior, na.rm = TRUE)

jeffco_test2 <- filter(jeffco_data, report_date %in% c(date, date-2)) %>%
  mutate(period = ifelse(report_date == date, "current", "prior")) %>%
  select(period, zip, cases) %>%
  pivot_wider(names_from = period, values_from = cases)

jeffco_test2 <- all(jeffco_test2$current == jeffco_test2$prior, na.rm = TRUE)

## Lincoln County
# lincoln_test <- filter(lincoln_data, report_date %in% c(date, date-1)) %>%
#  mutate(period = ifelse(report_date == date, "current", "prior")) %>%
#  select(period, zip, cases) %>%
#  pivot_wider(names_from = period, values_from = cases)

# lincoln_test <- all(lincoln_test$current == lincoln_test$prior, na.rm = TRUE)

# lincoln_test2 <- filter(lincoln_data, report_date %in% c(date, date-2)) %>%
#  mutate(period = ifelse(report_date == date, "current", "prior")) %>%
#  select(period, zip, cases) %>%
#  pivot_wider(names_from = period, values_from = cases)

# lincoln_test2 <- all(lincoln_test2$current == lincoln_test2$prior, na.rm = TRUE)

## Warren County
warren_test <- filter(warren_data, report_date %in% c(date, date-1)) %>%
  mutate(period = ifelse(report_date == date, "current", "prior")) %>%
  select(period, zip, cases) %>%
  pivot_wider(names_from = period, values_from = cases)

warren_test <- all(warren_test$current == warren_test$prior, na.rm = TRUE)

warren_test2 <- filter(warren_data, report_date %in% c(date, date-2)) %>%
  mutate(period = ifelse(report_date == date, "current", "prior")) %>%
  select(period, zip, cases) %>%
  pivot_wider(names_from = period, values_from = cases)

warren_test2 <- all(warren_test2$current == warren_test2$prior, na.rm = TRUE)

## Warren County
franklin_test <- filter(franklin_data, report_date %in% c(date-1, date-2)) %>%
  mutate(period = ifelse(report_date == date-1, "current", "prior")) %>%
  select(period, zip, cases) %>%
  pivot_wider(names_from = period, values_from = cases)

franklin_test <- all(franklin_test$current == franklin_test$prior, na.rm = TRUE)

franklin_test2 <- filter(franklin_data, report_date %in% c(date-2, date-3)) %>%
  mutate(period = ifelse(report_date == date-2, "current", "prior")) %>%
  select(period, zip, cases) %>%
  pivot_wider(names_from = period, values_from = cases)

franklin_test2 <- all(franklin_test2$current == franklin_test2$prior, na.rm = TRUE)

## Metro East
metro_east_test <- filter(metro_east_data, report_date %in% c(date, date-1)) %>%
  mutate(period = ifelse(report_date == date, "current", "prior")) %>%
  select(period, zip, cases) %>%
  pivot_wider(names_from = period, values_from = cases)

metro_east_test <- all(metro_east_test$current == metro_east_test$prior, na.rm = TRUE)

metro_east_test2 <- filter(metro_east_data, report_date %in% c(date, date-2)) %>%
  mutate(period = ifelse(report_date == date, "current", "prior")) %>%
  select(period, zip, cases) %>%
  pivot_wider(names_from = period, values_from = cases)

metro_east_test2 <- all(metro_east_test2$current == metro_east_test2$prior, na.rm = TRUE)

## Combine
zip_test <- tibble(
  source = c("St. Louis City", "St. Louis City", "St. Louis County", "St. Louis County", 
             "St. Charles County", "St. Charles County", "Jefferson County", "Jefferson County",
             "Warren County", "Warren County", "Franklin County", "Franklin County",
             # "Lincoln County", "Lincoln County",
             "Metro East", "Metro East"),
  period = c("1 day", "2 days", "1 day", "2 days", "1 day", "2 days", "1 day", "2 days", 
             "1 day", "2 days", "1 day", "2 days", "1 day", "2 days"), # , "1 day", "2 days"
  result = c(stl_city_test, stl_city_test2, stl_county_test, stl_county_test2, 
             stl_charles_test, stl_charles_test2, jeffco_test, jeffco_test2,
             warren_test, warren_test2, franklin_test, franklin_test2,
             # lincoln_test, lincoln_test2,
             metro_east_test, metro_east_test2)
)

## Clean-up
rm(stl_city_test, stl_city_test2, stl_county_test, stl_county_test2, 
   stl_charles_test, stl_charles_test2, jeffco_test, jeffco_test2,
   warren_test, warren_test2, # lincoln_test, lincoln_test2, 
   metro_east_test, metro_east_test2, franklin_test, franklin_test2)

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# subset MO data to report date ####
## Subset and Project
stl_city <- filter(city_data, report_date == date) %>%
  left_join(stl_city, ., by = c("GEOID_ZCTA" = "zip"))
stl_county <- filter(county_data, report_date == date) %>%
  left_join(stl_county, ., by = c("GEOID_ZCTA" = "zip"))
st_charles <- filter(st_charles_data, report_date == date) %>%
  left_join(st_charles, ., by = c("GEOID_ZCTA" = "zip"))
jeffco <- filter(jeffco_data, report_date == date) %>%
  left_join(jeffco, ., by = c("GEOID_ZCTA" = "zip"))
# lincoln <- filter(lincoln_data, report_date == date) %>%
#  left_join(lincoln, ., by = c("GEOID_ZCTA" = "zip"))
warren <- filter(warren_data, report_date == date) %>%
  left_join(warren, ., by = c("GEOID_ZCTA" = "zip"))
franklin <- filter(franklin_data, report_date == date-1) %>%
  left_join(franklin, ., by = c("GEOID_ZCTA" = "zip"))
metro_east <- filter(metro_east_data, report_date == date) %>%
  left_join(metro_east, ., by = c("GEOID_ZCTA" = "zip")) %>%
  select(-state)

## fix issues with lincoln county
# lincoln <- mutate(lincoln,
#                  report_date = date,
#                  geoid = "29113",
#                  county = "Lincoln",
#                  state = "Missouri")

## Save Individual Jurisdictions
st_write(stl_city, "data/zip/daily_snapshot_stl_city.geojson", delete_dsn = TRUE)
st_write(stl_county, "data/zip/daily_snapshot_stl_county.geojson", delete_dsn = TRUE)
st_write(st_charles, "data/zip/daily_snapshot_st_charles_county.geojson", delete_dsn = TRUE)
st_write(jeffco, "data/zip/daily_snapshot_jefferson_county.geojson", delete_dsn = TRUE)
# st_write(lincoln, "data/zip/daily_snapshot_lincoln_county.geojson", delete_dsn = TRUE)
st_write(warren, "data/zip/daily_snapshot_warren_county.geojson", delete_dsn = TRUE)
st_write(franklin, "data/zip/daily_snapshot_franklin_county.geojson", delete_dsn = TRUE)
st_write(metro_east, "data/zip/daily_snapshot_metro_east.geojson", delete_dsn = TRUE)

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# add race and poverty data for MO ####
stl_city <- left_join(stl_city, build_pop_zip(county = 510), by = "GEOID_ZCTA")
stl_county <- left_join(stl_county, build_pop_zip(county = 189), by = "GEOID_ZCTA")
st_charles <- left_join(st_charles, build_pop_zip(county = 183), by = "GEOID_ZCTA")
jeffco <- left_join(jeffco, build_pop_zip(county = 99), by = "GEOID_ZCTA")
warren <- left_join(warren, build_pop_zip(county = 219), by = "GEOID_ZCTA")
franklin <- left_join(franklin, build_pop_zip(county = 71), by = "GEOID_ZCTA")

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# build city-county level data ####
### Load Data
pop <- read_csv("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/demographics/STL_ZCTA_City_County_Total_Pop.csv",
                col_types = cols(
                  GEOID_ZCTA = col_character(),
                  total_pop = col_double()
                  )) 

## Identify Zips with Missing Data
city_county_na <- rbind(stl_city, stl_county) %>%
  select(GEOID_ZCTA, cases) %>%
  filter(is.na(cases) == TRUE)
city_county_na <- unique(city_county_na$GEOID_ZCTA)

## Subset Zips that are Partially Missing
city_county_partials <- rbind(stl_city, stl_county) %>%
  select(GEOID_ZCTA, cases, case_rate, wht_pct, blk_pct, pvty_pct) %>%
  filter(GEOID_ZCTA %in% city_county_na == TRUE)

## Subset and Process Zips that are Complete
city_county_full <- rbind(stl_city, stl_county) %>%
  select(GEOID_ZCTA, cases) %>%
  filter(GEOID_ZCTA %in% city_county_na == FALSE)

st_geometry(city_county_full) <- NULL

city_county_full %>%
  group_by(GEOID_ZCTA) %>%
  summarise(cases = sum(cases)) -> city_county_full

city_county <- filter(city_county, GEOID_ZCTA %in% unique(city_county_full$GEOID_ZCTA)) %>%
  left_join(., city_county_full, by = "GEOID_ZCTA") %>%
  left_join(., pop, by = "GEOID_ZCTA") %>%
  mutate(case_rate = cases/total_pop*1000) %>%
  select(-total_pop)

city_county <- left_join(city_county, build_pop_zip(county = "city-county"), by = "GEOID_ZCTA")

## Combine Geometries
city_county <- rbind(city_county, city_county_partials)

## Write Data
st_write(city_county, "data/zip/daily_snapshot_city_county.geojson", delete_dsn = TRUE)

## Clean-up
rm(city_county, city_county_full, city_county_partials, city_county_na, pop)

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

## build regional data (MO only) ####
## Load Data
pop <- read_csv("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/demographics/STL_ZCTA_Metro_West_Total_Pop.csv",
                col_types = cols(
                  GEOID_ZCTA = col_character(),
                  total_pop = col_double()
                )) 

## temporarily fix warren county
warren %>% 
  mutate(case_avg = NA, .after = "new_cases") %>%
  mutate(case_avg_rate = NA, .after = "case_rate") -> warren

## Identify Zips with Missing Data
regional_na <- rbind(stl_city, stl_county, st_charles, jeffco, warren, franklin) %>%
  select(GEOID_ZCTA, cases) %>%
  filter(is.na(cases) == TRUE)
regional_na <- unique(regional_na$GEOID_ZCTA)

## Subset Zips that are Partially Missing
regional_partials <- rbind(stl_city, stl_county, st_charles, jeffco, warren, franklin) %>%
  select(GEOID_ZCTA, cases, case_rate, wht_pct, blk_pct, pvty_pct) %>%
  filter(GEOID_ZCTA %in% regional_na == TRUE)

## Subset and Process Zips that are Complete
regional_full <- rbind(stl_city, stl_county, st_charles, jeffco, warren, franklin) %>%
  select(GEOID_ZCTA, cases) %>%
  filter(GEOID_ZCTA %in% regional_na == FALSE)

st_geometry(regional_full) <- NULL

regional_full %>%
  group_by(GEOID_ZCTA) %>%
  summarise(cases = sum(cases)) -> regional_full

## process longitudinal data
### group and summarise
regional_data <- bind_rows(city_data, county_data, jeffco_data, st_charles_data, warren_data, franklin_data) %>%
  select(report_date, zip, new_cases) %>%
  filter(zip %in% unique(regional_full$GEOID_ZCTA)) %>%
  group_by(report_date, zip) %>%
  summarise(new_cases = sum(new_cases, na.rm = TRUE))

regional_data <- arrange(regional_data, report_date, zip)

### calculate rolling average
regional_data %>%
  group_by(zip) %>%
  mutate(case_avg = rollmean(new_cases, k = 14, align = "right", fill = NA)) %>%
  filter(row_number() == n()) -> regional_data

## create regional data
region <- filter(region, GEOID_ZCTA %in% unique(regional_full$GEOID_ZCTA)) %>%
  left_join(., regional_full, by = "GEOID_ZCTA") %>%
  left_join(., regional_data, by = c("GEOID_ZCTA" = "zip")) %>%
  left_join(., pop, by = "GEOID_ZCTA") %>%
  mutate(case_rate = cases/total_pop*1000) %>%
  mutate(case_avg_rate = case_avg/total_pop*10000) %>%
  select(-total_pop)

region <- left_join(region, build_pop_zip(county = "regional"), by = "GEOID_ZCTA")

## process longitudinal data for partial zips
### split up regional_partials
regional_partials_valid <- filter(regional_partials, is.na(cases) == FALSE)
regional_partials_invalid <- filter(regional_partials, is.na(cases) == TRUE)

### group and summarise
regional_data <- bind_rows(city_data, county_data, jeffco_data, st_charles_data, warren_data, franklin_data) %>%
  select(report_date, zip, new_cases) %>%
  filter(zip %in% unique(regional_partials_valid$GEOID_ZCTA)) %>%
  group_by(report_date, zip) %>%
  summarise(new_cases = sum(new_cases, na.rm = TRUE))

regional_data <- arrange(regional_data, report_date, zip)

### calculate rolling average
regional_data %>%
  group_by(zip) %>%
  mutate(case_avg = rollmean(new_cases, k = 14, align = "right", fill = NA)) %>%
  filter(row_number() == n()) -> regional_data

regional_data %>%
  left_join(., pop, by = c("zip" = "GEOID_ZCTA")) %>%
  mutate(case_avg_rate = case_avg/total_pop*10000)  %>%
  select(-total_pop) -> regional_data

### combine
regional_partials_invalid <- mutate(regional_partials_invalid,
                                    report_date = date,
                                    new_cases = NA,
                                    case_avg = NA, 
                                    case_avg_rate = NA)

regional_partials_valid <- left_join(regional_partials_valid, regional_data, by = c("GEOID_ZCTA" = "zip"))
regional_partials <- rbind(regional_partials_valid, regional_partials_invalid)

## Combine Geometries
region <- rbind(region, regional_partials)
region <- select(region, GEOID_ZCTA, report_date, cases, case_rate, 
                 new_cases, case_avg, case_avg_rate,
                 wht_pct, blk_pct, pvty_pct)

## Write Data
st_write(region, "data/zip/daily_snapshot_regional.geojson", delete_dsn = TRUE)

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# clean-up MO ZIP objects ####
rm(regional_full, regional_partials, regional_na, regional_data,
   regional_partials_invalid, regional_partials_valid, pop)
rm(jeffco, st_charles, stl_city, stl_county, lincoln, warren, franklin)
rm(city_data, county_data, st_charles_data, jeffco_data, warren_data, 
   lincoln_data, metro_east_data, franklin_data)

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

## combine to create metro data
region <- select(region, GEOID_ZCTA, report_date, cases, case_rate, new_cases) # case_avg, case_avg_rate
metro <- rbind(region, metro_east)

## Write Data
st_write(metro, "data/zip/daily_snapshot_metro.geojson", delete_dsn = TRUE)

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# rm(process_zip, wrangle_zip, build_pop_zip)
