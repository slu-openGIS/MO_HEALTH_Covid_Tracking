get_zip <- function(state, county, method, cut = FALSE, paged = FALSE, val, file) {
  
  load("data/source/paths.rda")
  
  ## call sub-functions
  if (state == "MO"){
    
    if (county == "Clay"){
      out <- get_zip_clay(path = paths$clay)
    } else if (county == "Franklin"){
      out <- get_zip_franklin(file = file)
    } else if (county == "Jackson"){
      out <- get_zip_jackson()
    } else if (county == "Jefferson"){
      out <- get_zip_jefferson(path = paths$jefferson)
    } else if (county == "Kansas City"){
      out <- get_zip_kc()
    } else if (county == "Lincoln"){
      out <- get_zip_lincoln(path = paths$lincoln)
    } else if (county == "Platte"){
      out <- get_zip_platte(method = method)
    } else if (county == "St. Charles"){
      out <- get_zip_st_charles(cut = cut, val = val) 
    } else if (county == "St. Louis City"){
      out <- get_zip_st_louis_city(path = paths$st_louis_city)
    } else if (county == "St. Louis County"){
      out <- get_zip_st_louis_county(path = paths$st_louis_county_zip)
    } else if (county == "Warren"){
      out <- get_zip_warren()
    }
    
  } else if (state == "IL"){
    
    out <- get_zip_il(paged = paged)
    
  } else if (state == "KS"){
    
    if (county == "Johnson"){
      out <- get_zip_johnson(path = paths$johnson)
    } else if (county == "Wyandotte"){
      out <- get_zip_wyandotte(path = paths$wyandotte)
    }
    
  }
  
  ## return output
  return(out)
  
}

get_zip_clay <- function(path){
  
  ## scrape
  out <- get_esri(path = path)
  
  ## tidy
  out <- dplyr::select(out, f1, f9)
  out <- dplyr::rename(out, zip = f1, count = f9)
  out <- dplyr::filter(out, zip != 0)
  out <- dplyr::mutate(out, count = ifelse(count %in% c("<6", "0"), NA, count))
  out <- dplyr::mutate(out, count = as.numeric(count))
  out <- dplyr::filter(out, is.na(count) == FALSE)
  out <- dplyr::arrange(out, zip)
  
  ## return output
  return(out)
  
}

get_zip_franklin <- function(file){
  
  ## load reference data
  tbl <- sf::st_read("https://raw.githubusercontent.com/slu-openGIS/STL_BOUNDARY_ZCTA/master/data/geometries/STL_ZCTA_Franklin_County.geojson", 
                      crs = 4326, stringsAsFactors = FALSE)
  sf::st_geometry(tbl) <- NULL
  
}

get_zip_il <- function(paged = FALSE){
  
  # navigate to page and wait for it to load
  remDr$navigate("https://dph.illinois.gov/covid19/statistics")
  Sys.sleep(6)
  
  # the zip data used to be paginated but have not been since late January 2021
  if (paged == TRUE){
   
    # find and click the button leading to the Zip Code data
    remDr$findElement("#pagin > li:last-child > a", using = "css selector")$clickElement()
    Sys.sleep(3)
     
  }
  
  # fetch the site source in XML
  zipcode_data_table <- xml2::read_html(remDr$getPageSource()[[1]])
  zipcode_data_table <- selectr::querySelector(zipcode_data_table, "table.padded-table")
  
  ##############################################################
  
  # grab all Zip codes
  zipcodes <- selectr::querySelectorAll(zipcode_data_table, "#detailedData tbody tr td a")
  zipcodes <- purrr::map_chr(zipcodes, xml2::xml_text)
  
  # grab all total tests per Zip
  zip_tests <- selectr::querySelectorAll(zipcode_data_table, "#detailedData tbody tr:nth-child(n) td:nth-child(2)")
  zip_tests <- purrr::map_chr(zip_tests, xml2::xml_text)
  
  # grab all total cases per 
  zip_cases <- selectr::querySelectorAll(zipcode_data_table, "#detailedData tbody tr:nth-child(n) td:nth-child(3)")
  zip_cases <- purrr::map_chr(zip_cases, xml2::xml_text)
  
  # tidy
  zipcodes <- tidyr::as_tibble(zipcodes)
  zipcodes <- dplyr::mutate(zipcodes, value = as.numeric(value))
  zipcodes <- dplyr::rename(zipcodes, zip_code = "value")
  
  zip_tests <- tidyr::as_tibble(zip_tests)
  zip_tests <- dplyr::mutate(zip_tests, value = as.numeric(gsub(",", "", value)))
  zip_tests <- dplyr::rename(zip_tests, tested = "value")
  
  zip_cases <- tidyr::as_tibble(zip_cases)
  zip_cases <- dplyr::mutate(zip_cases, value = as.numeric(gsub(",", "", value)))
  zip_cases <- dplyr::rename(zip_cases, confirmed_cases = "value")
  
  # combine data
  out <- dplyr::bind_cols(zipcodes, zip_tests, zip_cases)
  
  # final tidy
  out <- dplyr::select(out, zip_code, confirmed_cases)
  out <- dplyr::rename(out,
                       zip = zip_code,
                       count = confirmed_cases
  )
  out <- dplyr::filter(out, is.na(zip) == FALSE)
  out <- dplyr::arrange(out, zip)
  
  # return output
  return(out)
  
} 

get_zip_jackson <- function(){
  
  # opening PowerBI dashboard
  remDr$navigate("https://app.powerbi.com/view?r=eyJrIjoiOWE4YjAwZDUtZDZiMy00M2M4LWI4ZTItY2QyOTgzMTMwYzY3IiwidCI6IjM2YTEwMDhmLWI2ZDgtNGZjOC1iNjBhLTU2ZDg3OGFlNmU4MyIsImMiOjR9")
  Sys.sleep(1)
  
  # clicking tab to take us to ZIP data
  remDr$findElement('//*[@id="pvExplorationHost"]/div/div/exploration/div/explore-canvas-modern/div/div[2]/div/div[2]/div[2]/visual-container-repeat/visual-container-group[1]/transform/div/div[2]/visual-container-modern[2]/transform/div/div[3]/div/visual-modern/div/button', using="xpath")$clickElement()
  Sys.sleep(3)
  
  # allowing mouse to center onto map, and activating the JS to display Zip code and cases
  remDr$mouseMoveToLocation(webElement = remDr$findElement('#labelCanvasId', using = "css selector"))
  Sys.sleep(1)
  remDr$findElement('//*[@id="pvExplorationHost"]/div/div/exploration/div/explore-canvas-modern/div/div[2]/div/div[2]/div[2]/visual-container-repeat/visual-container-group[1]/transform/div/div[2]/visual-container-modern[4]/transform/div/visual-container-header-modern/div/div[1]/div/visual-header-item-container/div/button', using="xpath")$clickElement()
  
  # having mouse center on map
  remDr$mouseMoveToLocation(webElement = remDr$findElement('#labelCanvasId', using = "css selector"))
  Sys.sleep(1)
  
  zip_list <- list()
  inc_list <- list()
  
  for(i in 1:26){
    
    # mouse hovers on area to display Zip code and cases
    area_element <- paste0("#pvExplorationHost > div > div > exploration > div > explore-canvas-modern > div > div.canvasFlexBox > div > div.displayArea.disableAnimations.fitToScreen > div.visualContainerHost > visual-container-repeat > visual-container-modern:nth-child(4) > transform > div > div:nth-child(4) > div > visual-modern > div > div > svg > g.mapShapes > path:nth-child(",i,")")
    
    #area_element <- "#pvExplorationHost > div > div > exploration > div > explore-canvas-modern > div > div.canvasFlexBox > div > div.displayArea.disableAnimations.fitToScreen > div.visualContainerHost > visual-container-repeat > visual-container-modern:nth-child(4) > transform > div > div:nth-child(4) > div > visual-modern > div > div > svg > g.mapShapes > path:nth-child(13)"
    area <- remDr$findElement(area_element, using = "css selector")
    remDr$mouseMoveToLocation(webElement = area)
    
    if(i == 13){
      remDr$mouseMoveToLocation(y = -10)
    }
    
    # getting Zip and cases
    zip_code <- remDr$findElement('/html/body/div[5]/visual-tooltip-modern/div/div/div/div/div[1]/div[2]/div', using = "xpath")$getElementText()[[1]]
    incidence <- remDr$findElement('/html/body/div[5]/visual-tooltip-modern/div/div/div/div/div[2]/div[2]/div', using = "xpath")$getElementText()[[1]]
    
    zip_list[[i]] <- zip_code
    inc_list[[i]] <- incidence
    
    Sys.sleep(1)
    
  }
  
  # output
  out <- do.call(rbind, Map(data.frame, zip=zip_list, incidence=inc_list))
  out <- dplyr::mutate(out, zip = as.numeric(zip_list),
                       incidence = as.numeric(inc_list))
  out <- dplyr::distinct(out)
  
  return(out)
  
}

get_zip_jefferson <- function(path){
  
  ## scrape
  out <- get_esri(path = path)
  
  # tidy
  out <- dplyr::select(out, ZIP, Active_Cas)
  out <- dplyr::rename(out, 
                       zip = ZIP,
                       count = Active_Cas)
  out <- dplyr::mutate(out, count = ifelse(count < 5, NA, count))
  out <- dplyr::arrange(out, zip)
  
  ## return output
  return(out)
  
}

get_zip_johnson <- function(path){
  
  ## scrape
  out <- get_esri(path = path)
  
  ## tidy
  out <- dplyr::select(out, Zip, Positives)
  out <- dplyr::rename(out, 
                       zip = Zip,
                       count = Positives)
  
  ## return output
  return(out)
}  

get_zip_kc <- function(){
  
  ## api call
  out <- readr::read_csv("https://data.kcmo.org/resource/374j-h7xt.csv",
                         col_types = readr::cols(
                           zipcode = readr::col_double(),
                           cases = readr::col_character(),
                           crude_rate_per_100_000 = readr::col_character(),
                           total_residents_tested = readr::col_double()
                         ))
  
  ## tidy
  out <- dplyr::select(out, zipcode, cases)
  out <- dplyr::rename(out,
                       zip = zipcode,
                       count = cases
  )
  out <- dplyr::mutate(out, count = ifelse(count == "SUPP*", NA, count))
  out <- dplyr::mutate(out, count = as.numeric(count))
  out <- dplyr::filter(out, is.na(count) == FALSE)
  out <- dplyr::arrange(out, zip)
  
  ## return output
  return(out)
  
}

get_zip_lincoln <- function(path){
  
  ## scrape
  out <- get_esri(path = path)
  
  ## tidy
  out <- dplyr::select(out, ZIP_CODE, COVID_Exce)
  out <- dplyr::rename(out,
                       zip = ZIP_CODE,
                       count = COVID_Exce
  )
  out <- dplyr::mutate(out, count = ifelse(count < 10, NA, count))
  out <- dplyr::filter(out, is.na(count) == FALSE)
  out <- dplyr::arrange(out, zip)
  
  ## return output
  return(out)
  
}

get_zip_platte <- function(method){
  
  if (method == "power bi"){
    
    out <- get_zip_platte_bi()
    
  } else if (method == "html"){
    
    out <- get_zip_platte_html()
    
  } else if (method == "mixed"){
    
    # initial scraping
    bi <- get_zip_platte_bi()
    html <- get_zip_platte_html()
    
    # subset html
    bi <- dplyr::filter(bi, is.na(count) == FALSE)
    html <- dplyr::filter(html, zip %in% bi$zip == FALSE)
    
    # combine
    out <- dplyr::bind_rows(bi, html)
    out <- dplyr::arrange(out, zip)
    
  }
  
  ## return output
  return(out)
  
}

get_zip_platte_bi <- function(){
  
  # navigate to dashboard URL
  remDr$navigate("https://app.powerbi.com/view?r=eyJrIjoiODRhZjQ5MTEtNTJhNi00NjczLTlmMGYtYmYyNjVkZTEwMzg0IiwidCI6Ijk1Njc2ZGE2LTJlMzYtNGFkNi1hNThlLTUyNzg0NmI3M2M5MyJ9")
  Sys.sleep(4)
  
  # obtaining HTML page source
  zipcode_data_table <- xml2::read_html(remDr$getPageSource()[[1]])
  
  # looping through ZCTA and cases from bar graph
  zcta_list <- list()
  zip_list <- list()
  for(i in 1:12){
    
    if(i <= 9){
      # getting ZCTA
      zcta_path <- paste0('#pvExplorationHost > div > div > exploration > div > explore-canvas-modern > div > div.canvasFlexBox > div > div.displayArea.disableAnimations.fitToPage > div.visualContainerHost > visual-container-repeat > visual-container-modern:nth-child(6) > transform > div > div:nth-child(3) > div > visual-modern > div > svg.cartesianChart > svg > g.axisGraphicsContext.columnChart > g.y.axis.hideLinesOnAxis.setFocusRing > g:nth-child(',i+1,') > text > title')
      zcta <- selectr::querySelectorAll(zipcode_data_table, zcta_path)
      zcta <- purrr::map_chr(zcta, xml2::xml_text)
      zcta_list[[i]] <- zcta
      
      # getting cases
      bar_element <- paste0('#pvExplorationHost > div > div > exploration > div > explore-canvas-modern > div > div.canvasFlexBox > div > div.displayArea.disableAnimations.fitToPage > div.visualContainerHost > visual-container-repeat > visual-container-modern:nth-child(6) > transform > div > div:nth-child(3) > div > visual-modern > div > svg.cartesianChart > svg > g.axisGraphicsContext.columnChart > g.columnChartUnclippedGraphicsContext > svg > g > rect:nth-child(',i,')')
      bar <- remDr$findElement(bar_element, using = "css selector")
      remDr$mouseMoveToLocation(webElement = bar)
      Sys.sleep(0.5)
      zip_data <- remDr$findElement('/html/body/div[4]/visual-tooltip-modern/div/div/div/div/div[2]/div[2]/div', using = "xpath")$getElementText()[[1]]
      zip_list[[i]] <- zip_data
    }
    
    if(i == 9){
      # scrolling down the zip list
      scrollbar_element <- "#pvExplorationHost > div > div > exploration > div > explore-canvas-modern > div > div.canvasFlexBox > div > div.displayArea.disableAnimations.fitToPage > div.visualContainerHost > visual-container-repeat > visual-container-modern:nth-child(6) > transform > div > div:nth-child(3) > div > visual-modern > div > svg.cartesianChart > g.brush.responsive > rect.selection"
      scrollbar <- remDr$findElement(scrollbar_element, using = "css selector")
      remDr$mouseMoveToLocation(webElement = scrollbar)
      remDr$buttondown()
      
      scrolldown_element <- "#pvExplorationHost > div > div > exploration > div > explore-canvas-modern > div > div.canvasFlexBox > div > div.displayArea.disableAnimations.fitToPage > div.visualContainerHost > visual-container-repeat > visual-container-modern:nth-child(15) > transform > div > div:nth-child(3) > div > visual-modern > div > svg.cartesianChart > svg > g.axisGraphicsContext.columnChart > g.columnChartUnclippedGraphicsContext > svg > g > rect:nth-child(9)"
      scrolldown <- remDr$findElement(scrolldown_element, using = "css selector")
      remDr$mouseMoveToLocation(webElement = scrolldown)
      remDr$buttonup()
      
      # re-reading page source
      zipcode_data_table <- xml2::read_html(remDr$getPageSource()[[1]])
      Sys.sleep(0.5)
    }
    
    if(i > 9){
      
      # getting ZCTA
      zcta_path <- paste0('#pvExplorationHost > div > div > exploration > div > explore-canvas-modern > div > div.canvasFlexBox > div > div.displayArea.disableAnimations.fitToPage > div.visualContainerHost > visual-container-repeat > visual-container-modern:nth-child(6) > transform > div > div:nth-child(3) > div > visual-modern > div > svg.cartesianChart > svg > g.axisGraphicsContext.columnChart > g.y.axis.hideLinesOnAxis.setFocusRing > g:nth-child(',i-2,') > text > title')
      zcta <- selectr::querySelectorAll(zipcode_data_table, zcta_path)
      zcta <- purrr::map_chr(zcta, xml2::xml_text)
      zcta_list[[i]] <- zcta
      
      # getting cases
      bar_element <- paste0('#pvExplorationHost > div > div > exploration > div > explore-canvas-modern > div > div.canvasFlexBox > div > div.displayArea.disableAnimations.fitToPage > div.visualContainerHost > visual-container-repeat > visual-container-modern:nth-child(6) > transform > div > div:nth-child(3) > div > visual-modern > div > svg.cartesianChart > svg > g.axisGraphicsContext.columnChart > g.columnChartUnclippedGraphicsContext > svg > g > rect:nth-child(',i-3,')')
      bar <- remDr$findElement(bar_element, using = "css selector")
      remDr$mouseMoveToLocation(webElement = bar)
      Sys.sleep(0.5)
      zip_data <- remDr$findElement('/html/body/div[4]/visual-tooltip-modern/div/div/div/div/div[2]/div[2]/div', using = "xpath")$getElementText()[[1]]
      zip_list[[i]] <- zip_data
    }
  }
  
  # output
  out <- do.call(rbind, Map(data.frame, zip=zcta_list, count=zip_list))
  out <- dplyr::mutate(out, count = as.numeric(count))
  out <- dplyr::mutate(out, count = ifelse(zip == "64028", NA, count))
  out <- dplyr::arrange(out, zip)
  
  ## return output
  return(out)
  
}
  
get_zip_platte_html <- function(){
  
  # scrape
  webpage <- xml2::read_html("https://www.plattecountyhealthdept.com/emergency.aspx")
  
  # extract tables
  out <- rvest::html_nodes(webpage, "table")
  table <- out[[3]]
  table <- rvest::html_table(table, fill = TRUE)
  
  # tidy table
  out <- dplyr::select(table, X1, X4)
  out <- dplyr::rename(out, zip = X1, count = X4)
  
  n <- as.numeric(nrow(out))
  n <- n-1
  
  out <- dplyr::slice(out, 2:n)
  
  testthat::expect_equal(nrow(out), 19)
  
  out <- dplyr::mutate(out, count = ifelse(count == "Suppressed", NA, count))
  out <- dplyr::mutate(out, count = as.numeric(count))
  out <- dplyr::mutate(out, count = ifelse(count < 5, NA, count))
  out <- dplyr::filter(out, is.na(count) == FALSE)
  
  ## return output
  return(out)
  
}

get_zip_st_charles <- function(cut = FALSE, val){
  
  # navigate to the site you wish to analyze
  remDr$navigate("https://app.powerbigov.us/view?r=eyJrIjoiZDFmN2ViMGEtNzQzMC00ZDU3LTkwZjUtOWU1N2RiZmJlOTYyIiwidCI6IjNiMTg1MTYzLTZjYTMtNDA2NS04NDAwLWNhNzJiM2Y3OWU2ZCJ9&pageName=ReportSectionb438b98829599a9276e2&pageName=ReportSectionb438b98829599a9276e2")
  Sys.sleep(4)
  
  # find and click the button leading to the Zip Code data
  remDr$findElement('.//button[descendant::span[text()="Zip Code"]]', using="xpath")$clickElement()
  Sys.sleep(4)
  
  # fetch the site source in XML
  zipcode_data_table <- xml2::read_html(remDr$getPageSource()[[1]])
  zipcode_data_table <- selectr::querySelector(zipcode_data_table, "div.pivotTable")
  
  # get zip codes
  zipcodes <- selectr::querySelectorAll(zipcode_data_table, "div.rowHeaders div.pivotTableCellWrap")
  zipcodes <- purrr::map_chr(zipcodes, xml2::xml_text)
  
  # put into tibble
  zipcodes <- tidyr::as_tibble(zipcodes)
  zipcodes <- dplyr::rename(zipcodes, zip_code = value) 
  
  # changing data type chr -> num
  zipcodes <- dplyr::mutate(zipcodes, zip_code = as.numeric(zip_code))
  
  zipcode_data <- zipcode_data_table %>%
    selectr::querySelectorAll("div.bodyCells div.pivotTableCellWrap") %>%
    purrr::map(xml2::xml_parent) %>%
    unique() %>%
    purrr::map(~ .x %>%
                 selectr::querySelectorAll("div.pivotTableCellWrap") %>% 
                 purrr::map_chr(xml2::xml_text)
    )
  
  # renaming columns, removing percent sign, and chaging data type from chr -> num
  zipcode_data <- suppressMessages(dplyr::bind_cols(zipcode_data))
  zipcode_data <- dplyr::rename(zipcode_data, 
                                cases = `...1`, 
                                percent_cases = `...2`,
                                deaths = `...3`,
                                percent_deaths = `...4`)
  zipcode_data <- dplyr::mutate(zipcode_data, cases = stringr::str_replace(cases, pattern = "[,]", replacement = "")) 
  zipcode_data <- dplyr::mutate(zipcode_data, percent_cases = stringr::str_extract(percent_cases, "^[0-9.]*"))
  zipcode_data <- dplyr::mutate(zipcode_data, percent_deaths = stringr::str_extract(percent_deaths, "^[0-9.]*")) 
  zipcode_data <- dplyr::mutate(zipcode_data, cases = as.numeric(cases),
                                percent_cases = as.numeric(percent_cases),
                                deaths = as.numeric(deaths),
                                percent_deaths = as.numeric(percent_deaths))
  
  # fix display issues
  if (cut == TRUE){
    zipcode_data <- filter(zipcode_data, cases != val)
  }
  
  # combine data
  out <- dplyr::bind_cols(zipcodes, zipcode_data)
  out <- dplyr::arrange(out, zip_code)
  
  # final tidy
  out <- dplyr::select(out, zip_code, cases)
  out <- dplyr::rename(out,
    zip = zip_code,
    count = cases
  )
  out <- dplyr::filter(out, is.na(zip) == FALSE)
  out <- dplyr::arrange(out, zip)
  
  # return output
  return(out)
  
}

get_zip_st_louis_city <- function(path){
  
  ## scrape
  out <- get_esri(path = path)
  
  ## tidy
  out <- dplyr::select(out, GEOID10, Cases)
  out <- dplyr::rename(out,
                zip = GEOID10,
                count = Cases)
  out <- dplyr::mutate(out, zip = as.numeric(zip))
  
  ## return output
  return(out)
  
}

get_zip_st_louis_county <- function(path){
  
  ## scrape
  out <- get_esri(path = path)
  
  ## tidy
  out <- dplyr::select(out, zip_5, cases_total)
  out <- dplyr::rename(out,
                       zip = zip_5,
                       count = cases_total)
  out <- dplyr::arrange(out, zip)
  
  ## return output
  return(out)
  
}

get_zip_warren <- function(){
  
  # scrape website
  webpage <- xml2::read_html("https://www.warrencountyhealth.com/covid-19-dashboard/")
  webpage <- rvest::html_nodes(webpage, "p")
  
  # tidy scraped data
  data <- webpage[7]
  data <- suppressWarnings(stringr::str_split(string = data, pattern = "[[:space:]]", simplify = TRUE))
  data <- suppressWarnings(readr::parse_number(data))
  data <- data[is.na(data) == FALSE]
  
  # construct output
  out <- data.frame(
    zip = data[seq(1,length(data),2)],
    count = data[seq(2,length(data),2)]
  )
  
  out <- dplyr::mutate(out, count = abs(count))
  out <- dplyr::mutate(out, count = ifelse(count < 5, NA, count))
  out <- dplyr::filter(out, is.na(count) == FALSE)
  out <- dplyr::arrange(out, zip)
  
  # return output
  return(out)
  
}

get_zip_wyandotte <- function(path){
  
  ## scrape
  out <- get_esri(path = path)
  # out <- get_esri(path = paths$wyandotte)
  
  ## tidy
  out <- dplyr::select(out, zip, confirmed_count)
  out <- dplyr::rename(out, count = confirmed_count)
  out <- dplyr::filter(out, count >= 5)
  out <- dplyr::arrange(out, zip)
  
  ## return output
  return(out)
  
}
