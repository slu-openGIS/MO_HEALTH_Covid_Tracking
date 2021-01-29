# scrape zip code data - headless browser / RSelenium ####

## authorship
## Saint Louis University students Alvin Do, Eric Quach, and Metta Pham all
## contributed to this script and the underlying functions it calls.

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# open RSelenium ####
open_rsel()

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# Missouri ZIPs, Kansas City Area ####

## Platte County
# platte_zips <- get_zip(state = "MO", county = "Platte", method = "mixed")
# write_csv(platte_zips, paste0("data/source/kc_daily_zips/platte_", date, ".csv"))

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# Missouri ZIPs, St. Louis Area ####

## St. Charles County
st_charles_zips <- get_zip(state = "MO", county = "St. Charles", cut = FALSE)
write_csv(st_charles_zips, paste0("data/source/stl_daily_zips/st_charles_", date, ".csv"))

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# Illinois ZIPs ####

## Statewide ZIPs
il_zips <- get_zip(state = "IL", paged = FALSE)
write_csv(il_zips, paste0("data/source/il_daily_zips/il_zips_", date, ".csv"))

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

## clean-up
rm(platte_zips, st_charles_zips, il_zips)
rm(get_zip_platte, get_zip_platte_bi, get_zip_platte_html, get_zip_il,
   get_zip_st_charles)

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# close RSelenium ####

## shut down
close_rsel()

## clean-up
rm(open_rsel, close_rsel)

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# update status
message("RSelenium code completed successfully!")
