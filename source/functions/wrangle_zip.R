
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
  } else if (county == 113){
    pop <- readr::read_csv("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/demographics/STL_ZCTA_Lincoln_County_Total_Pop.csv",
                           col_types = cols(
                             GEOID_ZCTA = col_double(),
                             total_pop = col_double()
                           )) 
  } else if (county == 219){
    pop <- readr::read_csv("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/demographics/STL_ZCTA_Warren_County_Total_Pop.csv",
                           col_types = cols(
                             GEOID_ZCTA = col_double(),
                             total_pop = col_double()
                           )) 
  } else if (county == 17){
    pop <- readr::read_csv("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/demographics/STL_ZCTA_Metro_East_Total_Pop.csv",
                           col_types = cols(
                             GEOID_ZCTA = col_double(),
                             total_pop = col_double()
                           ))     
  }
  
  # prep population
  pop <- dplyr::mutate(pop, GEOID_ZCTA = as.character(GEOID_ZCTA))
  
  # calculate rate
  out <- dplyr::left_join(out, pop, by = c("zip" = "GEOID_ZCTA"))
  
  # calculate 
  out <- dplyr::group_by(out, zip)
  out <- dplyr::mutate(out, new_cases = cases - lag(cases))
  
  if (county %in% c(17, 113, 219) == FALSE){
    out <- dplyr::mutate(out, case_avg = rollmean(new_cases, k = 14, align = "right", fill = NA))
  }
  
  out <- dplyr::ungroup(out)
  
  # calculate rates
  out <- dplyr::mutate(out, case_rate = cases/total_pop*1000)
  # out <- dplyr::mutate(out, case_rate = ifelse(is.na(case_rate) == TRUE, NaN, case_rate))
  
  if (county %in% c(17, 113, 219) == FALSE){
    out <- dplyr::mutate(out, case_avg_rate = case_avg/total_pop*10000)
  }
  
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
  } else if (county == 113){
    county_name <- "Lincoln"
  } else if (county == 219){
    county_name <- "Warren"
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
  } else if (county == 113){
    file <- paste0("data/source/stl_daily_zips/lincoln_", date, ".csv")
  } else if (county == 219){
    file <- paste0("data/source/stl_daily_zips/warren_", date, ".csv")
  } else if (county == 17){
    file <- paste0("data/source/il_daily_zips/il_zips_", date, ".csv")
  }
  
  # read data
  df <- readr::read_csv(file, col_types = cols(
    zip = col_double(),
    count = col_double()
  ))
  
  # fix warren county 63380
  ## this zip does not have a 2018 ZCTA, but is surrounded by 63383
  if (county == 219){
    df <- dplyr::mutate(df, zip = ifelse(zip == 63380, 63383, zip))
    df <- dplyr::group_by(df, zip) 
    df <- dplyr::summarise(df, count = sum(count, na.rm = TRUE))
  }
  
  # add new columns, modify existing
  if (county == 17){
    
    df <- dplyr::mutate(df,
                        report_date = date,
                        zip = as.character(zip),
                        state = "Illinois") # ,
    # count = ifelse(is.na(count) == TRUE, NaN, count))
    df <- dplyr::select(df, report_date, zip, state, count)
    df <- dplyr::rename(df, cases = count) 
    
  } else {
    
    df <- dplyr::mutate(df,
                        report_date = date,
                        zip = as.character(zip),
                        geoid = ifelse(county == 99, paste0("290", county), paste0("29", county)),
                        county = county_name,
                        state = "Missouri") # ,
    # count = ifelse(is.na(count) == TRUE, NaN, count))
    df <- dplyr::select(df, report_date, zip, geoid, county, state, count)
    df <- dplyr::rename(df, cases = count) 
    
  }
  
  # return output
  return(df)
  
}

build_pop_zip <- function(county){
  
  # read population
  if (county == 510){
    race <- readr::read_csv("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/demographics/STL_ZCTA_St_Louis_City_Race.csv",
                           col_types = cols(
                             GEOID_ZCTA = col_character(),
                             wht_pct = col_double(),
                             blk_pct = col_double()
                           )) 
    
    poverty <- readr::read_csv("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/demographics/STL_ZCTA_St_Louis_City_Poverty.csv",
                               col_types = cols(
                                 GEOID_ZCTA = col_character(),
                                 pvty_pct = col_double()
                               )) 
    
  } else if (county == 189){
    race <- readr::read_csv("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/demographics/STL_ZCTA_St_Louis_County_Race.csv",
                           col_types = cols(
                             GEOID_ZCTA = col_character(),
                             wht_pct = col_double(),
                             blk_pct = col_double()
                           )) 
    
    poverty <- readr::read_csv("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/demographics/STL_ZCTA_St_Louis_County_Poverty.csv",
                               col_types = cols(
                                 GEOID_ZCTA = col_character(),
                                 pvty_pct = col_double()
                               )) 
  } else if (county == 183){
    race <- readr::read_csv("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/demographics/STL_ZCTA_St_Charles_County_Race.csv",
                           col_types = cols(
                             GEOID_ZCTA = col_character(),
                             wht_pct = col_double(),
                             blk_pct = col_double()
                           )) 
    
    poverty <- readr::read_csv("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/demographics/STL_ZCTA_St_Charles_County_Poverty.csv",
                               col_types = cols(
                                 GEOID_ZCTA = col_character(),
                                 pvty_pct = col_double()
                               )) 
  } else if (county == 99){
    race <- readr::read_csv("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/demographics/STL_ZCTA_Jefferson_County_Race.csv",
                           col_types = cols(
                             GEOID_ZCTA = col_character(),
                             wht_pct = col_double(),
                             blk_pct = col_double()
                           )) 
    
    poverty <- readr::read_csv("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/demographics/STL_ZCTA_Jefferson_County_Poverty.csv",
                               col_types = cols(
                                 GEOID_ZCTA = col_character(),
                                 pvty_pct = col_double()
                               )) 
  } else if (county == 113){
    race <- readr::read_csv("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/demographics/STL_ZCTA_Lincoln_County_Race.csv",
                            col_types = cols(
                              GEOID_ZCTA = col_character(),
                              wht_pct = col_double(),
                              blk_pct = col_double()
                            )) 
    
    poverty <- readr::read_csv("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/demographics/STL_ZCTA_Lincoln_County_Poverty.csv",
                               col_types = cols(
                                 GEOID_ZCTA = col_character(),
                                 pvty_pct = col_double()
                               )) 
  } else if (county == 219){
    race <- readr::read_csv("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/demographics/STL_ZCTA_Warren_County_Race.csv",
                            col_types = cols(
                              GEOID_ZCTA = col_character(),
                              wht_pct = col_double(),
                              blk_pct = col_double()
                            )) 
    
    poverty <- readr::read_csv("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/demographics/STL_ZCTA_Warren_County_Poverty.csv",
                               col_types = cols(
                                 GEOID_ZCTA = col_character(),
                                 pvty_pct = col_double()
                               )) 
  } else if (county == "city-county"){
    race <- readr::read_csv("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/demographics/STL_ZCTA_City_County_Race.csv",
                            col_types = cols(
                              GEOID_ZCTA = col_character(),
                              wht_pct = col_double(),
                              blk_pct = col_double()
                            )) 
    
    poverty <- readr::read_csv("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/demographics/STL_ZCTA_City_County_Poverty.csv",
                               col_types = cols(
                                 GEOID_ZCTA = col_character(),
                                 pvty_pct = col_double()
                               )) 
  } else if (county == "regional"){
    race <- readr::read_csv("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/demographics/STL_ZCTA_Metro_West_Race.csv",
                            col_types = cols(
                              GEOID_ZCTA = col_character(),
                              wht_pct = col_double(),
                              blk_pct = col_double()
                            )) 
    
    poverty <- readr::read_csv("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/demographics/STL_ZCTA_Metro_West_Poverty.csv",
                               col_types = cols(
                                 GEOID_ZCTA = col_character(),
                                 pvty_pct = col_double()
                               )) 
  }
  
  # join
  out <- dplyr::left_join(race, poverty, by = "GEOID_ZCTA")
  
  # return output
  return(out)
  
}

