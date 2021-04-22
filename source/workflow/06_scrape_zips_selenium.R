# scrape zip code data - headless browser / RSelenium ####

## authorship
## Saint Louis University students Alvin Do, Eric Quach, and Metta Pham all
## contributed to this script and the underlying functions it calls.

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# open RSelenium ####
open_rsel(browser = browser_name)

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# Missouri ZIPs, Kansas City Area ####

## Jackson County
jackson_zips <- get_zip(state = "MO", county = "Jackson")
write_csv(jackson_zips, paste0("data/source/kc_daily_zips/jackson_", date, "_rates.csv"))

## Platte County
platte_zips <- get_zip(state = "MO", county = "Platte", method = "html")
write_csv(platte_zips, paste0("data/source/kc_daily_zips/platte_", date, ".csv"))

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

# MO Race Vaccination Data
vaccine_race_ethnic <- get_mo_vacc_race()

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

## clean-up
rm(platte_zips, st_charles_zips, il_zips, jackson_zips)
rm(get_zip_platte, get_zip_platte_bi, get_zip_platte_html, get_zip_il,
   get_zip_st_charles, get_zip_jackson, get_mo_vacc_race)

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# close RSelenium ####

## shut down
close_rsel()

## clean-up
rm(open_rsel, close_rsel)

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# update status
message("RSelenium code completed successfully!")
