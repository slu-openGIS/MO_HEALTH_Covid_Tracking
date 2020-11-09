get_state <- function(state, metric){
  
  # call subfunctions
  if (state == 29){
    if (metric == "deaths, actual"){
      out <- get_mo_deaths()
    }
  }
  
  # return output
  return(out)
  
}


get_mo_deaths <- function(){
  
  ## download data
  out <- readr::read_csv("https://results.mo.gov/t/COVID19/views/COVID-19DataforDownload/MetricsbyDateofDeath.csv",
                         col_types = cols(`Date of Death` = col_character()))
  
  ## tidy
  ### initial processing
  out <- dplyr::rename(out,
    date = Dod,
    value = `Measure Names`,
    count = `Measure Values`
  )
  
  out <- dplyr::select(out, date, value, count)
  
  out <- dplyr::filter(out, is.na(date) == FALSE)
  out <- dplyr::filter(out, date != "All")
  
  out <- dplyr::mutate(out, date = lubridate::mdy(date))
  
  ### pad first week with 0 deaths
  first_date <- dplyr::select(out, date)
  first_date <- dplyr::slice(first_date, 1)
  first_date <- dplyr::pull(first_date)
  
  extra_dates <- dplyr::as_tibble(seq(first_date-6, first_date-1, by="days"))
  extra_dates <- dplyr::rename(extra_dates, date = value)
  extra_dates <- dplyr::mutate(extra_dates, value = "Total Deaths")
  extra_dates <- dplyr::mutate(extra_dates, count = 0)
  
  ### combine data
  out <- dplyr::bind_rows(extra_dates, out)
  
  ### finish tidying
  out <- dplyr::mutate(out, value = "Deaths, Actual")
  
  out <- dplyr::mutate(out, avg = rollmean(count, k = 7, align = "right", fill = NA))
  
  out <- dplyr::filter(out, date >= first_date)
  
  ## return output
  return(out)
  
}