# MO_HEALTH_Covid_Tracking

This repository contains the data set creation scripts that power for the [Missouri COVID-19 Tracking Project](http://slu-opengis.github.io/covid_daily_viz/). These were originally housed in the same [repository](https://github.com/slu-openGIS/covid_daily_viz) as the data visualization code, but have been separated as part of the conversion of the original code into a more modular, better documented set of resources.

## Data Sources

1. County and state COVID-19 data - the <a href="https://nytimes.com" target="_blank">New York Times'</a> <a href="https://github.com/nytimes/covid-19-data" target="_blank">COVID-19 Project</a>
2. State testing data - the <a href="https://health.mo.gov/living/healthcondiseases/communicable/novel-coronavirus/" target="_blank">Missouri Department of Health and Senior Services</a> for Missouri specific data and the <a href="https://covidtracking.com" target="_blank">COVID Tracking Project</a> for surrounding states
3. State health disparities data - the <a href="https://health.mo.gov/living/healthcondiseases/communicable/novel-coronavirus/" target="_blank">Missouri Department of Health and Senior Services</a>
4. St. Louis area health disparities data - the <a href="https://www.stlouis-mo.gov/covid-19/data/index.cfm" target="_blank">City of St. Louis</a> and <a href="https://stlcorona.com/resources/covid-19-statistics1/" target="_blank">St. Louis County</a>
5. St. Louis area zip code data - the <a href="https://www.stlouis-mo.gov/covid-19/data/index.cfm" target="_blank">City of St. Louis</a> and <a href="https://stlcorona.com/resources/covid-19-statistics1/" target="_blank">St. Louis County</a>
6. St. Louis area hospitalization data - the St. Louis Metropolitan Pandemic Task Force
7. Demographic data - the U.S. Census Bureau's American Community Survey 5-year estimates (2014-2018)

## Included Data
From these raw data, the following core data sets are being generated:

  * `state_full.csv` - State-level data for MO, IL, KS, and OK beginning 2020-01-24
  * `metro_full.csv` - Metro-level data for MO (including portions of metros in IL, KS, and OK) beginning 2020-01-24
  * `county_full.csv` - County-level data for MO, IL, KS, and OK beginning 2020-01-24
  * `zip_stl_city.csv` - St. Louis City ZACTA (zip code) level data beginning 2020-04-01
  * `zip_stl_county.csv` - St. Louis County ZACTA (zip code) leve data beginning 2020-06-01

These data sets use a common set of varible names and are all "long" data. They are used to generate daily snapshots for mapping:

  * `daily_snapshot_mo.geojson` - County-level data for MO
  * `daily_snapshot_mo_xl.geojson` - County-level data for MO along with IL, OK, and KS counties in Missouri's Metropolitain Statistical Areas (MSAs)
  * `daily_snapshot_kc.geojson` - County-level data for MO and KS counties in the Kansas City MSA
  * `daily_snapshot_stl.geojson` - County-level data for MO and IL counties in the St. Louis MSA
  * `daily_snapshot_city_county.geojson` - ZACTA (zip code) data for the City of St. Louis and St. Louis County

There are several additional data sets, including convenience summaries of county-level data for the St. Louis and Kansas City MSAs and separate daily snapshots at the ZCTA-level for City of St. Louis and St. Louis County separately, rather than together.

## Citing This Repository
All data and code here are released under a [CC-BY 4.0 license](LICENSE). Citation details, including a DOI number, will be available via Zenodo soon.
