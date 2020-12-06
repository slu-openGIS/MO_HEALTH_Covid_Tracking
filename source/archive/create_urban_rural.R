library(dplyr)
library(janitor)
library(readr)
library(readxl)
library(sf)

mo <- st_read("data/county/daily_snapshot_mo.geojson") %>%
  select(GEOID)
st_geometry(mo) <- NULL

class <- read_excel("data/source/urban_rural/NCHSURCodes2013.xlsx") %>%
  clean_names() %>%
  mutate(GEOID = as.character(fips_code), .before = fips_code) %>%
  select(GEOID, x2013_code) %>%
  rename(class = x2013_code) %>%
  filter(GEOID %in% mo$GEOID)

class <- mutate(class, class = ifelse(GEOID == "29095", 2, class))

class_xl <- tibble(
  GEOID = c("29511", "29512"),
  class = c(1, 4)
)

class <- bind_rows(class, class_xl) %>%
  arrange(GEOID)

write_csv(class, "data/source/urban_rural/urban_rural.csv")
