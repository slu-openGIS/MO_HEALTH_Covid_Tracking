#'
#' Function to scrape public Tableau Dashboards
#' 

get_tableau <- function(host, views, n, getWS = FALSE){
  
  if(stringr::str_detect(host, "^https://") == FALSE) {
    host_url <- paste0("https://", host)
  } else {
    host_url <- host
  }
  path <- views
  
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
  
  if(getWS == TRUE){
    for(i in 1:length(worksheets)){
      print(paste("[",i,"] ",worksheets[i], sep=""))
    }
    return()
  }
  selected <- n;
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
  return(df)
}