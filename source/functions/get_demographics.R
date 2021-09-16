get_demographics <- function(state, county, metric){
  
  if (state == "MO"){
    
    if (is.null(county) == TRUE){
      out <- get_state_demos(metric = metric)
    } else if (county == "St. Louis City"){
      out <- get_city_demos(metric = metric)
    } else if (county == "St. Louis County"){
      out <- get_county_demos(metric = metric)
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

get_county_demos <- function(metric){
  
  load("data/source/paths.rda")
  
  if (metric == "race"){
    
    # scrape
    morbidity <- get_esri(path = paths$st_louis_county_demos)
    mortality <- get_esri(path = paths$st_louis_county_deaths)
    
    # tidy
    ## construct output table
    out <- dplyr::tibble(
      geoid = "29189",
      county = "St. Louis",
      value = c("Asian", "Black", "Two or More", "White")
    )
    
    ## tidy case data
    morbidity <- dplyr::select(morbidity, white_cases, black_or_african_american_cases,
                               asian_cases, two_or_more_races_cases)
    morbidity <- tidyr::pivot_longer(morbidity,
                                     cols = c(white_cases, black_or_african_american_cases,
                                              asian_cases, two_or_more_races_cases),
                                     names_to = "value", values_to = "cases")
    morbidity <- dplyr::mutate(morbidity, value = dplyr::case_when(
      value == "white_cases" ~ "White",
      value == "black_or_african_american_cases" ~ "Black",
      value == "asian_cases" ~ "Asian",
      value == "two_or_more_races_cases" ~ "Two or More"))
    out <- dplyr::left_join(out, morbidity, by = "value")
    
    ## tidy mortality data
    mortality <- dplyr::select(mortality, white_deaths, black_or_african_american_deaths)
    mortality <- tidyr::pivot_longer(mortality,
                                     cols = c(white_deaths, black_or_african_american_deaths),
                                     names_to = "value", values_to = "deaths")
    mortality <- dplyr::mutate(mortality, value = dplyr::case_when(
      value == "white_deaths" ~ "White",
      value == "black_or_african_american_death" ~ "Black"
    ))
    
    ## create output
    out <- dplyr::left_join(out, mortality, by = "value")
    
  } else if (metric == "ethnicity"){
    
    # scrape
    morbidity <- get_esri(path = paths$st_louis_county_demos)
    
    # construct output table
    out <- dplyr::tibble(
      geoid = "29189",
      county = "St. Louis",
      value = "Latino",
      cases = morbidity$hispanic_or_latino_cases[1]
    )
    
  }
  
  # return output
  return(out)
  
}

get_state_demos <- function(metric){
  
  if (metric == "race"){
    out <- get_state_race()
  }
  
  # return output
  return(out)
  
}

get_state_race <- function(){
  
  # scrape cases by ethnicity
  ethnic_c <- get_state_demos_scrape(6)
  ethnic_c <- dplyr::mutate(ethnic_c, ethnicity = dplyr::case_when(
    ethnicity == "HISPANIC" ~ "Latino",
    ethnicity == "UNKNOWN" ~ "Unknown Ethnicity"
  ))
  ethnic_c <- dplyr::filter(ethnic_c,  is.na(ethnicity) == FALSE)
  ethnic_c <- dplyr::rename(ethnic_c, value = ethnicity, cases_prop = percentage)
  
  # scrape cases by race
  race_c <- suppressWarnings(get_state_demos_scrape(7))
  race_c <- dplyr::mutate(race_c, race = dplyr::case_when(
    race == "WHITE" ~ "White",
    race == "BLACK OR AFRICAN AMERICAN" ~ "Black",
    race == "AMERICAN INDIAN_ALASKAN NATIVE" ~ "Native",
    race == "ASIAN" ~ "Asian",
    race == "NAT HAWAIIAN_PACIFIC ISLANDER" ~ "Pacific Islander",
    race == "MORE THAN ONE RACE" ~ "Two or More",
    race == "UNKNOWN" ~ "Unknown Race"
  ))
  race_c <- dplyr::filter(race_c,  is.na(race) == FALSE)
  race_c <- dplyr::rename(race_c, value = race, cases_prop = percentage)
  
  # bind
  out <- dplyr::bind_rows(race_c, ethnic_c)
  
  # scrape deaths by ethnicity
  ethnic_d <- get_state_demos_scrape(4)
  ethnic_d <- dplyr::mutate(ethnic_d, ethnicity = dplyr::case_when(
    ethnicity == "HISPANIC" ~ "Latino",
    ethnicity == "UNKNOWN" ~ "Unknown Ethnicity"
  ))
  ethnic_d <- dplyr::filter(ethnic_d,  is.na(ethnicity) == FALSE)
  ethnic_d <- dplyr::rename(ethnic_d, value = ethnicity, deaths_prop = percentage)
  
  # scrape deaths by race
  race_d <- suppressWarnings(get_state_demos_scrape(5))
  race_d <- dplyr::mutate(race_d, race = dplyr::case_when(
    race == "WHITE" ~ "White",
    race == "BLACK OR AFRICAN AMERICAN" ~ "Black",
    race == "AMERICAN INDIAN_ALASKAN NATIVE" ~ "Native",
    race == "ASIAN" ~ "Asian",
    race == "NAT HAWAIIAN_PACIFIC ISLANDER" ~ "Pacific Islander",
    race == "MORE THAN ONE RACE" ~ "Two or More",
    race == "UNKNOWN" ~ "Unknown Race"
  ))
  race_d <- dplyr::filter(race_d, is.na(race) == FALSE)
  race_d <- dplyr::rename(race_d, value = race, deaths_prop = percentage)
  
  # bind
  deaths <- dplyr::bind_rows(race_d, ethnic_d)
  
  # join
  out <- dplyr::left_join(out, deaths, by = "value")
  
  # clean-up
  out <- dplyr::mutate(out, state = "Missouri", .before = "value")
  
  # return
  return(out)
  
}

#'
#' This function outputs the "demographics" tab from https://showmestrong.mo.gov/public-healthcare-demographics/ site.
#' It is an extremely long code so it will take a bit to run at first.
#' 
#' The code scrapes several "worksheets" directly the website from the given list below:
#' 
#' "[1] + PCR by age" (this is actually Case by age)
#' "[2] County map"
#' "[3] Death by age"
#' "[4] Death ethnicity"
#' "[5] Death race"
#' "[6] PCR+ ethnicity" (Case by ethnicity)
#' "[7] PCR+ race" (Case by race)
#' "[8] Testing Report Update Date"
#' "[9] test date by age"
#' 
#' To use the get_demo() function, the only argument is `n` which is the index pointing to the worksheet above.
#' For example, to access the cases by ethnicity, do get_demo(6)
#' 
#' Reference:
#' case by age -> 1
#' death by age -> 3
#' 
#' case by race -> 7
#' death by race -> 5
#' 
#' case by ethnicity -> 6
#' death by ethnicity -> 4
#' 
get_state_demos_scrape <- function(n){
  
  host_url <- "https://results.mo.gov"
  path <- "/t/COVID19/views/COVID-19PublicDashboards/Demographics"
  
  body <- xml2::read_html(httr::modify_url(host_url, 
                                           path = path, 
                                           query = list(":embed" = "y",":showVizHome" = "no")
  ))
  
  data <- rvest::html_nodes(body, "textarea#tsConfigContainer")
  data <- rvest::html_text(data)
  json <- rjson::fromJSON(data)
  
  url <- httr::modify_url(host_url, path = paste(json$vizql_root, "/bootstrapSession/sessions/", json$sessionid, sep =""))
  
  resp <- httr::POST(url, body = list(sheet_id = json$sheetId), encode = "form")
  data <- httr::content(resp, "text")
  
  extract <- stringr::str_match(data, "\\d+;(\\{.*\\})\\d+;(\\{.*\\})")
  info <- rjson::fromJSON(extract[1,1])
  data <- rjson::fromJSON(extract[1,3])
  
  worksheets = names(data$secondaryInfo$presModelMap$vizData$presModelHolder$genPresModelMapPresModel$presModelMap)
  
  selected <- n
  worksheet <- worksheets[as.integer(selected)]
  
  columnsData <- data$secondaryInfo$presModelMap$vizData$presModelHolder$genPresModelMapPresModel$presModelMap[[worksheet]]$presModelHolder$genVizDataPresModel$paneColumnsData
  
  i <- 1
  result <- list();
  for(t in columnsData$vizDataColumns){
    if (is.null(t[["fieldCaption"]]) == FALSE) {
      paneIndex <- t$paneIndices
      columnIndex <- t$columnIndices
      if (length(t$paneIndices) > 1){
        paneIndex <- t$paneIndices[1]
      }
      if (length(t$columnIndices) > 1){
        columnIndex <- t$columnIndices[1]
      }
      result[[i]] <- list(
        fieldCaption = t[["fieldCaption"]], 
        valueIndices = columnsData$paneColumnsList[[paneIndex + 1]]$vizPaneColumns[[columnIndex + 1]]$valueIndices,
        aliasIndices = columnsData$paneColumnsList[[paneIndex + 1]]$vizPaneColumns[[columnIndex + 1]]$aliasIndices, 
        dataType = t[["dataType"]],
        stringsAsFactors = FALSE
      )
      i <- i + 1
    }
  }
  dataFull = data$secondaryInfo$presModelMap$dataDictionary$presModelHolder$genDataDictionaryPresModel$dataSegments[["0"]]$dataColumns
  
  cstring <- list();
  for(t in dataFull) {
    if(t$dataType == "cstring"){
      cstring <- t
      break
    }
  }
  data_index <- 1
  name_index <- 1
  frameData <-  list()
  frameNames <- c()
  for(t in dataFull) {
    for(index in result) {
      if (t$dataType == index["dataType"]){
        if (length(index$valueIndices) > 0) {
          j <- 1
          vector <- character(length(index$valueIndices))
          for (it in index$valueIndices){
            vector[j] <- t$dataValues[it+1]
            j <- j + 1
          }
          frameData[[data_index]] <- vector
          frameNames[[name_index]] <- paste(index$fieldCaption, "value", sep="-")
          data_index <- data_index + 1
          name_index <- name_index + 1
        }
        if (length(index$aliasIndices) > 0) {
          j <- 1
          vector <- character(length(index$aliasIndices))
          for (it in index$aliasIndices){
            if (it >= 0){
              vector[j] <- t$dataValues[it+1]
            } else {
              vector[j] <- cstring$dataValues[abs(it)]
            }
            j <- j + 1
          }
          frameData[[data_index]] <- vector
          frameNames[[name_index]] <- paste(index$fieldCaption, "alias", sep="-")
          data_index <- data_index + 1
          name_index <- name_index + 1
        }
      }
    }
  }
  
  df <- NULL
  lengthList <- c()
  for(i in 1:length(frameNames)){
    lengthList[i] <- length(frameData[[i]])
  }
  max <- max(lengthList)
  for(i in 1:length(frameNames)){
    if (length(frameData[[i]]) < max){
      len <- length(frameData[[i]])
      frameData[[i]][(len+1):max]<-""
    }
    df[frameNames[[i]]] <- frameData[i]
  }
  options(width = 1200)
  df <- as_tibble(df, stringsAsFactors = FALSE)
  
  if(selected ==  1){
    df <- df %>%
      select(`age (group)-value`, `SUM(Positive case PCR)-value`) %>% 
      transform(`SUM(Positive case PCR)-value` = as.numeric(`SUM(Positive case PCR)-value`)) %>% 
      rename(age_group = age..group..value, total = SUM.Positive.case.PCR..value)}
  else if(as.integer(selected) == 3){
    df <- df %>%
      select(`age (group)-value`, `SUM(* Deaths Flag)-value`) %>% 
      transform(`SUM(* Deaths Flag)-value` = as.numeric(`SUM(* Deaths Flag)-value`)) %>% 
      rename(age_group = age..group..value, total = SUM...Deaths.Flag..value)}
  else if(as.integer(selected) == 7){
    
    df <- df %>%
      rename(race = `Race-alias`, percentage = `AGG(SUM([* Positive PCR Cases]) / TOTAL(SUM([* Positive PCR Cases])))-alias`) %>%
      select(race, percentage) %>% 
      mutate(percentage = as.numeric(percentage))
    
  } else if(as.integer(selected) == 5){
    
    df <- df %>%
      rename(race = `Race-alias`, percentage = `AGG(SUM([* PCR Deaths]) / TOTAL(SUM([* PCR Deaths])))-alias`) %>%
      select(race, percentage) %>% 
      mutate(percentage = as.numeric(percentage))
    
  } else if(as.integer(selected) == 6){
    
    df <- df %>%
      rename(ethnicity = `Ethnicity-alias`, percentage = `AGG(SUM([* Positive PCR Cases]) / TOTAL(SUM([* Positive PCR Cases])))-alias`) %>%
      select(ethnicity, percentage) %>% 
      mutate(percentage = as.numeric(percentage))
      
    
  } else if(as.integer(selected) == 4){
    
    df <- df %>%
      rename(ethnicity = `Ethnicity-alias`, percentage = `AGG(SUM([* PCR Deaths]) / TOTAL(SUM([* PCR Deaths])))-alias`) %>%
      select(ethnicity, percentage) %>% 
      mutate(percentage = as.numeric(percentage))
    
  }
  
  
  return(df)
}

