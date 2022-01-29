# statewide hospitalization counts ####

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

## download and subset to just MO
hosp <- read_csv("https://healthdata.gov/api/views/g62h-syeh/rows.csv",
                 col_types = cols(date = col_date())) %>%
  filter(state == "MO") 

hosp <- arrange(hosp, date)

## subset columns
hosp_a <- select(hosp, date, 
                 total_adult_patients_hospitalized_confirmed_and_suspected_covid,
                 total_pediatric_patients_hospitalized_confirmed_and_suspected_covid,
                 staffed_icu_adult_patients_confirmed_and_suspected_covid,
                 percent_of_inpatients_with_covid, deaths_covid)

hosp_b <- select(hosp, date,
                 previous_day_admission_adult_covid_confirmed,
                 previous_day_admission_adult_covid_suspected,
                 previous_day_admission_pediatric_covid_confirmed,
                 previous_day_admission_pediatric_covid_suspected)

## prep columns
hosp_a %>% 
  select(
    report_date = date,
    in_pt_adult = total_adult_patients_hospitalized_confirmed_and_suspected_covid,
    in_pt_peds = total_pediatric_patients_hospitalized_confirmed_and_suspected_covid,
    in_pt_pct = percent_of_inpatients_with_covid,
    icu_adult = staffed_icu_adult_patients_confirmed_and_suspected_covid,
    mortality = deaths_covid
  ) %>%
  mutate(in_pt_adult_avg = rollmean(in_pt_adult, k = 7, align = "right", fill = NA), .after = in_pt_adult) %>%
  mutate(in_pt_peds_avg = rollmean(in_pt_peds, k = 7, align = "right", fill = NA), .after = in_pt_peds) %>%
  mutate(in_pt_pct_avg = rollmean(in_pt_pct, k = 7, align = "right", fill = NA), .after = in_pt_pct) %>%
  mutate(icu_adult_avg = rollmean(icu_adult, k = 7, align = "right", fill = NA), .after = icu_adult) %>%
  mutate(mortality_avg = rollmean(mortality, k = 7, align = "right", fill = NA), .after = mortality) -> hosp_a

hosp_b %>%
  mutate(
    report_date = date-1,
    new_in_pt_adult = previous_day_admission_adult_covid_confirmed + previous_day_admission_adult_covid_suspected,
    new_in_pt_peds = previous_day_admission_pediatric_covid_confirmed + previous_day_admission_pediatric_covid_suspected
  ) %>%
  select(report_date, new_in_pt_adult, new_in_pt_peds) %>%
  mutate(new_in_pt_adult_avg = rollmean(new_in_pt_adult, k = 7, align = "right", fill = NA), .after = new_in_pt_adult) %>%
  mutate(new_in_pt_peds_avg = rollmean(new_in_pt_peds, k = 7, align = "right", fill = NA), .after = new_in_pt_peds) -> hosp_b

## combine
hosp <- left_join(hosp_a, hosp_b, by = "report_date")

## save
write_csv(hosp, "data/state/state_hospital.csv")

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

## clean-up
rm(hosp, hosp_a, hosp_b)
