get_esri <- function(path){
  
  # scrape
  data <- httr::GET(path) 
  
  # extract
  data <- httr::content(data) 
  data <- jsonlite::fromJSON(data)

  out <- data[["features"]][["attributes"]]
  
  # return output
  return(out)
  
}