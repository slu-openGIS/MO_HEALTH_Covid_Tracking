get_cases <- function(state, metric){
  
  if (state == "MO"){
    
    if (metric == "totals"){
      out <- get_case_totals()
    }
    
  }
  
  # return output
  return(out)
  
}

get_case_totals <- function(){
  
  # scrape cumulative cases in Missouri
  total_cases <- get_state_data_scrape(20)
  total_deaths <- get_state_data_scrape(23)
  
  # tidy
  out <- dplyr::bind_cols(total_cases, total_deaths)
  out <- dplyr::rename(out,
                       total_cases = `SUM(* Positive Cases)-alias`, 
                       cases_per_100k = `AGG(* Positive Cases per 100k)-alias`, 
                       total_deaths = `SUM(* Deaths Flag)-alias`) 
  
  out <- dplyr::mutate(out,
                       total_cases = as.numeric(total_cases), 
                       cases_per_100k = as.numeric(cases_per_100k), 
                       total_deaths = as.numeric(total_deaths))
  
  # return output
  return(out)
  
}


#'
#' This function outputs several worksheets and data directly from the "Statewide" tab
#' Source: https://showmestrong.mo.gov/data/public-health/
#' 
#' The code scrapes several "worksheets" directly the website from the given list below:
#' 
# [1] "[1] (R) % Change in Cases"
# [1] "[2] (R) % Change in Deaths"
# [1] "[3] (R) % Change in Positivity"
# [1] "[4] (R) % Change in Tests"
# [1] "[5] (R) New Tests"
# [1] "[6] (R) New Tests per 100K"
# [1] "[7] (R) Past 7 New Cases"
# [1] "[8] (R) Past 7 New Cases per 100K"
# [1] "[9] (R) Past 7 New Deaths"
# [1] "[10] (R) Past 7 New Deaths per 100K"
# [1] "[11] (S) % Change in Cases"
# [1] "[12] (S) % Change in Deaths"
# [1] "[13] (S) % Change in Pos Rate"
# [1] "[14] (S) % Change in Tests"
# [1] "[15] (S) Cases Past 7 BAN"
# [1] "[16] (S) Deaths Past 7 BAN"
# [1] "[17] (S) New Tests"
# [1] "[18] (S) Test Test Positivity Rate"
# [1] "[19] (S) Turnaround Time"
# [1] "[20] BAN - Total Cases"
# [1] "[21] BAN - Total Cases (Past 7)"
# [1] "[22] BAN - Total Cases (Past 7) - Daily (Horiz)"
# [1] "[23] BAN - Total Deaths"
# [1] "[24] BAN - Total Deaths (Past 7)"
# [1] "[25] BAN - Total Deaths (Past 7) - Daily (Horz)"
# [1] "[26] BAN - Total Tests"
# [1] "[27] BAN - Total Tests (Past 7)"
# [1] "[28] BAN - Total Tests (Past 7) - Daily - Horz"
# [1] "[29] Cases in MO (Over Time) Moving 7 - Gray 5"
# [1] "[30] Cumulative (Metric) Map (Only Filled)"
# [1] "[31] Cumulative (Metric) by County"
# [1] "[32] Data Note"
# [1] "[33] Deaths in MO (Over Time) - Moving 7"
# [1] "[34] Metric Selector"
# [1] "[35] Past 7 Days (Metric) by County"
# [1] "[36] Past 7 Days - Metric Map (Only Filled)"
# [1] "[37] Testing in MO (Over Time) Moving 7 - Gray 5"
# [1] "[38] Volume or 100k Selector"
#'
get_state_data_scrape <- function(n){
  
  host_url <- "https://results.mo.gov/t/COVID19"
  path <- "/t/COVID19/views/StatewideDashboards-MOBILETEST/COVID-19inMissouriPhone"
  
  body <- xml2::read_html(httr::modify_url(host_url, 
                                           path = path, 
                                           query = list(":embed" = "y",":showVizHome" = "no")
  ))
  
  #
  data <- rvest::html_nodes(body, "textarea#tsConfigContainer")
  data <- rvest::html_text(data)
  
  # data <- body %>% 
  #  rvest::html_nodes("textarea#tsConfigContainer") %>% 
  #  rvest::html_text()
  
  json <- rjson::fromJSON(data)
  
  url <- httr::modify_url(host_url, path = paste(json$vizql_root, "/bootstrapSession/sessions/", json$sessionid, sep =""))
  
  resp <- httr::POST(url, body = list(sheet_id = json$sheetId), encode = "form")
  data <- httr::content(resp, "text")
  
  extract <- stringr::str_match(data, "\\d+;(\\{.*\\})\\d+;(\\{.*\\})")
  info <- rjson::fromJSON(extract[1,1])
  data <- rjson::fromJSON(extract[1,3])
  
  worksheets = names(data$secondaryInfo$presModelMap$vizData$presModelHolder$genPresModelMapPresModel$presModelMap)
  
  selected <-  n;
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
  df <- dplyr::as_tibble(df, stringsAsFactors = FALSE)
  
}

