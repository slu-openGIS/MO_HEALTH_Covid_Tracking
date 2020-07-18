# Scrape Data and Construct Data Sets, PM only

# UPDATE city zip's with < 5 or 0 cases
city_lt5 <- c("63117", "63119", "63125", "63130", "63133", "63143")

# store date value
date <- Sys.Date()

# dependencies
library(dplyr)
library(lubridate)
library(purrr)
library(readr)
library(sf)
library(tidyr)
library(zoo)

# functions
source("source/functions/wrangle_zip.R")

# workflow
source("source/workflow/05_create_zip.R")
source("source/workflow/06_create_testing.R")
source("source/workflow/07_create_stl_hospital.R")
source("source/workflow/08_create_kc_counties.R")

# clean-up
rm(date)
