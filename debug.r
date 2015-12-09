url <- "http://54.152.59.84:8080/LINCS/instances"

.POST <- function(url, body="", query="", rep=0, ...) {
  response <- tryCatch({
    res <- POST(url=url, query=query, body=body, ...);
    # trap the couchbase temporary failure event
    if(is.list(res) && rep < 3 && grepl("Temporary failure", content(res, as='text'))) {
        Sys.sleep(.2 * (rep+1))  
        res <- .POST(url, body=body, query=query, rep+1, ...)
    }
    return(res)
  }, error = function(e) {
    if(rep < 3) {
      Sys.sleep(.2 * (rep+1))
      print(e)
      return(.POST(url, body=body, query=query, rep+1, ...))
    } else {
      return(readRDS(file=paste(path.package("slinky"),"/rds/res400.rds" ,sep="")))
    }
  })          
  response
}