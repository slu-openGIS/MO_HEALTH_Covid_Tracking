get_last_update <- function(){
  
  x <- httr::GET(url = "https://api.github.com/repos/nytimes/covid-19-data/commits/master")
  y <- x$headers$`last-modified`
  y <- stringr::word(y, 2, -2)
  
  z <- lubridate::dmy_hms(y)
  z <- as.POSIXlt(z, tz = "EST")
  current_time <- Sys.time()
  delta <- as.numeric(difftime(current_time, z, units = "hours"))
  
  q <- usethis::ui_yeah(paste0("The New York Times data were last updated ", round(delta, digits = 2), " hours ago. Proceed?"))
  
  return(q)
  
}


