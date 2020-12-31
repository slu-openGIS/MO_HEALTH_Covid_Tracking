get_demographics <- function(state, county, metric){
  
  if (state == "MO"){
    
    if (county == "St. Louis City"){
      out <- get_city_demos(metric = metric)
    }
    
  }
  
  # return output
  return(out)
  
}

get_city_demos <- function(metric){
  
  ## scrape
  out <- get_city_scrape(metric = metric)
  
  # tidy
  if (metric == "race"){
    
    out <- dplyr::mutate(out,
                         geoid = "29510",
                         county = "St. Louis City")
    out <- dplyr::select(out, geoid, county, Race, Cases, Deaths)
    out <- dplyr::rename(out,
                         value = Race,
                         cases = Cases,
                         deaths = Deaths)
    out <- dplyr::mutate(out,
                         value = dplyr::case_when(
                           value == "African American" ~ "Black",
                           value == "Black/AA" ~ "Black",
                           value == "Caucasian" ~ "White",
                           value == "NA/AI" ~ "Native",
                           value == "Multiple Races" ~ "Two or More",
                           TRUE ~ as.character(value)),
                         cases = as.numeric(ifelse(cases == "< 5" | cases == "0", NA, cases)),
                         deaths = as.numeric(ifelse(deaths == "< 5" | deaths == "0", NA, deaths)))
    out <- dplyr::filter(out, value %in% c("Asian", "Black", "Native", "Two or More", "White"))
    
  } else if (metric == "race by sex"){
    
    out <- dplyr::mutate(out,
                         geoid = "29510",
                         county = "St. Louis City")
    out <- dplyr::select(out, geoid, county, Race, Sex, Cases, Deaths)
    out <- dplyr::rename(out,
                         value = Race,
                         sex = Sex,
                         cases = Cases,
                         deaths = Deaths)
    out <- dplyr::mutate(out,
                         value = dplyr::case_when(
                           value == "African American" ~ "Black",
                           value == "Black/AA" ~ "Black",
                           value == "Caucasian" ~ "White",
                           value == "Multiple Races" ~ "Two or More",
                           TRUE ~ as.character(value)),
                         sex = ifelse(sex == "FEMALE", "Female", sex),
                         cases = as.numeric(ifelse(cases == "< 5", NA, cases)),
                         deaths = as.numeric(ifelse(deaths == "< 5", NA, deaths)))
    out <- dplyr::filter(out, value %in% c("Asian", "Black", "Two or More", "White"))
    out <- dplyr::filter(out, sex %in% c("Female", "Male"))
    
  } else if (metric == "ethnicity"){
    
    out <- dplyr::mutate(out,
                         geoid = "29510",
                         county = "St. Louis City")
    out <- dplyr::select(out, geoid, county, Ethnicity, Cases) # Deaths
    out <- dplyr::rename(out,
                         value = Ethnicity,
                         cases = Cases) # deaths = Deaths
    out <- dplyr::filter(out, value == "Hispanic")
    out <- dplyr::mutate(out, 
                         value = "Latino",
                         cases = as.numeric(cases))
    
  }
  
  # return output
  out <- dplyr::as_tibble(out)
  return(out)
  
}

get_city_scrape <- function(metric){
  
  # set value
  if (metric == "race"){
    val <- 4
  } else if (metric == "race by sex"){
    val <- 6
  } else if (metric == "race by age"){
    val <- 5
  } else if (metric == "age"){
    val <- 1
  } else if (metric == "ethnicity"){
    val <- 7
  }
  
  # scrape
  webpage <- xml2::read_html("https://www.stlouis-mo.gov/government/departments/health/communicable-disease/covid-19/data/demographics.cfm")
  
  # extract tables
  out <- rvest::html_nodes(webpage, "table")
  out <- out[[val]]
  out <- rvest::html_table(out, fill = TRUE)
  
  # return output
  return(out)
  
}