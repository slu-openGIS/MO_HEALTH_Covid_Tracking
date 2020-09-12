# Scape Data and Construct Data Sets

# store date value
date <- Sys.Date()-1

# dependencies
library(dplyr)
library(lubridate)
library(purrr)
library(readr)
library(sf)
library(tigris)
library(zoo)

# functions
source("source/functions/get_data.R")
source("source/functions/historic_expand.R")

# workflow
source("source/workflow/01_scrape_and_tidy.R")
source("source/workflow/02_create_state_msa.R")
source("source/workflow/03_add_rates.R")
source("source/workflow/04_create_spatial.R")
source("source/workflow/05_create_regions.R")

# clean-up
rm(date)
