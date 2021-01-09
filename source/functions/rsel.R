#' 
#' This function is used to open and close the RSelenium driver
#' 

open_rsel <- function(){
  
  rD <<- RSelenium::rsDriver(
    port = 4445L,
    version = 'latest',
    browser = "firefox",
    # browser = c("chrome", "firefox", "phantomjs", "internet explorer"),
    # chromever = '87.0.4280.88',
    phantomver = "2.1.1",
    verbose = F,
    # extraCapabilities = list(
    #  chromeOptions = list(
    #    args = c('--headless','--disable-gpu', '--window-size=1280,800'),
    #    prefs = list(
    #      "profile.default_content_settings.popups" = 0L,
    #      "download.prompt_for_download" = FALSE,
    #      "download.default_directory" = getwd()
    #    )
    #  )
    # )
  )
  remDr <<- rD$client
}

close_rsel <- function(){
  
  # closing window and stopping server
  if(exists("remDr")|exists("rD")){
    remDr$close()
    rD$server$stop()
  }
    
  # cleanup
  objs <- ls(pos = ".GlobalEnv")
  rm(list = objs[grep("rD|remDr", objs)], pos = ".GlobalEnv")
  invisible(gc())
  
  # For Windows machines:
  if(.Platform$OS.type == "windows"){
    system("taskkill /im java.exe /f", intern=FALSE, ignore.stdout=FALSE)
  }
}
