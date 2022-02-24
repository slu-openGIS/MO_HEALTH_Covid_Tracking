# LTC example script

# This is just a Qol user query to allow for easy uuid access from the webpage
#print("Please enter 'Dataset Version Identifier' from the following URL:")
#print("https://data.cms.gov/covid-19/covid-19-nursing-home-data/api-docs")
#uuid <- readline(prompt="Dataset Version Identifier: ")
uuid <- "8b46674e-a152-4e88-9307-a193c70ab03a"


# library(splusTimeDate)
library("jsonlite")
library(tidyverse)
library(selectr)
library(httr)
library(sf)
library(janitor)


## This function write data to a specified directory given a uuid.
## For an example I'm only pulling from one state, the function as it stands is hard coded to pull from 4
write_ltc_data <- function(id) {
  pages <- list()
  more <- TRUE
  i <- 0
  p <- 0
  a <- 1
  #state specification can be done here
  #state <- c("MO", "IL", "KS", "OK")
  
  state <- c("MO")
  #migrate to function, allow for parallelization, parallelize across states? sort dataframe afterwards
  while(more){
    url <- paste("https://data.cms.gov/data-api/v1/dataset/", id, 
                 "/data?filter[provider_state]=", state[a], "&size=2000&offset=", 
                 i*2000, sep = '')
    mydata <- jsonlite::fromJSON(url)
    message("Retrieving page ", i, " from ", state[a])
    message("Nursing homes sampled: ", nrow(mydata))
    message(url)
    i <- i + 1
    p <- p + 1
    pages[[p+1]] <- mydata
    if (nrow(mydata) < 2000) {
      a <- a + 1
      message("New state ", state[a])
      i <- 0
      if (length(state) < a) {
        more <- FALSE 
      }
    }
  }
  covid <- jsonlite::rbind_pages(pages)
  covid <- as.data.frame(covid)
  # write.csv(covid, "COVID-19 Nursing Home Data.csv", row.names=FALSE)
}
swrite_ltc_data(uuid)

# library(V8)
# file_date stores the last modified date of the ltc data file in the year-month-day format
file_date <- as.Date(strtrim(file.info("COVID-19 Nursing Home Data.csv")$mtime, 10))
file_date

# update date stores the most recent update date of the ltc data webpage
url <- "https://data.cms.gov/covid-19/covid-19-nursing-home-data/api-docs"
page <- rvest::session(url)
update_date <- as.Date(substring(page$response$headers$`last-modified`, first = 6, last = 16), "%d %B %Y")
update_date

page <- xml2::read_html(url)
out <- rvest::html_nodes(page, "table table-sm table-bordered")

page %>%
  rvest::html_element("table table-sm table-bordered") %>%
  rvest::html_table()

# Since as of tiday the difference is not great than one week I will spoof some data
update_date <- "2022-01-24"

# week_diff stores the difference in weeks between the file update and the website update
week_diff <- abs(as.double(difftime(update_date, file_date, units = 'weeks')))
print(paste0("Difference between last file write and data update is ", toString(week_diff), " weeks"))

# if the difference between file and website exceeds one week, update the ltc data
if (week_diff > 1.0 | is.na(week_diff) == T) {
  # This is the Covid data pull function demonstrated earlier
  #write_ltc_data(uuid)
}

# this is just a sanity check data load, saving/loading csv saves time because read_csv infers column data type
covid <- read_csv(file = "COVID-19 Nursing Home Data.csv") %>% 
  clean_names()
head(covid)