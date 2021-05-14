# Build PM Data ####

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# these data include:
#   - ZIP code data for St. Louis
#   - Testing data for Missouri and adjacent states (currently paused because
#     of dashboard changes at the state level)
#   - Hospitalization data for St. Louis

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# values ####

## store current Franklin County file name
# franklin_path <- paste0(lubridate::month(Sys.Date()), " ", stringr::str_pad(lubridate::day(Sys.Date()), 2, pad = "0"), " 2020 Table.xlsx")
franklin_path <- "Franklin County Data Rolling.xlsx"
user <- "Chris"
# user <- "Carter"

## store date value
date <- Sys.Date()

## set browser
# browser_name <- "firefox"
browser_name <- "chrome"

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# qa promts ####

## confirm Franklin County data
q <- usethis::ui_yeah("Have you added the latest Franklin County ZIP code data to Downloads?")

# if (q == FALSE){
#  stop("Please update the filename before proceeding!")
# }

## confirm St. Louis Pandemic Task Force data
hospital_update <- usethis::ui_yeah("Have you manually updated the Pandemic Task Force data from the latest slides?")

## confirm vaccine process
vaccine_race_scrape <- usethis::ui_yeah("Do you want to attempt to scrape the vaccination race data from the State dashboard?")

if (vaccine_race_scrape == FALSE){
  q <- usethis::ui_yeah("Have you manually updated the vaccination rate data from the State dashboard?")
  
  if (q == FALSE){
    stop("Please update the vaccination race data before proceeding!")
  }
}

## confirm Docker started data
q <- usethis::ui_yeah("Have you started the Docker daemon?")

if (q == FALSE){
  stop("Please start the Docker daemon before proceeding!")
}

## clean-up
rm(q)

## confirm auto update data
auto_update <- usethis::ui_yeah("Do you want to automatically update the remote GitHub repo?")

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# start docker ####
# docker image being used is - selenium/standalone-firefox
# one update might be to use a more modern firefox version - I think this image is pretty old

system("docker run -d -p 4445:4444 selenium/standalone-chrome")

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

if (vaccine_race_scrape == FALSE){
  vaccine_race_ethnic <- dplyr::tibble(
    report_date = rep(date, 7),
    geoid = rep(29, 7),
    value = c("American Indian or Alaska Native", "Asian", "Black or African-American",
              "Multi-racial", "Native Hawaiian or Other Pacific Islander", 
              "White", "Hispanic or Latino"),
    initiated = c(4159, 59564, 163289, 
                  105090, 4033, 
                  1616785, 93539),
    completed = c(2972, 42068, 121326,
                  91917, 3024, 
                  1342120, 69207)
  )
}

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# dependencies ####

## packages
### tidyverse
library(dplyr)          # data wrangling
library(lubridate)      # dates and times
library(purrr)          # functional programming
library(readr)          # csv file tools
library(readxl)         # excel file tools
library(tidyr)          # data wrangling

### spatial packages
library(sf)             # mapping tools

### other packages
library(zoo)            # rolling means

## functions
source("source/functions/get_cases.R")        # scrape case/death data (MO)
source("source/functions/get_demographics.R") # scrape demographic data (MO)
source("source/functions/get_esri.R")         # scrape ESRI dashboards (generic)
source("source/functions/get_mo_vacc.R")      # scrape vaccine data (MO / STL)
source("source/functions/get_mo_vacc_race.R")      # scrape vaccine data (MO / STL)
source("source/functions/get_tableau.R")      # scrape Tableau dashboards (generic)
source("source/functions/get_zip.R")          # scrape zip code data (MO / IL / KS)
source("source/functions/historic_expand.R")  # create empty data for zips by date
source("source/functions/rsel.R")             # open and close RSelenium
source("source/functions/wrangle_zip.R")      # process zip code data (STL)
source("source/functions/wrangle_kc_zip.R")   # process zip code data (KC)

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# workflow ####

source("source/workflow/06_scrape_zips_selenium.R")
source("source/workflow/06_scrape_zips.R")
source("source/workflow/07_create_zips.R")

if (hospital_update == TRUE){
  source("source/workflow/09_create_stl_hospital.R")
}

source("source/workflow/12_create_deaths.R")
source("source/workflow/15_create_demographics.R")
source("source/workflow/16_create_vaccines.R")  

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# optionally pushed to GitHub
if (auto_update == TRUE){
  
  system("git add -A")
  system(paste0("git commit -a -m 'build pm data for ", as.character(date), "'"))
  system("git push origin master")
  
}

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# clean-up R environment ####
rm(date, auto_update, hospital_update, user, browser_name)

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# clean-up docker environment ####
system("docker stop $(docker ps -a -q)")
system("docker rm $(docker ps -a -q)")

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# print zip code unit test results ####
print(zip_test)
