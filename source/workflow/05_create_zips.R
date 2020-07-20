# Build ZIP Code Data ####

## Load Data ####
stl_city <- st_read("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/geometries/STL_ZCTA_St_Louis_City.geojson", 
                           crs = 4326, stringsAsFactors = FALSE)
stl_county <- st_read("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/geometries/STL_ZCTA_St_Louis_County.geojson", 
                    crs = 4326, stringsAsFactors = FALSE)
st_charles <- st_read("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/geometries/STL_ZCTA_St_Charles_County.geojson", 
                      crs = 4326, stringsAsFactors = FALSE)
jeffco <- st_read("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/geometries/STL_ZCTA_Jefferson_County.geojson", 
                      crs = 4326, stringsAsFactors = FALSE)

city_county <- st_read("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/geometries/STL_ZCTA_City_County.geojson", 
                       crs = 4326, stringsAsFactors = FALSE)
region <- st_read("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/geometries/STL_ZCTA_Regional.geojson", 
                       crs = 4326, stringsAsFactors = FALSE)

## Build County Level Data ####
### Define Dates
city_dates <- c(seq(as.Date("2020-04-01"), as.Date("2020-05-18"), by="days"), seq(as.Date("2020-05-20"), date, by="days"))

### Load ZIP Data
city_dates %>%
  unlist() %>%
  map_df(~ wrangle_zip(date = .x, county = 510)) %>%
  rename(
    cases = confirmed,
    case_rate = confirmed_rate
  ) %>%
  mutate(zip = as.character(zip)) %>% 
  mutate(
    cases = ifelse(is.na(cases) == TRUE, NaN, cases),
    case_rate = ifelse(is.na(case_rate) == TRUE, NaN, case_rate)
  ) -> stl_city_covid

# need to expand code in wrangle_zip to accommodate Jefferson and St. Charles counties
