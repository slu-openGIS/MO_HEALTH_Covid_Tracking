# Build AM Data ####

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# these data include:
#   - the New York Times county data, which is used to build county, metro,
#     regional, and state data sets for MO and adjacent areas
#   - CMS nursing home data, but only if they have been updated
#   - HHS hospitalization data, but only if they have been updated (in progress)

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# qa prompts ####

## load function
source("source/functions/get_last_update.R")

## check last update
q <- get_last_update(source = "New York Times")

## evaluate last update
if (q == FALSE){
  stop("AM update aborted!")
}

## confirm auto update data
auto_update <- usethis::ui_yeah("Do you want to automatically update the remote GitHub repo?")

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# dependencies ####

## packages
### tidyverse
library(dplyr)          # data wrangling
library(lubridate)      # dates and times
library(purrr)          # functional programming
library(readr)          # csv file tools

### spatial
library(sf)             # mapping tools
# library(tigris)

### other
library(janitor)        # data wrangling
library(rjson)          # parse json
library(zoo)            # rolling means

## functions
source("source/functions/get_data.R")         # call NYTimes API
source("source/functions/historic_expand.R")  # create empty data for zips by date

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# store date value
date <- Sys.Date()-1

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# execute daily workflow ####

source("source/workflow/01_scrape_and_tidy.R")
source("source/workflow/02_create_state_msa.R")
source("source/workflow/03_add_rates.R")
source("source/workflow/04_create_spatial.R")
source("source/workflow/05_create_regions.R")

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# execute weekly workflow ####

## check ltc metadata for update
update <- get_last_update(source = "CMS")
load("data/source/ltc/last_update.rda")

## rebuild ltc data if there has been an update
if ((update == last_update$current_date) == FALSE){
  source("source/workflow/11_create_ltc.R") 
}

## check hospitalization metadata for update
# update <- get_last_update(source = "HHS")
# load("data/source/hhs/last_update.rda")

## rebuild hhs data if there has been an update
# if ((update == last_update$current_date) == FALSE){
#  source("source/workflow/14_create_hhs.R") 
#}

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# optionally pushed to GitHub
if (auto_update == TRUE){
  
  system("git add -A")
  system(paste0("git commit -a -m 'build am data for ", as.character(date+1), "'"))
  system("git push origin master")
  
}

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# clean-up ####
rm(date, auto_update, update, last_update, q, get_last_update)
