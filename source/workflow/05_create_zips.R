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
county_dates <- c(seq(as.Date("2020-04-06"), as.Date("2020-05-18"), by="days"), seq(as.Date("2020-05-20"), date, by="days"))
st_charles_dates <- seq(as.Date("2020-07-14"), date, by="days")
jeffco_dates <- seq(as.Date("2020-07-23"), date, by="days")

### Process Individual Jurisdictions
city_data <- process_zip(county = 510, dates = city_dates)
county_data <- process_zip(county = 189, dates = county_dates)
st_charles_data <- process_zip(county = 183, dates = st_charles_dates)
jeffco_data <- process_zip(county = 99, dates = jeffco_dates)

### Save Individual Jurisdictions
write_csv(city_data, "data/zip/zip_stl_city.csv")
write_csv(county_data, "data/zip/zip_stl_county.csv")
write_csv(st_charles_data, "data/zip/zip_st_charles_county.csv")
write_csv(jeffco_data, "data/zip/zip_jefferson_county.csv")

## Build City-County Level Data ####


