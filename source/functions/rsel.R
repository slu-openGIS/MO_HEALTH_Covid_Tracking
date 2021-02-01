#' 
#' This function is used to open and close the RSelenium driver
#' 

open_rsel <- function(headless){
  
  if (headless == T){
    rD <<- RSelenium::rsDriver(
      port = 4445L,
      version = 'latest',
      browser = c("chrome", "firefox", "phantomjs", "internet explorer"),
      chromever = '88.0.4324.96',
      phantomver = "2.1.1",
      geckover = "latest",
      verbose = F,
      extraCapabilities = list(
        chromeOptions = list(
          args = c('--headless','--disable-gpu', '--window-size=1280,800'),
          prefs = list(
            "profile.default_content_settings.popups" = 0L,
            "download.prompt_for_download" = FALSE,
            "download.default_directory" = getwd())))
    )
  } else {
    rD <<- RSelenium::rsDriver(
      port = 4445L,
      version = 'latest',
      browser = c("chrome", "firefox", "phantomjs", "internet explorer"),
      chromever = '88.0.4324.96',
      phantomver = "2.1.1",
      geckover = "latest",
      verbose = F
    )
  }
  
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
