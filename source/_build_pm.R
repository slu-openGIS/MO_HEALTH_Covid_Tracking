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
franklin_path <- paste0(lubridate::month(Sys.Date()), " ", stringr::str_pad(lubridate::day(Sys.Date()), 2, pad = "0"), " 2020 Table.xlsx")
# franklin_path <- "11 15 2020 Table.xlsx"

## store date value
date <- Sys.Date()

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
source("source/functions/get_state.R")        # scrape state level data
source("source/functions/historic_expand.R")  # create empty data for zips by date
source("source/functions/wrangle_zip.R")      # process zip code data

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# workflow ####

source("source/workflow/06_create_zips.R")
# source("source/workflow/08_create_testing.R")
source("source/workflow/09_create_stl_hospital.R")
# source("source/workflow/10_create_kc_counties.R")
source("source/workflow/12_create_deaths.R")

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# clean-up ####
rm(date, q, get_state)

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# print zip code unit test results ####
print(zip_test)
