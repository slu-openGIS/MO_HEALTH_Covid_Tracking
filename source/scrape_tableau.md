# Tableau Dashboard Scraper

## This is a guide for the `get_tableau()` function. It provides instructions on how to get the Tableau dashboard's URL to scrape as well as how to use the function itself.

### **NOTE**: The main thing we need to do is get the tableau URL from the HTML source so it is best to use **Google Chrome** for the best experience. There will also be images to help visualize the process better.

1. Go to a website where it is displaying the Tableau dashboard. There will usually be a watermark on the bottom of the dashboard.

2. Inspect the page source by hitting **CTRL+SHIFT+I** (**CMD+OPTION+I** for Mac)

3. Hit **CTRL+F** (**CMD+F** for Mac) within the page source to look for keywords and type in "*iframe*". 

4. Keep searching through the each match by clicking the "down" arrow next to it until the entire dashboard gets highlighted. It should look something like this: 
    <img src="https://snipboard.io/jTQ5Au.jpg">

5. Within the < iframe > tag, there is a *src* attribute with a URL on it. Double-click the URL to copy it, and open it on a different tab. The URL should **ONLY** display the dashboard and nothing else as shown here:
    <img src="https://snipboard.io/3QdOf9.jpg">

    - **NOTE**: This might not be the case for every dashboard. The **key** thing that is a sure sign that the URL is correct is that there is a "/views/" directory in the URL. Nearly all Tableau dashboards will have this in the URL.
    - Another option is to search for the "views" keyword instead of "iframe" if the iframe tag doesn't provide a URL.

6. Now it is as simple as putting parts of the URL into the `get_tableau()` function. We will get into that in the next section. 

#

# How to use `get_tableau()`

The function takes in four arguments:
- `host`
- `views`
- `n`
- `getWS`

## Getting `host` and `views`:

For the URL acquired from the steps above, it is split into the two arguments, `host` and `views`.
- `host`: starting from the beginning of the URL and ending with ".com". From the example above, it would be `https://results.mo.gov`.
    - **NOTE**: It does not matter if the "*https://*" isn't shown or copied. The function will be able to take the URL with or without it.
- `views`: starting from the forward slash "/" that followed the host url, it is everything down to but not including the "?" of the URL. From the example above, it would be `/t/COVID19/views/COVID-19PublicDashboards/Demographics`.

## Getting Worksheets with `getWS`:

If scraping the dashboard for the first time, or if the dashboard or its link gets updated, it is best to look at the worksheets first. To do so, simply put in: `get_tableau(host="http://some.host", views="/some/views", getWS=TRUE)`.

This will provide worksheets in the console as shown here:
    <img src="https://snipboard.io/omukn4.jpg">

## Acquiring data from Worksheet `n`:
We see several different worksheets that provides data directly from the Tableau dashboard online. From here, to pick a worksheet, simply put the argument `n=` with the worksheet number and remove the `getWS` argument. We will use worksheet 4 to gather total deaths by ethnicity for example: `get_tableau(host="http://some.host", views="/some/views", n=)`. We get the following output: 
    <img src="https://snipboard.io/kTK9qB.jpg">

## Final Notes:

There you have it! Once the data frame is outputted onto the console, you are free to manipulate the data however you want like any other data frame in R. You can rename the titles, append more rows, delete rows, and all sorts of fun stuff with the data we've scraped. Happy scraping and good luck!