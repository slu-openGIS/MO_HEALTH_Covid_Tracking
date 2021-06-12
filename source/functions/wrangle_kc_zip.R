
process_kc_zip <- function(dates, reduce = TRUE){
  
  # load zip data
  out <- list(
    clay_data = purrr::map_df(unlist(dates$kc_dates), ~ wrangle_kc_zip(date = .x, county = "Clay")),
    # jackson_data = purrr::map_df(unlist(dates$kc_dates), ~ wrangle_kc_zip(date = .x, county = "Jackson")),
    johnson_data = purrr::map_df(unlist(dates$kc_dates), ~ wrangle_kc_zip(date = .x, county = "Johnson")),
    kc_data = purrr::map_df(unlist(dates$kc_dates), ~ wrangle_kc_zip(date = .x, county = "Kansas City")),
    platte_data = purrr::map_df(unlist(dates$kc_dates), ~ wrangle_kc_zip(date = .x, county = "Platte")),
    wyandotte_data = purrr::map_df(unlist(dates$wyandotte_dates), ~ wrangle_kc_zip(date = .x, county = "Wyandotte"))
  )
  
  if (reduce == TRUE){
   
    # reduce
    out <- purrr::reduce(out, .f = dplyr::bind_rows)
    
    out <- dplyr::mutate(out, zip = ifelse(zip == "64028", "64079", zip))
    out <- dplyr::mutate(out, zip = ifelse(zip == "66160", "66103", zip))
    
    out <- dplyr::arrange(out, zip, report_date) 
    out <- dplyr::group_by(out, zip, report_date)
    out <- dplyr::summarise(out,
                            region = dplyr::first(region),
                            state = dplyr::first(state),
                            cases = sum(cases))
    
    # tidy
    out <- dplyr::select(out, report_date, zip, region, state, cases)
    
  }
  
  # return output
  return(out)
  
}

wrangle_kc_zip <- function(date, county){
  
  # set state
  if (county %in% c("Clay", "Jackson", "Kansas City", "Platte")){
    state <- "Missouri"
  } else if (county %in% c("Johnson", "Wyandotte")){
    state <- "Kansas"
  }
  
  # load data
  if (county == "Clay"){
    file <- paste0("data/source/kc_daily_zips/clay_", date, ".csv")
  } else if (county == "Jackson"){
    file <- paste0("data/source/kc_daily_zips/jackson_", date, ".csv")
  } else if (county == "Johnson"){
    file <- paste0("data/source/kc_daily_zips/johnson_", date, ".csv")
  } else if (county == "Kansas City"){
    file <- paste0("data/source/kc_daily_zips/kansas_city_", date, ".csv")
  } else if (county == "Platte"){
    file <- paste0("data/source/kc_daily_zips/platte_", date, ".csv")
  } else if (county == "Wyandotte"){
    file <- paste0("data/source/kc_daily_zips/wyandotte_", date, ".csv")
  }
  
  # read data
  df <- readr::read_csv(file, col_types = cols(
    zip = col_double(),
    count = col_double()
  ))
  
  df <- dplyr::mutate(df,
                      report_date = date,
                      zip = as.character(zip),
                      region = "Kansas City Metro",
                      state = state)
  
  df <- dplyr::select(df, report_date, zip, region, state, count)
  df <- dplyr::rename(df, cases = count) 
  
  # return output
  return(df)
  
}
