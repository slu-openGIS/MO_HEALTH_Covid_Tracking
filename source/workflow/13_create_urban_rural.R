# Build Urban-Rural Data ####

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# load and preprocess data ####

class <- read_csv("data/source/urban_rural/urban_rural.csv",
                  col_types = cols(
                    GEOID = col_character(),
                    class = col_double()
                  ))

county <- read_csv("data/county/county_full.csv") %>%
  filter(geoid %in% class$GEOID) %>%
  select(report_date, geoid, county, cases, new_cases, deaths, new_deaths)

county_pop <- st_read("data/source/mo_county_plus/mo_county_plus.shp") %>%
  select(GEOID, total_pop)

st_geometry(county_pop) <- NULL

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# initial join ####

## join
county <- left_join(county, class, by = c("geoid" = "GEOID")) %>%
  left_join(., county_pop, by = c("geoid" = "GEOID"))

## clean-up
rm(class, county_pop)

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# simplify classes ####
county <- mutate(county, type = case_when(
  class == 1 ~ "Large Metro, Central",
  class == 2 ~ "Large Metro, Fringe",
  class %in% c(3,4) ~ "Small Metro",
  class %in% c(5,6) ~ "Non-Metro"
))

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# create trends

## create trends
county %>%
  group_by(report_date, type) %>%
  summarise(
    cases = sum(cases),
    new_cases = sum(new_cases),
    deaths = sum(deaths),
    new_deaths = sum(new_deaths),
    total_pop = sum(total_pop)
  )  %>%
  group_by(report_date, type) %>%
  mutate(
    case_avg = rollmean(new_cases, k = 7, align = "right", fill = NA),
    deaths_avg = rollmean(new_deaths, k = 7, align = "right", fill = NA)
  )  -> class

## create rates
class %>%
  mutate(case_rate = cases/total_pop*100000, .after = cases) %>%
  mutate(death_rate = deaths/total_pop*100000, .after = deaths) -> x
  
  