# Build St. Louis Hospitalization Data ####

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

## read data
hosp_data <- read_csv("data/source/stl_hospital/historic_data.csv") %>%
  mutate(report_date = mdy(report_date))
  
## calculate rolling averages
hosp_data %>%
  mutate(new_in_pt_avg = rollmean(new_in_pt, k = 7, align = "right", fill = NA)) %>%
  mutate(in_pt_avg = rollmean(in_pt, k = 7, align = "right", fill = NA)) %>%
  mutate(icu_avg = rollmean(icu, k = 7, align = "right", fill = NA)) %>%
  mutate(vent_avg = rollmean(vent, k = 7, align = "right", fill = NA)) %>%
  mutate(mortality_avg = rollmean(mortality, k = 7, align = "right", fill = NA)) %>%
  mutate(peds_in_pt_0_11_avg = rollmean(peds_in_pt_0_11, k = 7, align = "right", fill = NA)) %>%
  mutate(peds_in_pt_12_17_avg = rollmean(peds_in_pt_12_17, k = 7, align = "right", fill = NA)) %>%
  mutate(peds_in_pt = peds_in_pt_0_11+peds_in_pt_12_17) %>%
  mutate(peds_in_pt_avg = rollmean(peds_in_pt, k = 7, align = "right", fill = NA)) %>%
  mutate(peds_icu_0_11_avg = rollmean(peds_icu_0_11, k = 7, align = "right", fill = NA)) %>%
  mutate(peds_icu_12_17_avg = rollmean(peds_icu_12_17, k = 7, align = "right", fill = NA)) %>%
  mutate(peds_icu = peds_icu_0_11+peds_icu_12_17) %>%
  mutate(peds_icu_avg = rollmean(peds_icu, k = 7, align = "right", fill = NA)) %>%
  select(report_date, new_in_pt, new_in_pt_avg, in_pt, in_pt_avg, icu, icu_avg, 
         vent, vent_avg, mortality, mortality_avg,
         peds_in_pt_0_11, peds_in_pt_0_11_avg, peds_in_pt_12_17, peds_in_pt_12_17_avg,
         peds_in_pt, peds_in_pt_avg,
         peds_icu_0_11, peds_icu_0_11_avg, peds_icu_12_17, peds_icu_12_17_avg, 
         peds_icu, peds_icu) -> hosp_data

# write data
write_csv(hosp_data, file = "data/metro/stl_hospital.csv")

# clean-up
rm(hosp_data)
