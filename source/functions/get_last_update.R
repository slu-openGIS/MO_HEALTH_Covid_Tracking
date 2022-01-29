get_last_update <- function(source){
  
  if (source == "New York Times"){
   
    ## for county-level case and mortality data
    ## parse last update date/time stamp
    x <- httr::GET(url = "https://api.github.com/repos/nytimes/covid-19-data/commits/master")
    y <- x$headers$`last-modified`
    y <- stringr::word(y, 2, -2)
    z <- lubridate::dmy_hms(y)
    z <- as.POSIXlt(z, tz = "EST")
    
    ## parse current time date/time stamp
    current_time <- Sys.time()
    
    ## calculated elapsed time
    delta <- as.numeric(difftime(current_time, z, units = "hours"))
    
    ## prompt
    q <- usethis::ui_yeah(paste0("The New York Times data were last updated ", round(delta, digits = 2), " hours ago. Proceed?"))
    
    ## return output
    return(q)
     
  } else if (source == "CMS"){
    
    ## CMS LTC data
    ## return api last update value
    x <- rjson::fromJSON(file = "https://data.cms.gov/api/views/metadata/v1/s2uc-8wxp")
    x <- as.Date(x$dataUpdatedAt)
    
    ## return output
    return(x)
    
  } else if (source == "HHS"){
    
    ## HHS hospitalization data
    ## return api last update value
    x <- rjson::fromJSON(file = "https://beta.healthdata.gov/api/views/metadata/v1/anag-cw7u")
    x <- as.Date(x$updatedAt)
    
    ## return output
    return(x)
    
  } else if (source == "HHS State"){
    
    ## HHS hospitalization data
    ## return api last update value
    x <- rjson::fromJSON(file = "https://beta.healthdata.gov/api/views/metadata/v1/g62h-syeh")
    x <- as.Date(x$updatedAt)
    
    ## return output
    return(x)
    
  }
  
}


