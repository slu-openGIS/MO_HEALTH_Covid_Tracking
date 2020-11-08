# Build PM Data ####

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# these data include:
#   - ZIP code data for St. Louis
#   - Hospitalization data for St. Louis
#   - Kansas City county breakdowns

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# values ####

## store current Franklin County file name
franklin_path <- "11 07 2020 Table.xlsx"

## store date value
date <- Sys.Date()

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# dependencies ####

## packages
library(dplyr)
library(lubridate)
library(purrr)
library(readr)
library(readxl)
library(sf)
library(tidyr)
library(zoo)

## functions
source("source/functions/historic_expand.R")
source("source/functions/wrangle_zip.R")

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# workflow ####

source("source/workflow/06_create_zips.R")
# source("source/workflow/08_create_testing.R")
source("source/workflow/09_create_stl_hospital.R")
source("source/workflow/10_create_kc_counties.R")

# clean-up
rm(date)

# print zip code unit test results
print(zip_test)
