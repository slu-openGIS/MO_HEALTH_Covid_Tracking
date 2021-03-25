get_vaccine <- function(metric){
  
  ## scrape and tidy
  if (metric %in% c("initiated", "completed") == TRUE){
    
    ## scrape
    if (metric == "initiated"){
      out <- get_mo_vacc(n = 8)
      out <- dplyr::pull(out, `AGG(COVID-19 Doses Administered)-alias`)
    } else if (metric == "completed"){
      out <- get_mo_vacc(n = 9)
      out <- dplyr::pull(out, `SUM(Vax Complete)-alias`)
    }
    
    ## tidy
    out <- as.numeric(out)
    
  } else if (metric == "totals") {
    
    initiated <- get_mo_vacc(n = 8)
    initiated <- dplyr::pull(initiated, `AGG(COVID-19 Doses Administered)-alias`)
    complete <- get_mo_vacc(n = 9)
    complete <- dplyr::pull(complete, `SUM(Vax Complete)-alias`)
    
    out <- list(
      initiated = as.numeric(initiated),
      complete = as.numeric(complete)
    )
    
  } else if (metric == "race"){
    
    ## scrape
    out <- get_mo_vacc(n = 11)
    
    ## tidy
    out <- janitor::clean_names(out)
    
    out <- dplyr::rename(out,
      initiated = agg_first_covid_19_dose_administered_alias,
      value = race1_value
    )
    
    out <- dplyr::mutate(out,
                         initiated = as.numeric(initiated),
                         value = dplyr::case_when(
                           value == "White" ~ "White",
                           value == "Black or African-American" ~ "Black",
                           value == "American Indian or Alaska Nati" ~ "Native",
                           value == "Asian" ~ "Asian",
                           value == "Native Hawaiian or Other Pacif" ~ "Pacific Islander",
                           value == "Multi-racial" ~ "Two or More"
                         ))
    
    out <- dplyr::select(out, value, initiated)
    
  } else if (metric == "ethnicity"){
    
    ## scrape
    out <- get_mo_vacc(n = 6)
    
    ## tidy
    out <- janitor::clean_names(out)
    
    out <- dplyr::rename(out,
                         initiated = agg_first_covid_19_dose_administered_alias,
                         value = recip_ethnicity_value
    )    

    out <- dplyr::mutate(out,
                         initiated = as.numeric(initiated),
                         value = ifelse(value == "Hispanic or Latino", "Latino", "Not Latino"))
        
    out <- dplyr::select(out, value, initiated)
    
  } else if (metric == "county"){
    
    ## scrape
    out <- get_mo_vacc(n = 4)
    
    ## tidy
    out <- janitor::clean_names(out)
    
    out <- dplyr::rename(out,
                         count = measure_values_alias,
                         value = measure_names_alias,
                         county = jurisdiction_value
    ) 
    
    out <- dplyr::select(out, county, value, count)
    out <- dplyr::filter(out, value %in% c("Percent of Population Initiating Vaccination",
                                           "COVID-19 Doses Administered") == FALSE)
    out <- dplyr::mutate(out, count = stringr::str_replace(string = count, patter = ",", replacement = ""))
    out <- dplyr::mutate(out, count = as.numeric(count))
    
    out <- dplyr::mutate(out, value = dplyr::case_when(
      value == "7-Day COVID-19 Doses Administered" ~ "last7",
      value == "COVID-19 Vaccine Regimen Completed" ~ "complete", 
      value == "COVID-19 Vaccine Regimen Initiated" ~ "initiated"
    ))
    
    out <- tidyr::pivot_wider(out, id = county, names_from = value, values_from = count)
    out <- dplyr::select(out, county, initiated, complete, last7)
    
  }
  
  ## return output
  return(out)
  
}

get_mo_vacc <- function(n){
  host = "https://results.mo.gov"
  views = "/t/COVID19/views/VaccinationsDashboard/Vaccinations"
  
  get_tableau(host = host, views = views, n = n)
  
}

