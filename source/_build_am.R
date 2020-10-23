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
library(zoo)        # moving averages

## functions
source("source/functions/get_data.R")
source("source/functions/historic_expand.R")

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# store date value
date <- Sys.Date()-1

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# execute workflow ####
source("source/workflow/01_scrape_and_tidy.R")
source("source/workflow/02_create_state_msa.R")
source("source/workflow/03_add_rates.R")
source("source/workflow/04_create_spatial.R")
source("source/workflow/05_create_regions.R")
# source("source/workflow/10_create_ltc.R")

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# clean-up ####
rm(date)
