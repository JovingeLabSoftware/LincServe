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


Slinky$methods(calc = function(method = NULL, cluster = NULL) {
  "Calculate zscores and stores them in the document store.
  \\subsection{Parameters}{
  \\itemize{
  \\item{\\code{cluster} An optional cluster object to use for calculations. 
  Each node must have this package installed on it.}
  }}
  \\subsection{Return Value}{None.  Called for side effect of populating 
  document store with zscores}"
  
  if (is.null(method)) stop('You must provide a calculation method...')
  
  inst_count <- 1328047 # TODO: write a REST endpoint to get this info
  
  if(length(cluster)) {
    
    if (!("cluster" %in% class(cluster))) stop('Cluster must be created by snow library...')
    
      # to do: add cluster support
      # still need to work out the best way to do this...

#     chunks <- clusterSplit(cluster, seq_len(inst_count))
#     # split the ids in chunks and
#     switch(method,
#            "ZSVC_L1000_gold" = .self$zvscChemGold(ids)
#     )
    
  } else {
    
    # iterate over the ids sequentially
    ids <- seq_len(inst_count)
    switch(method,
      "ZSVC_L1000_gold" = .self$zvscChemGold(ids)
    )
  }

})


Slinky$methods(zvscChemGold = function(ids) {
  "Calculate zscores for specific instances relative to mean 
  of appropriate vehicle controls on same plate.
  \\subsection{Parameters}{
  \\itemize{
  \\item{\\code{id} Ids of instance for which scores are desired.}
  }}
  \\subsection{Return Value}{None.}"
  
  rest <- .self$.endpoint
  
  # iterate through all passed instances
  for(i in ids) {  
    # TODO: re-implement REST endpoint for this
    if(.self$.checkZ(i)) next
    
    url <- paste0(rest, '/instances/', i)
    res <- .self$.GET(url)
    instance <- rjson::fromJSON(content(res, 'text'))
    
    if (.self$.checkPertGold(instance)) {
      replicates <- .self$.getReplicates(
        pert = instance$metadata$pert_desc, cell = instance$metadata$cell_id, 
        dose = instance$metadata$pert_dose, 
        duration = instance$metadata$pert_time
      )
      
      if (nrow(replicates) > 1) {
        scores <- do.call(cbind, lapply(replicates$id, .self$ZbyPlate))
        gids <- rownames(scores)
        scores <- apply(scores, 1, mean)
        .self$saveZ(doc_type = "ZSVC_L1000_gold", z_scores = scores, instance = instance)
      } else {
        .self$.log(level = "error", message = paste("NOREPS for instance", i))            
      }
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
    exp <- fromJSON(exp)$data
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
      return(x$value$data)
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
  data <- h5read(gctxfile, "0/DATA/0/matrix", index=list(c(1:978), col))
  doclist <- character();
  foreach(i = 1:length(col)) %dopar% {
    res <- .self$.POST(url, body=list('id' = col[i], type="q2norm", metadata = jsonlite::unbox(md[i,]), gene_ids = ids, data=as.vector(data[,i])), 
                       encode = "json", verbose=TRUE)
    if(status_code(res) != 200) {
      .self$.log("error", paste("ERRNOLOAD Failed to load document (col: ", col[i], ")...", content(res, as='text')))
    } else {
      .self$.log("info", paste("OK: loaded document (col: ", col[i], ")..."))
      doclist <- c(doclist, content(res, as = 'parsed'))
    }
  }
  doclist
})


Slinky$methods(saveZ = function(doc_type, z_scores, instance) { 
#   "Save the calculated z-scores to CouchBase via the REST API given a set of 
#   relative expression values, a \\code{type} of document to store the scores
#   as, and the \\code{list} representation of an \\code{q2norm} instance.
#   \\subsection{Parameters}{
#   \\itemize{
#   \\item{\\code{doc_type} The \code{type} of document you'd like to associate with the saved document.}
#   \\item{\\code{z_scores} A named vector of robust z-scores.}
#   \\item{\\code{instance} A \code{list} representation of an \code{q2norm} instance.}
#   }}
#   \\subsection{Return Value}{id(s) of resulting documents in doc store.}"
  
  if (missing(doc_type)) stop('You must provide a document type when saving z-scores.')
  if (missing(z_scores)) stop('You must provide z-scores when saving z-scores.')
  if (missing(instance)) stop('You must provide instance when saving z-scores.')
  
  # From the REST documentation:
  #   perturbagen	String name of perturbagen
  #   dose numeric dose (unitless)
  #   duration numeric duration (unitless)
  #   cell String cell line used
  #   method String calculation method used, e.g. "zsvc_plate"
  #   gold boolean is this a gold signature score?
  #   gene_ids [String] from lincs
  #   data [Numeric] the scores (one per gene)
  
  url <- paste(.self$.endpoint, "/pert", sep="")
  query <- list(
    perturbagen = jsonlite::unbox(instance$metadata$pert_desc),
    dose = jsonlite::unbox(instance$metadata$pert_dose),
    duration = jsonlite::unbox(instance$metadata$pert_time),
    cell = jsonlite::unbox(instance$metadata$cell_id),
    method = jsonlite::unbox(doc_type), 
    gold = jsonlite::unbox(instance$metadata$is_gold),
    gene_ids = instance$gene_ids,
    data = z_scores
  )

  res <- .self$.POST(url = url, body = query, encode = "json", verbose = TRUE)

  if (res$status_code != 200L) {
    .self$.log("error", paste("ERR failed to save zscores for instance", instance$metadata$cell_id, instance$metadata$pert_desc, instance$metadata$pert_dose, instance$metadata$pert_time))
  } else {
    .self$.log("info", paste("OK saved zscores for", instance$metadata$cell_id, instance$metadata$pert_desc, instance$metadata$pert_dose, instance$metadata$pert_time))
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




Slinky$methods(.checkPertGold = function(instance) {
  "Checks to see if an instance was treated by a chemical perturbagen and `is_gold`.
  Takes a `list` representation of a `q2norm` document created from `rjson` and checks 
  the `metadata` slot.
  \\subsection{Parameters}{
  \\itemize{
  \\item{\\code{instance} a `list` representation of a `q2norm` document}
  }}
  \\subsection{Return Value}{`TRUE`/`FALSE`}"
  
  isok <- TRUE
  if (!length(instance$metadata$pert_desc) || is.na(instance$metadata$pert_desc)) {
    .self$.log("warn", paste("NODESC (no description)", 
                             instance$metadata$cell_id, 
                             instance$metadata$pert_desc, 
                             instance$metadata$pert_dose, 
                             instance$metadata$pert_time))            
    isok <- FALSE;
  } else if (instance$metadata$pert_type != "trt_cp" || instance$metadata$pert_desc == "-666") {
    # to do: support perturbagens with only BRD id and no description
    .self$.log("warn", paste("NOCHEM (not a chemical perturbagen, treatment type", instance$metadata$pert_type, ")", 
                             instance$metadata$cell_id, 
                             instance$metadata$pert_desc, 
                             instance$metadata$pert_dose, 
                             instance$metadata$pert_time))            
    isok <- FALSE;
  } else if (!instance$metadata$is_gold) {  
    # above is hacking around issue of "true" vs. true in metadata
    .self$.log("warn", paste("NOGOLD (instance not gold)", 
                             instance$metadata$cell_id, 
                             instance$metadata$pert_desc, 
                             instance$metadata$pert_dose_unit, 
                             instance$metadata$pert_time))            
    isok <- FALSE;
  }
  return(isok)
})



# TODO: patch this when endpoint exists again
#
# .checkZ (private)
#  See if a zscore document already exists
#
#
Slinky$methods(.checkZ = function(i) {
  return(FALSE)
  
  exists = FALSE;
  url <- paste(.self$.endpoint, "/zscores/", i, "/exists", sep="")
  res <- .self$.GET(url);
  tryCatch({
    exists <-  fromJSON(gsub('"', '', content(res, type = 'text')))
  }, error = function(e) {
    .self$.log("error", paste("EXCHECK (unknown error on checking for existance)", e, "id:", i))
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
  query <- list(pert = pert, cell = cell, dose = dose, 
                duration = duration, is_gold = gold, limit = 10000)
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
    write(message, file=.self$logfile, append=TRUE)
  }
})


#
# .GET (private method)
# Simple wrapper around httr GET to facilitate error trapping, retries, and logging
#
Slinky$methods(.GET = function(url, rep=0, ...) {
  response <- tryCatch({
    res <- GET(url=url, ...);
    # trap the couchbase temporary failure event
    if(is.list(res) && rep < 3 && grepl("Temporary failure", content(res, as='text'))) {
      Sys.sleep(1 * (rep+1))  
      res <- .GET(url, rep+1, ...)
    }
    return(res)
  }, error = function(e) {
    if(rep < 3) {
      Sys.sleep(.2 * (rep+1))
      print(e)
      return(.GET(url, rep+1, ...))
    } else {
      return(readRDS(file=paste(path.package("slinky"),"/rds/res400.rds" ,sep="")))
    }
  })          
  response
})


#
# .POST (private method)
# Simple wrapper around httr POST to facilitate error trapping, retries, and logging
#
Slinky$methods(.POST = function(url, body="", query="", rep=0, ...) {
  response <- tryCatch({
    res <- POST(url=url, query=query, body=body, ...);
    # trap the couchbase temporary failure event
    if(is.list(res) && rep < 3 && grepl("Temporary failure", content(res, as='text'))) {
      if(!.self$silent) print("Temporary failure...pausing a momment then will retry")
      Sys.sleep(.2 * (rep+1))  
      res <- .POST(url, body=body, query=query, rep+1, ...)
    }
    return(res)
  }, error = function(e) {
    if(rep < 3) {
      Sys.sleep(1 * (rep+1))
      print(e)
      return(.POST(url, body=body, query=query, rep+1, ...))
    } else {
      return(readRDS(file=paste(path.package("slinky"),"/rds/res400.rds" ,sep="")))
    }
  })          
  response
})

