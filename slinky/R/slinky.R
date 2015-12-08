#' Slinky Class
#'
#' Make LINCS analysis fun.
#'
#' @name Slinky-class
#' @exportClass Slinky
#' @export Slinky
#' @description A class to facilitate storage and analysis of the level 2 data from the LINCS project.  This 
#' class does not provide any of the data (which must be obtained under individual agreement with 
#' LINCS).  However, once obtained, working with their large binary data files is facilitated 
#' by this class.
#'
#' @field .ip  (Private) IP address of your LINCS REST server, set with setIp. Default is \code{127.0.0.1}.
#' @field .port (Private)  Port of your LINCS REST server, set with setPort. Default is \code{8080}.
#' @field loglevel How much information should we log? Options are \code{all}, 
#'        \code{error}, \code{warn}, \code{none}.  Note that \code{all} or \code{warn} will result in logfile ~120MB in size.
#'        Default is \code{all}.
#' @field logfile Where to store the log.  Default is \code{log.txt}.
#' @field silent Should logging info only be written to file (and not to stdout)?  Default is FALSE.  Irrelevant if \code{loglevel} is \code{none}.
#' @field maxtries If http request fails, how many times should we retry before moving on? Default is \code{3}.
#' @examples
#' lincs <- Slinky$new()
#' lincs$calc()
#'
Slinky <- setRefClass("Slinky",
                      fields = list(.ip = "character",
                                    .port = "character",
                                    .endpoint = "character",
                                    loglevel = "character",
                                    logfile = "character",
                                    silent = "logical",
                                    maxtries = "numeric"),
                      methods = list(
                        withdraw = function(x) {
                          "Withdraw money from account. Allows overdrafts"
                        }
                      )
)

Slinky$methods(initialize = function(ip = '127.0.0.1', port='8080', loglevel = 'all', logfile="log.txt", silent=FALSE, maxtries=3) {
  .self$setIp(ip)
  .self$setPort(port)
  .self$loglevel <<- loglevel
  .self$silent <<- silent
  .self$logfile <<- logfile
  .self$maxtries <<- maxtries
})

Slinky$methods(setIp = function(ip = '127.0.0.1') {
  "Set IP and redefine endpoint
  \\subsection{Parameters}{
  \\itemize{
  \\item{\\code{ip} The IP address of the your LINCS REST server, default is \\code{127.0.0.1}.}
  }}
  \\subsection{Return Value}{none}"
  .self$.ip=ip
  .self$.endpoint = paste("http://", .self$.ip, ":", .self$.port, "/LINCS", sep="")
})

Slinky$methods(setPort = function(port = '8080') {
  "Set port and redefine endpoint
  \\subsection{Parameters}{
  \\itemize{
  \\item{\\code{port} The port of the your LINCS REST server, default is \\code{8080}.}
  }}
  \\subsection{Return Value}{none}"
  .self$.port = port;
  .self$.endpoint = paste("http://", .self$.ip, ":", .self$.port, "/LINCS", sep="")
})

Slinky$methods(calc = function(cluster = NULL) {
  "Calculate zscores and stores them in the document store.
  \\subsection{Parameters}{
  \\itemize{
  \\item{\\code{cluster} An optional cluster object to use for calculations. 
  Each node must have this package installed on it.}
  }}
  \\subsection{Return Value}{None.  Called for side effect of populating 
  document store with zscores}"
  rest <- .self$.endpoint
  count <- 1
  range <- content(.self$.GET(paste(rest, "/nidrange", sep="")))
  step <- floor((range$max - range$min) / 20000);
  
  if(length(cluster)) {
    # to do: add cluster support
  }
  
  for(i in seq(0, range$max, step)) {  # process this chunk of instances
    url <- paste(rest, "/summaries/nid?first=", i, "&last=", i+step, sep="")
    res <- .self$.GET(url, query=list(first=i, last=i+step));
    
    data <- tryCatch({.self$.summaryToDF(content(res, as = 'text'))}, error = function(e) { 
      .self$.log("error", paste("NODATA: Could not parse summary", content(res, as='text')), count)
      next()
    })  
    
    for(ii in 1:nrow(data)) { # process each instance
      param = data[ii,]
      if(!.self$.checkParam(param)) next
      # else ...
      id <- paste(param$cell, gsub("/", "", param$desc), param$dose, param$time, "ZSVC_L1000", "1.0", sep="_")
      if(!.self$.checkZ(id)) {  
        instances <- .self$.getReplicates(pert = param$desc, cell = param$cell, dose = param$dose, duration = param$time)
        if(length(instances) > 1) {
          scores <- do.call(cbind, lapply(instances$id, .self$ZbyPlate))
          gids <- rownames(scores)
          scores <- apply(scores, 1, mean)
          saveDoc(param$cell, param$desc, param$dose, param$time, gids, scores, "ZSVC_L1000", "1.0", "true")            
          .self$.log("info", paste("OK saved zscores for", param$cell, param$desc, param$dose, param$time), count)            
        } else {
          .self$.log("error", paste("NOREPS for instance", param$cell, param$desc, param$dose, param$time), count)            
        }
      } else {  
        .self$.log("warn", paste(": WARN EXISTS (already exists) for", param$cell, param$desc, param$dose, param$time), count)            
      }            
      count <- count+1;
    }      
  }  
})


Slinky$methods(ZbyPlate = function(id) {
  "Calculate zscores for specific instance relative to mean 
  of appropriate vehicle controls on same plate.
  \\subsection{Parameters}{
  \\itemize{
  \\item{\\code{id} Id of instance for which scores are desired.}
  }}
  \\subsection{Return Value}{Vector containing robust z-scores for each gene.}"
  
  ctrl <- .self$getPlateControls(id)
  ctrl.m <- apply(ctrl, 1, mean)
  fc <- NULL
  tryCatch({
    url <- paste(.self$.endpoint, "/instances/", id, sep="")
    exp <- .self$.GET(url)
    exp <- gsub('\"', '"', content(exp, "text")) # need to get rid of escapes 
    geneids <- fromJSON(exp)$gene_ids
    exp <- fromJSON(exp)$norm_exp
    fc <- log2(exp/ctrl.m)
    fc <- (fc - median(fc)) / mad(fc)
    names(fc) <- geneids
    fc
  }, error = function(e) {
    print(e)
    .self$.log("error", paste("NOCALC: encountered error when calculating z-scores for", id, ":", e))
  })          
  fc
})

Slinky$methods(getPlateControls = function(id) {
  "Fetch normalized expression data for control samples from same plate as id
  and treated only with the vehicle used for sample id.
  \\subsection{Parameters}{
  \\itemize{
  \\item{\\code{id} Id of instance for which control data is desired.}
  }}
  \\subsection{Return Value}{dataframe containing normalized gene expression
  for controls.}"
  veh <- .self$.GET(paste(.self$.endpoint, "/instances/", id, "/controls", sep=""))
  if(length(veh)) {
    veh <- gsub('\"', '"', content(veh, "text")) # need to get rid of escapes 
    veh <- fromJSON(veh)
    f <- function(x) {
      return(x$value$norm_exp);
    }
    return(do.call(cbind, lapply(veh, f)))
  } else {
    return(NULL)
  }
})

Slinky$methods(loadAll2 =function(nodes = 4, chunks=1000) {    
  ii <- 1:1328098
  chunks <- split(ii, ceiling(seq_along(ii)/chunks))
  registerDoMC(nodes)
  
  for(i in 1:length(chunks)) {
    .self$loadLevel2(col=chunks[[i]])
  }
})

Slinky$methods(loadLevel2 = function(gctxfile = "/mnt/lincs/q2norm_n1328098x22268.gctx", col) {
  "Load data for specified column(s) from hdf5 formatted file (.gctx) from LINCS Fetch 
  into your document store via RESTful interface.  Metadata will be matched from metadata
  object included in this package and added to resulting document. 
  \\subsection{Parameters}{
  \\itemize{
  \\item{\\code{gctxfile} Path to level 2 gctx file. Default is \\code{./q2norm_n1328098x22268.gctx}.}
  \\item{\\code{col} Column(s) of data to load from gctx file.}
  }}
  \\subsection{Return Value}{id(s) of resulting documents in doc store.}"
  
  if(!exists('metadata')) {
    data("metadata")
  }
  
  
  url <- paste(.self$.endpoint, "/instances", sep="")
  ids <- h5read(gctxfile, "/0/META/ROW/id", index=list(c(1:978)))
  ids <- gsub(" ", "", ids)
  colids <- h5read(gctxfile, "/0/META/COL/id", index=list(col))
  colids <- gsub(" ", "", colids)
  ix <- match(colids, metadata[,1])
  md <- metadata[ix,]
  doc <- list();
  doc_ids = character(0)
  data <- h5read(gctxfile, "0/DATA/0/matrix", index=list(c(1:978), col))
  foreach(i = 1:length(col)) %dopar% {
    print(i)
    res <- POST(url, body=list('id' = col[i], type="q2norm", metadata = md[i,], gene_ids = ids, data=as.vector(data[,i])), 
                encode = "json", verbose=TRUE)
    if(status_code(res) != 200) {
      .self$.log("error", paste("Failed to load document (col: ", col[i], ")...", content(res, as='text')))
    } 
  }
})


#----------------------------------------------------------------------------------------------------------------------
#
# private functions below
#

#
# .checkParam (private)
#  Verify applicable instance by parameters (i.e., perturbagen treated, gold instance)
#
#
Slinky$methods(.checkParam = function(param) {
  isok <- TRUE;
  if(length(param$desc) == 0 || is.na(param$desc)) {
    .self$.log("warn", paste("NODESC (no description)", 
                             param$cell, param$desc, param$dose, param$time))            
    isok <- FALSE;
  } else if(param$type != "trt_cp" || param$desc == "-666") {
    # to do: support perturbagens with only BRD id and no description
    .self$.log("warn", paste("NOCHEM (not a chemical perturbagen, treatment type", param$type, ")", 
                             param$cell, param$desc, param$dose, param$time))            
    isok <- FALSE;
  } else if(as.character(param$gold) == "FALSE") {  
    # above is hacking around issue of "true" vs. true in metadata
    .self$.log("warn", paste("NOGOLD (instance not gold)", 
                             param$cell, param$desc, param$dose, param$time))            
    isok <- FALSE;
  }
  return(isok)
})

#
# .checkZ (private)
#  See if a zscore document already exists
#
#
Slinky$methods(.checkZ = function(id) {
  exists = FALSE;
  url <- paste(.self$.endpoint, "/zscores/", id, "/exists", sep="")            
  res <- .self$.GET(url);
  tryCatch({
    exists <-  fromJSON(gsub('"', '', content(res, type = 'text')))
  }, error = function(e) {
    .self$.log("error", paste("EXCHECK (unknown error on checking for existance)", e, "id:", id))
  })
  return(exists > 0)
})


#
# .getReplicates (private)
#  get replicate instances based on cell line, dose, duration and (optionally) gold status
#
#  return list of matching instance ids
Slinky$methods(.getReplicates = function(pert, 
                                         cell, 
                                         dose, 
                                         duration, 
                                         gold=TRUE) { 
  query <- list(pert = pert, cell=cell, dose=dose, duration=duration, gold=gold, limit=10000)
  res <- .self$.GET(paste(.self$.endpoint, "/instances", sep=""), query=query)
  ids <- NULL    
  tryCatch({
    data <- gsub('\"', '"', content(res, "text")) # need to get rid of escapes
    ids <- data %>% 
      gather_array %>% 
      spread_values(id = jstring("id")) %>%
      select(id)
  }, error = function(e) {
    print(e)
    .self$.log("error", paste("NOREPS for instance:", pert, cell, dose, duration, "with data", data))
  })            
  ids
})

#
# .summaryToDF (private)
#  Parse JSON from REST server to extract dataframe of useful metadata
#  for set of documents
#
#  return dataframe continue summary info for multiple instances
Slinky$methods(.summaryToDF = function(json) {
  data <- gsub('\"', '"', json) # need to get rid of escapes
  data <- data %>% 
    gather_array %>% 
    spread_values(id = jstring("id")) %>%
    enter_object("summary") %>%
    spread_values(
      cell = jstring("cell_id"),
      desc = jstring("pert_desc"),
      type = jstring("pert_type"),
      dose = jnumber("pert_dose"),
      time = jnumber("pert_time"),
      vehicle = jstring("pert_vehicle"),
      gold = jlogical("is_gold")
    ) %>%
    select(id, desc, type, cell, dose, time, vehicle, gold)
  data  
})


#
# .log (private)
# Rudimentary logging
#
Slinky$methods(.log = function(level, message, line = NULL) {
  if( (level == "error" && .self$loglevel != "none") || 
        (level == "warn" && .self$loglevel %in%  c("all", "warn")) ||
        (level == "info" && .self$loglevel == "all") ) {    
    msg <- paste(line, toupper(level), ":", message)
    if(!.self$silent) print(msg)
    write(line, file=.self$logfile, append=TRUE)
  }
})


#
# .GET (private method)
# Simple wrapper around httr GET to facilitate error trapping, retries, and logging
#
Slinky$methods(.GET = function(url, rep=0, ...) {
  res <- NULL
  tryCatch({
    res <- GET(url, ...);
  }, error = function(e) {
    if(rep < .self$maxtries) {
      .self$.log('info', paste("NO RESPONSE FROM SERVER: RETRYING GET FROM:", url))
      Sys.sleep(.2)
      return(.self$.GET(url, rep+1, ...))
    } else {
      .self$.log('error', paste("NO RESPONSE FROM SERVER: FAILED:", url))
    }
  })          
  res
})


#
# .POST (private method)
# Simple wrapper around httr POST to facilitate error trapping, retries, and logging
#
Slinky$methods(.POST = function(url, query, rep=0, ...) {
  res <- NULL
  tryCatch({
    res <- POST(url, query, ...);
  }, error = function(e) {
    if(rep < .self$maxtries) {
      .self$.log('info', paste("NO RESPONSE FROM SERVER: RETRYING POST TO:", url))
      Sys.sleep(.2)
      return(.self$.POST(url, query, rep+1, ...))
    } else {
      .self$.log('error', paste("NO RESPONSE FROM SERVER: FAILED:", url))
    }
  })          
  res
})

