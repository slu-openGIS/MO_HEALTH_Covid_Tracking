README.txt

Functions:

get_ltc_data(): Accepts state and uuid variable. Usus "jsonlite" library to retrieve ltc data in increments of 1500. Data is concatenated and returned as a single dataframe.

concat_ltc_data(): Accepts uuid variable. Repeatedly calls get_ltc_data() with various states, combines each state's dataframe into a single variable, and writes said variable to csv.

pull_data(): Accepts no variable. Fetches curent ltc uuid using an XHR scrape (details below). The most recent uuid is checked against the previously used uuid (stored as a rds file for speed), if the uuids are the same (implying the data has not changed), the function does nothing. If the uuids are different (meaning the data has been updated), then concat_ltc_data() is called to create an updated csv file.

XHR scraping notes: When dealing with the javascript heavy page, I spent many months struggling to access the dataset specific uuid. The following process is how I managed to access the raw uuid for scraping.
- Inspect the nursing home webpage, either through shortcut or right clicking and selecting inspect.
- Navigate to the network tab of inspect.
- Refresh the page, during this refresh the network tab will record all outgoing calls used to create the webpage.
- Near the top, select Fetch/XHR. XMLHttpRequest (XHR) is a JavaScript API to create AJAX requests. Its methods provide the ability to send network requests between the browser and a server. In this case the requests are used to move the information used to populate the JavaScript tables. 
- I manually examined each XHR request shown in the network tab until I located a call to a static url "https://data.cms.gov/data-api/v1/slug?path=%2Fcovid-19%2Fcovid-19-nursing-home-data", which stores the current uuid.
- The XHR source is in a basic text format and easily parsable.
