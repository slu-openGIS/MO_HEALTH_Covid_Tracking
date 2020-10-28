# Construct AM Data Sets

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# dependencies ####
## tidyverse
library(dplyr)
library(lubridate)
library(purrr)
library(readr)

## spatial
library(sf)
library(tigris)

## other
library(janitor)    # data wrangling
library(rjson)      # parse json
library(zoo)        # moving averages

## functions
source("source/functions/get_data.R")
source("source/functions/historic_expand.R")

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# store date value
date <- Sys.Date()-1

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# check ltc metadata for update
update <- fromJSON(file = "https://data.cms.gov/api/views/metadata/v1/s2uc-8wxp")
update <- as.Date(update$dataUpdatedAt)
load("data/source/ltc/last_update.rda")

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# execute workflow ####
## daily workflow elements
source("source/workflow/01_scrape_and_tidy.R")
source("source/workflow/02_create_state_msa.R")
source("source/workflow/03_add_rates.R")
source("source/workflow/04_create_spatial.R")
source("source/workflow/05_create_regions.R")

## weekly workflow elements
if ((update == last_update$current_date) == FALSE){
  source("source/workflow/11_create_ltc.R") 
}

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# clean-up ####
rm(date, update, last_update)
