# scrape zip code data ####

## authorship
## Saint Louis University students Alvin Do, Eric Quach, and Metta Pham all
## contributed to this script and the underlying functions it calls.

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# open RSelenium ####
open_rsel()

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# Missouri ZIPs, Kansas City Area ####

## Clay
clay_zips <- get_zip(state = "MO", county = "Clay")
write_csv(clay_zips, paste0("data/source/kc_daily_zips/clay_", date, ".csv"))

## Jackson County
jackson_zips <- get_zip(state = "MO", county = "Jackson")
write_csv(jackson_zips, paste0("data/source/kc_daily_zips/jackson_", date, ".csv"))

## Kansas City
kc_zips <- get_zip(state = "MO", county = "Kansas City")
write_csv(kc_zips, paste0("data/source/kc_daily_zips/kansas_city_", date, ".csv"))

## Platte County
platte_zips <- get_zip(state = "MO", county = "Platte", method = "html")
write_csv(platte_zips, paste0("data/source/kc_daily_zips/platte_", date, ".csv"))

## clean-up
rm(clay_zips, jackson_zips, kc_zips, platte_zips)
rm(get_zip_clay, get_zip_jackson, get_zip_kc, get_zip_platte)

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# Missouri ZIPs, St. Louis Area ####

## St. Charles County
st_charles_zips <- get_zip(state = "MO", county = "St. Charles")
write_csv(st_charles_zips, paste0("data/source/stl_daily_zips/st_charles_", date, ".csv"))

## Warren County
warren_zips <- get_zip(state = "MO", county = "Warren")
write_csv(warren_zips, paste0("data/source/stl_daily_zips/warren_", date, ".csv"))

## clean-up
rm(st_charles_zips, warren_zips)
rm(get_zip_st_charles, get_zip_warren)

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# Illinois ZIPs ####

## Statewide ZIPs
il_zips <- get_zip(state = "IL")
write_csv(il_zips, paste0("data/source/il_daily_zips/il_zips_", date, ".csv"))

## clean-up
rm(il_zips, get_zip_il)

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# Kansas ZIPs ####

## Johnson County
johnson_zips <- get_zip(state = "KS", county = "Johnson")
write_csv(johnson_zips, paste0("data/source/kc_daily_zips/johnson_", date, ".csv"))

## Wyandotte County
wyandotte_zips <- get_zip(state = "KS", county = "Wyandotte")
write_csv(wyandotte_zips, paste0("data/source/kc_daily_zips/wyandotte_", date, ".csv"))

## clean-up
rm(johnson_zips, wyandotte_zips)
rm(get_zip_johnson, get_zip_wyandotte)

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# close RSelenium ####

## shut down
close_rsel()

## clean-up
rm(rD, remDr, open_rsel, close_rsel)

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# final clean-up ####
rm(get_esri, get_tableau, get_zip)
