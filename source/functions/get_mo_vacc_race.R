get_mo_vacc_race <- function(){
  
  race_list <- list()
  total_init_list <- list()
  total_comp_list <- list()
  
  # Navigate to Tableau dashboard
  remDr$navigate("https://results.mo.gov/t/COVID19/views/VaccinationsDashboard/Vaccinations")
  Sys.sleep(10)
  
  # Click on page and scroll down to data plot area
  remDr$findElement('//*[@id="view3135269236547538553_202816268246377735"]/div[1]/div[2]/canvas[2]', using = 'xpath')$clickElement()
  
  for (i in 1:20){
    remDr$findElement("css", "body")$sendKeysToElement(list(key="down_arrow"))
  }
  
  # Click on "Race" radio button
  remDr$findElement('//*[@id="[Parameters].[Pop Benchmark - 35-44 (copy)]_2"]/div[2]/input', using = "xpath")$clickElement()
  remDr$findElement('//*[@id="[Parameters].[Pop Benchmark - 35-44 (copy)]_2"]/div[2]/input', using = "xpath")$clickElement()
  Sys.sleep(3)
  
  # Moving mouse to race plot
  race_barplot <- remDr$findElement('//*[@id="view3135269236547538553_1000113453828777861"]/div[1]/div[2]/canvas[2]', using = 'xpath')
  remDr$mouseMoveToLocation(webElement = race_barplot)
  Sys.sleep(3)
  
  # Moving mouse to first bar
  remDr$mouseMoveToLocation(x = -440, y = 165)
  Sys.sleep(1)
  
  # Gathering the data
  for (i in 1:6){
    data <- xml2::read_html(remDr$getPageSource()[[1]])
    data <- selectr::querySelectorAll(data, "div.tab-tooltip table tbody tr td span")
    data <- purrr::map_chr(data, xml2::xml_text)
    
    race_list[i] <- data[3]
    total_init_list[i] <- gsub(',', '', data[7])
    total_comp_list[i] <- gsub(',', '', data[9])
    
    remDr$mouseMoveToLocation(x = 150)
    
  }
  
  # Clicking on "Ethnicity" radio button
  remDr$findElement('//*[@id="[Parameters].[Pop Benchmark - 35-44 (copy)]_3"]/div[2]/input', using = 'xpath')$clickElement()
  Sys.sleep(3)
  
  # Moving mouse to bar plot
  eth_barplot <- remDr$findElement('//*[@id="view3135269236547538553_1000113453828777861"]/div[1]/div[2]/canvas[2]', using = 'xpath')
  remDr$mouseMoveToLocation(webElement = eth_barplot)
  
  remDr$mouseMoveToLocation(x = -440, y = 165)
  
  # Gathering data
  remDr$mouseMoveToLocation(webElement = eth_barplot)
  remDr$mouseMoveToLocation(x = -440, y = 165)
  
  data <- xml2::read_html(remDr$getPageSource()[[1]])
  data <- selectr::querySelectorAll(data, "div.tab-tooltip table tbody tr td span")
  data <- purrr::map_chr(data, xml2::xml_text)
  
  race_list[7] <- data[3]
  total_init_list[7] <- gsub(',', '', data[7])
  total_comp_list[7] <- gsub(',', '', data[9])
  
  # tidy
  out <- do.call(rbind, Map(data.frame,
                            report_date = Sys.Date() - 1,
                            geoid = 29,
                            value=race_list,
                            initiated = total_init_list,
                            completed = total_comp_list))
  
  out <- dplyr::mutate(out, 
                       initiated = as.numeric(initiated),
                       completed = as.numeric(completed))
  return(out)
}
