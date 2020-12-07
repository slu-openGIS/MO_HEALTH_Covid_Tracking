get_zip <- function(state, county) {
  
  load("data/source/paths.rda")
  
  ## call sub-functions
  if (state == "MO"){
    
    if (county == "Clay"){
      out <- get_zip_clay(path = paths$clay)
    } else if (county == "Jackson"){
      out <- get_zip_jackson(path = paths$jackson)
    } else if (county == "Kansas City"){
      out <- get_zip_kc()
    } else if (county == "Platte"){
      out <- get_zip_platte()
    } else if (county == "St. Charles"){
      out <- get_zip_st_charles(cut = FALSE) 
    }
    
  } else if (state == "IL"){
    out <- get_zip_il()
  } else if (state == "KS"){
    
    if (county == "Johnson"){
      
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
  out <- dplyr::select(out, f1, Pop_up_Data_Zip)
  out <- dplyr::rename(out, zip = f1, count = Pop_up_Data_Zip)
  out <- dplyr::filter(out, zip != 0)
  out <- dplyr::mutate(out, count = ifelse(count %in% c("<6", "0"), NA, count))
  out <- dplyr::mutate(out, count = as.numeric(count))
  out <- dplyr::filter(out, is.na(count) == FALSE)
  out <- dplyr::arrange(out, zip)
  
  ## return output
  return(out)
  
}

get_zip_il <- function(){
  
  remDr$navigate("https://dph.illinois.gov/covid19/statistics")
  Sys.sleep(3)
  
  # find and click the button leading to the Zip Code data
  remDr$findElement("#pagin > li:last-child > a", using = "css selector")$clickElement()
  Sys.sleep(3)
  
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

get_zip_jackson <- function(path){
  
  ## scrape
  out <- get_esri(path = path)
  
  ## tidy
  out <- dplyr::select(out, ZIP, COVID_cases)   
  out <- dplyr::rename(out,
                       zip = ZIP, 
                       count = COVID_cases
  )
  out <- dplyr::arrange(out, zip)
  
  ## return output
  return(out)
  
}

get_zip_johnson <- function(){
  
  ## scrape
  out <- get_tableau(host = "https://public.tableau.com", 
                     views = "/views/covid19_joco_public/dbCumulative", 
                     n = 1)
  
}

get_zip_kc <- function(){
  
  ## api call
  out <- readr::read_csv("https://data.kcmo.org/resource/98fz-2jyt.csv",
                         col_types = readr::cols(
                           zipcode = readr::col_double(),
                           cases = readr::col_character(),
                           crude_rate_per_100_000 = readr::col_character(),
                           total_residents_tested = readr::col_double(),
                           positivity_rate = readr::col_double()
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

get_zip_platte <- function(){
  
  remDr$navigate("https://app.powerbi.com/view?r=eyJrIjoiODRhZjQ5MTEtNTJhNi00NjczLTlmMGYtYmYyNjVkZTEwMzg0IiwidCI6Ijk1Njc2ZGE2LTJlMzYtNGFkNi1hNThlLTUyNzg0NmI3M2M5MyJ9")
  Sys.sleep(3)
  
  zipcode_data_table <- xml2::read_html(remDr$getPageSource()[[1]])
  zipcode_data_table <- selectr::querySelectorAll(zipcode_data_table, "svg.svgScrollable")
  
  zip_data <- selectr::querySelectorAll(zipcode_data_table[[4]], "g.columnChartUnclippedGraphicsContext svg g rect")
  zip_data <- rvest::html_attr(zip_data, "aria-label")
  zip_data <- unlist(strsplit(zip_data, "\\."))
  
  zip_code <- unlist(as.data.frame(t(stringr::str_match_all(zip_data, "[0-9]+"))))[c(TRUE, FALSE)]
  zip_code <- dplyr::as_tibble(zip_code)
  zip_code <- dplyr::rename(zip_code, zip_code = value)
  zip_code <- transform(zip_code, zip_code = as.numeric(zip_code))
  
  cases <- unlist(as.data.frame(t(stringr::str_match_all(zip_data, "[0-9]+"))))[c(FALSE, TRUE)]
  cases <- dplyr::as_tibble(cases)
  cases <- dplyr::rename(cases, cases = value)
  cases <- dplyr::mutate(cases, cases = as.numeric(cases))
  
  out <- dplyr::bind_cols(zip_code, cases)
  
  out <- dplyr::rename(out,
                       zip = zip_code,
                       count = cases
  )
  out <- dplyr::arrange(out, zip)
  
  ## return output
  return(out)
  
}

get_zip_st_charles <- function(cut = FALSE){
  
  # navigate to the site you wish to analyze
  remDr$navigate("https://app.powerbigov.us/view?r=eyJrIjoiZDFmN2ViMGEtNzQzMC00ZDU3LTkwZjUtOWU1N2RiZmJlOTYyIiwidCI6IjNiMTg1MTYzLTZjYTMtNDA2NS04NDAwLWNhNzJiM2Y3OWU2ZCJ9&pageName=ReportSectionb438b98829599a9276e2&pageName=ReportSectionb438b98829599a9276e2")
  Sys.sleep(3)
  
  # find and click the button leading to the Zip Code data
  remDr$findElement('.//button[descendant::span[text()="Zip Code"]]', using="xpath")$clickElement()
  Sys.sleep(3)
  
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
    zipcode_data <- dplyr::slice(zipcode_data, 1:15)
    zipcodes <- dplyr::slice(zipcodes, 1:15)
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

get_zip_wyandotte <- function(path){
  
  ## scrape
  out <- get_esri(path = path)
  
  ## tidy
  out <- dplyr::select(out, zip, confirmed_count)
  out <- dplyr::rename(out, count = confirmed_count)
  out <- dplyr::filter(out, count >= 5)
  out <- dplyr::arrange(out, zip)
  
  ## return output
  return(out)
  
}
