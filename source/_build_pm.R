# Build PM Data ####

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# these data include:
#   - ZIP code data for St. Louis
#   - Testing data for Missouri and adjacent states (currently paused because
#     of dashboard changes at the state level)
#   - Hospitalization data for St. Louis

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# values ####
downloads_path <- "/Users/chris/Downloads"
date <- Sys.Date()

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# qa promts ####

## confirm St. Louis Pandemic Task Force data
hospital_update <- usethis::ui_yeah("Have you manually updated the Pandemic Task Force data from the latest slides?")

## confirm vaccine process
q <- usethis::ui_yeah("Have you added the latest four race/ethnicity vaccination data files to Downloads?")

if (q == FALSE){
  stop("Please download all four race/ethnicity files before proceeding!")
}

## confirm Docker started data
q <- usethis::ui_yeah("Have you downloaded the latest Illinois ZIP code data?")

if (q == FALSE){
  stop("Please download the Illinois ZIP code data before proceeding!")
}

## clean-up
rm(q)

## confirm auto update data
auto_update <- usethis::ui_yeah("Do you want to automatically update the remote GitHub repo?")

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# dependencies ####

## packages
### tidyverse
library(dplyr)          # data wrangling
library(lubridate)      # dates and times
library(purrr)          # functional programming
library(readr)          # csv file tools
library(readxl)         # excel file tools
library(testthat)       # unit testing
library(tidyr)          # data wrangling

### spatial packages
library(sf)             # mapping tools

### other packages
library(janitor)        # data wrangling
library(zoo)            # rolling means

## functions
source("source/functions/get_cases.R")        # scrape case/death data (MO)
source("source/functions/get_demographics.R") # scrape demographic data (MO)
source("source/functions/get_esri.R")         # scrape ESRI dashboards (generic)
source("source/functions/get_tableau.R")      # scrape Tableau dashboards (generic)
source("source/functions/get_zip.R")          # scrape zip code data (MO / IL / KS)
source("source/functions/historic_expand.R")  # create empty data for zips by date
source("source/functions/wrangle_zip.R")      # process zip code data (STL)
source("source/functions/wrangle_kc_zip.R")   # process zip code data (KC)

rm(get_zip_il, get_zip_st_charles) 
rm(get_zip_platte, get_zip_platte_bi, get_zip_platte_html, get_zip_jackson)

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# workflow ####

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
rm(date, user)

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# print zip code unit test results ####
print(zip_test)
