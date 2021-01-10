# Build PM Data ####

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# these data include:
#   - ZIP code data for St. Louis
#   - Testing data for Missouri and adjacent states (currently paused because
#     of dashboard changes at the state level)
#   - Hospitalization data for St. Louis
#   - Kansas City county breakdowns (currently paused because legacy dashboard 
#     has not been updated)

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# values ####

## store current Franklin County file name
# franklin_path <- paste0(lubridate::month(Sys.Date()), " ", stringr::str_pad(lubridate::day(Sys.Date()), 2, pad = "0"), " 2020 Table.xlsx")
franklin_path <- "Franklin County Data Rolling.xlsx"
user <- "Chris"
# user <- "Carter"

## store date value
date <- Sys.Date()-1

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# qa promts ####

## confirm Franklin County data
q <- usethis::ui_yeah("Have you added the latest Franklin County ZIP code data to Downloads?")

if (q == FALSE){
  stop("Please update the filename before proceeding!")
}

## confirm St. Louis Pandemic Task Force data
q <- usethis::ui_yeah("Have you manually updated the Pandemic Task Force data from the latest slides?")

if (q == FALSE){
  stop("Please update the hospitalization data manually before proceeding!")
}

## confirm Docker is up and running
q <- usethis::ui_yeah("Have you started Docker?")

if (q == FALSE){
  stop("Please start Docker before proceeding!")
}

## clean-up
rm(q)

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
source("source/functions/get_tableau.R")      # scrape Tableau dashboards (generic)
source("source/functions/get_zip.R")          # scrape zip code data (MO / IL / KS)
source("source/functions/historic_expand.R")  # create empty data for zips by date
source("source/functions/rsel.R")             # open and close RSelenium
source("source/functions/wrangle_zip.R")      # process zip code data (STL)
source("source/functions/wrangle_kc_zip.R")   # process zip code data (KC)

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# workflow ####

source("source/workflow/06_scrape_zips.R")
source("source/workflow/07_create_zips.R")
# source("source/workflow/08_create_testing.R")
source("source/workflow/09_create_stl_hospital.R")
# source("source/workflow/10_create_kc_counties.R")
source("source/workflow/12_create_deaths.R")
source("source/workflow/15_create_demographics.R")

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# clean-up ####
rm(date, user)

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# print zip code unit test results ####
print(zip_test)
