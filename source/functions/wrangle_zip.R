
process_zip <- function(county, dates){
  
  # load zip data
  out <- purrr::map_df(unlist(dates), ~ wrangle_zip(date = .x, county = county))
  
  # read population
  if (county == 510){
    pop <- readr::read_csv("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/demographics/STL_ZCTA_St_Louis_City_Total_Pop.csv",
                           col_types = cols(
                             GEOID_ZCTA = col_double(),
                             total_pop = col_double()
                           )) 
  } else if (county == 189){
    pop <- readr::read_csv("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/demographics/STL_ZCTA_St_Louis_County_Total_Pop.csv",
                           col_types = cols(
                             GEOID_ZCTA = col_double(),
                             total_pop = col_double()
                           )) 
  } else if (county == 183){
    pop <- readr::read_csv("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/demographics/STL_ZCTA_St_Charles_County_Total_Pop.csv",
                           col_types = cols(
                             GEOID_ZCTA = col_double(),
                             total_pop = col_double()
                           )) 
  } else if (county == 99){
    pop <- readr::read_csv("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/demographics/STL_ZCTA_Jefferson_County_Total_Pop.csv",
                           col_types = cols(
                             GEOID_ZCTA = col_double(),
                             total_pop = col_double()
                           )) 
  }
  
  # prep population
  pop <- dplyr::mutate(pop, GEOID_ZCTA = as.character(GEOID_ZCTA))
  
  # calculate rate
  out <- dplyr::left_join(out, pop, by = c("zip" = "GEOID_ZCTA"))
  out <- dplyr::mutate(out, case_rate = cases/total_pop*1000)
  out <- dplyr::mutate(out, case_rate = ifelse(is.na(case_rate) == TRUE, NaN, case_rate))
  out <- dplyr::select(out, -total_pop)
  
  # return output
  return(out)
  
}

wrangle_zip <- function(date, county){
  
  # set county name
  if (county == 510){
    county_name <- "St. Louis City" 
  } else if (county == 189){
    county_name <- "St. Louis"
  } else if (county == 183){
    county_name <- "St. Charles"
  } else if (county == 99){
    county_name <- "Jefferson"
  }
  
  # construct file path
  if (county == 510){
    file <- paste0("data/source/stl_daily_zips/stl_city_", date, ".csv")
  } else if (county == 189){
    file <- paste0("data/source/stl_daily_zips/stl_county_", date, ".csv")
  } else if (county == 183){
    file <- paste0("data/source/stl_daily_zips/st_charles_", date, ".csv")
  } else if (county == 99){
    file <- paste0("data/source/stl_daily_zips/jeff_county_", date, ".csv")
  }
  
  # read data
  df <- readr::read_csv(file, col_types = cols(
    zip = col_double(),
    count = col_double()
  ))
  
  # add new columns, modify existing
  df <- dplyr::mutate(df,
                      report_date = date,
                      zip = as.character(zip),
                      geoid = ifelse(county == 99, paste0("290", county), paste0("29", county)),
                      county = county_name,
                      state = "Missouri",
                      count = ifelse(is.na(count) == TRUE, NaN, count))
  df <- dplyr::select(df, report_date, zip, geoid, county, state, count)
  df <- dplyr::rename(df, cases = count)
  
  # return output
  return(df)
  
}
