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

