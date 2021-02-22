get_vaccine <- function(metric){
  
  ## scrape and tidy
  if (metric %in% c("total doses", "first dose", "second dose") == TRUE){
    
    ## scrape
    if (metric == "total doses"){
      out <- get_mo_vacc(n = 8)
    } else if (metric == "first dose"){
      out <- get_mo_vacc(n = 9)
    } else if (metric == "second dose"){
      out <- get_mo_vacc(n = 10)
    }
    
    ## tidy
    out <- dplyr::pull(out, `AGG(COVID-19 Doses Administered)-alias`)
    out <- as.numeric(out)
    
  } else if (metric == "totals") {
    
    total <- get_mo_vacc(n = 8)
    total <- dplyr::pull(total, `AGG(COVID-19 Doses Administered)-alias`)
    first <- get_mo_vacc(n = 9)
    first <- dplyr::pull(first, `AGG(COVID-19 Doses Administered)-alias`)
    secnd <- get_mo_vacc(n = 10)
    secnd <- dplyr::pull(secnd, `AGG(COVID-19 Doses Administered)-alias`)
    
    out <- list(
      first = as.numeric(first),
      second = as.numeric(secnd),
      total = as.numeric(total)
    )
    
  } else if (metric == "race"){
    
    ## scrape
    out <- get_mo_vacc(n = 12)
    
    ## tidy
    out <- janitor::clean_names(out)
    
    if ("agg_covid_19_doses_administered_alias" %in% names(out)){
      stop("Race vaccination data has been updated!")
    }
    
    out <- dplyr::rename(out,
      first_dose = agg_first_covid_19_dose_administered_alias,
      # total_dose = agg_covid_19_doses_administered_alias,
      value = race_value
    )
    
    out <- dplyr::mutate(out,
                         first_dose = as.numeric(first_dose),
                         # total_dose = as.numeric(total_dose),
                         value = dplyr::case_when(
                           value == "White" ~ "White",
                           value == "Black or African-American" ~ "Black",
                           value == "American Indian or Alaska Nati" ~ "Native",
                           value == "Asian" ~ "Asian",
                           value == "Native Hawaiian or Other Pacif" ~ "Pacific Islander",
                           value == "Multi-racial" ~ "Two or More"
                         ))
    
    out <- dplyr::mutate(out, total_dose = NA)
    
    out <- dplyr::mutate(out, second_dose = total_dose - first_dose)
    out <- dplyr::select(out, value, first_dose, second_dose, total_dose)
    
  } else if (metric == "ethnicity"){
    
    ## scrape
    out <- get_mo_vacc(n = 7)
    
    ## tidy
    out <- janitor::clean_names(out)
    
    if ("agg_covid_19_doses_administered_alias" %in% names(out)){
      stop("Ethnicity vaccination data has been updated!")
    }
    
    out <- dplyr::rename(out,
                         first_dose = agg_first_covid_19_dose_administered_alias,
                         # total_dose = agg_covid_19_doses_administered_alias,
                         value = recip_ethnicity_value
    )    

    out <- dplyr::mutate(out,
                         first_dose = as.numeric(first_dose),
                         # total_dose = as.numeric(total_dose),
                         value = ifelse(value == "Hispanic or Latino", "Latino", "Not Latino"))
        
    out <- dplyr::mutate(out, total_dose = NA)
    
    out <- dplyr::mutate(out, second_dose = total_dose - first_dose)
    out <- dplyr::select(out, value, first_dose, second_dose, total_dose)
    
  } else if (metric == "county"){
    
    ## scrape
    out <- get_mo_vacc(n = 5)
    
    ## tidy
    out <- janitor::clean_names(out)
    
    out <- dplyr::rename(out,
                         first_dose = agg_first_covid_19_dose_administered_alias,
                         total_dose = agg_covid_19_doses_administered_alias,
                         county = county_name_alias
    ) 
    
    out <- dplyr::mutate(out,
                         first_dose = as.numeric(first_dose),
                         total_dose = as.numeric(total_dose))
    
    out <- dplyr::mutate(out, second_dose = total_dose - first_dose)
    out <- dplyr::select(out, county, first_dose, second_dose, total_dose)
   
    ## scrape 7-day data
    last7 <- get_mo_vacc(n = 4) 
    
    ## tidy
    last7 <- janitor::clean_names(last7) 
    last7 <- dplyr::filter(last7, measure_names_alias == "7-Day COVID-19 Doses Administered")
    
    last7 <- dplyr::rename(last7,
                         prior_week_dose = measure_values_alias,
                         county = county_name_alias
    ) 
    
    last7 <- dplyr::mutate(last7, prior_week_dose = 
                             stringr::str_replace(string = prior_week_dose,
                                                  pattern = ",",
                                                  replacement = ""))
    last7 <- dplyr::mutate(last7, prior_week_dose = as.numeric(prior_week_dose))
    
    last7 <- dplyr::select(last7, county, prior_week_dose)
    
    ## combine
    out <- dplyr::left_join(out, last7, by = "county")
    
  }
  
  ## return output
  return(out)
  
}




# [1] "[1] % Share State"
# [1] "[2] Age - % Complete"
# [1] "[3] By Date"
# [1] "[4] County - Table"
# [1] "[5] County Map - % of Pop"
# [1] "[6] Dashboard Date"
# [1] "[7] Ethnicity - % Complete"
# [1] "[8] Num Vaccinations"
# [1] "[9] Num Vax Dose 1"
# [1] "[10] Num Vax Dose 2"
# [1] "[11] Num Vax Last 7"
# [1] "[12] Race - % Complete"
# [1] "[13] Sex - % Complete"

get_mo_vacc <- function(n){
  host = "https://results.mo.gov"
  views = "/t/COVID19/views/VaccinationsDashboard/Vaccinations"
  
  get_tableau(host = host, views = views, n = n)
  
}

