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


Slinky$methods(getInstanceData = function(ids, type="q2norm") {
  "Retrieve instance data for multiple distil_ids. Uses the POST interface of the 
  REST API to avoid query string length restriction for GET queries, enabling
  retrieval of large(r) datasets.
  \\subsection{Parameters}{
  \\itemize{
  \\item{\\code{ids} distil_ids for which data is desired.}
  \\item{\\code{type} which data type you want to return.  Default is
                      q2norm, other options may include zsvc and zspc
  }
  }}
  \\subsection{Return Value}{Dataframe containing the requested data}"
  
  if(type == "q2norm") type <- "data" # should fix this with future data upload
  url <- paste(.self$.endpoint, "/instances/distil_id", sep="")
  query <- list(
    ids = ids,
    fields = c("metadata.distil_id", type, "gene_ids")
  )
  res <- content(.self$.POST(url = url, body = query, encode = "json"))
  data <- do.call(cbind, lapply(res, .self$.extract, type))
  colnames(data) <- sapply(res, .self$.extract, "distil_id")
  rownames(data) <- res[[1]]$gene_ids
  data
})


Slinky$methods(getInstance = function(ids) {
  "Retrieve instances in their entirety including all data and metadata.
  Uses the POST interface of the REST API to avoid query string length 
  restriction for GET queries, enabling retrieval of large(r) datasets.
  \\subsection{Parameters}{
  \\itemize{
  \\item{\\code{ids} distil_ids for which data is desired.}
  }
  }}
  \\subsection{Return Value}{Instances in list format}"
  
  url <- paste(.self$.endpoint, "/instances/distil_id", sep="")
  query <- list(
    ids = ids
  )
  content(.self$.POST(url = url, body = query, encode = "json"))
})

Slinky$methods(query = function(q, f=NA, l=NA, s=NA) {
  "Retrieve metadata using the query interface of the REST API. 
  \\subsection{Parameters}{
  \\itemize{
  \\item{\\code{q} query terms as field=value pairs in the form of a list.  Value
         may be a single value or a vector of values.  Fields are assumed to be 
         within the metadata slot of the data, so there is no need to prefix fields 
         with 'metadata.', although it is allowed.  This also means query is restricted
         to the metadata (i.e. you cannot query based on gene_ids or doctype).}
  \\item{\\code{f} vector of fields to return.  Defaults to '*'.  Note here subfields
                   (e.g. metdata.pert_desc) must be explicit as top level fields (e.g. data)
                   can also be returned
  \\item{\\code{l} limit, for paging (number of documents to return, default is everything)
  \\item{\\code{s} skip, for paging (default in 0)
  }}
  \\subsection{Return Value}{List with metadata and data (gene expression) components}"

  if(is.na(f)) f = c("data", "gene_ids", "metadata.*", "doctype")
  if("data" %in% f && !"gene_ids" %in% f) f = c(f, "gene_ids")
  url <- paste(.self$.endpoint, "/instances", sep="")
  query <- paste("q=", jsonlite::toJSON(q), sep="")
  query <- paste(query, "&f=", jsonlite::toJSON(f), sep="")
  if(!is.na(l)) query <- paste(query, "&l=", l, sep="")
  if(!is.na(s)) query <- paste(query, "&s=", s, sep="")

  res <- content(.self$.GET(url = url, query = query, encode="json"))
  data <- NULL
  ids <- .self$.extract(res[[1]], "gene_ids")
  metadata <- NULL
  names <- names(res[[1]])
  if("gene_ids" %in% names || "data" %in% names)
       names <- names[-which(names %in% c("gene_ids", "data"))]

  fd <- function(x) {
    return(.self$.extract(x, "data"))
  }
  data <- do.call(cbind, lapply(res, fd))
  
  fm <- function(x, nm) {
    as.data.frame(x[nm])
  }
  metadata <- do.call(rbind, lapply(res, fm, nm = names))

  # this seems to be resulting in errors with strange metadata returned...  
#   for(i in 1:length(res)) {
#     row = NULL;
#     for(n in names(res[[i]])) {
#         if (n != "gene_ids" && n != "data") {
#         row = c(row, .self$.extract(res[[i]], n))
#       }
#     }
#     metadata <- rbind(metadata, row)
#   }
  # metadata <- as.data.frame(metadata, stringsAsFactors=F) # handle single row case
  # rownames(metadata) <- NULL
  # colnames(metadata) <- names
  
  data <- as.data.frame(data)
  rownames(data) <- ids
  colnames(data) <- metadata$distil_id
  return(list(metadata=metadata, data=data))
})


Slinky$methods(calc = function(filter = NULL, cores = NULL, cluster = NULL) {
  "Calculate zscores and stores them in the document store. Future versions will 
   allow users to specify a \\code{filter} statement to only compute a subset of
   scores
  \\subsection{Parameters}{
  \\itemize{
  \\item{\\code{cluster} An optional cluster object to use for calculations. 
  Each node must have this package installed on it.}
  }}
  \\subsection{Return Value}{None.  Called for side effect of populating 
  document store with zscores}"

  
  # TODO: allow for some filtering options -- compute for all 
  if(!exists('metadata')) {
    data("metadata")
  }
  
  # filter for certain plates based on filter statement
  metadata <- filter(metadata, pert_desc != "-666")
  
  # i actually think it would be fastest to compute all z-scores for a single 
  # plate at the same time; then we only pull the plate data once
  plates <- unique(metadata$det_plate)
  
  if (is.null(cores) & is.null(cluster)) {
    message("Running calculations serially. Specify cores or cluster to run in parallel...")
  } else if (!is.null(cluster)) {
    if (!("cluster" %in% class(cluster))) stop('Cluster must be created by snow library...')
    registerDoSNOW(cluster)
    clusterCall(cluster, function() library(slinky))
    clusterExport(cluster, list = c('.self', 'plates'), envir=environment())
  } else if (!is.null(cores)) {
    registerDoMC(cores)
  }
  
  if (getDoParWorkers() > 1) {
    chunks <- split(plates, cut(seq_along(plates), getDoParWorkers()))
  } else {
    chunks <- list(plates)
    message('Processing serially')
  }
  
  foreach (j = chunks) %dopar% {
    for (p in j)  {
      plate_data <- .self$query(q = list(det_plate = p))
      .self$.zspc(plate_data)
      .self$.zsvc(plate_data)
    }
  }

})


Slinky$methods(.zspc = function(plate_data) {

  # compute robust z-scores using all samples on plate
  # robust z-score description
  # http://support.lincscloud.org/hc/en-us/articles/202099616-Signature-Generation-and-Analysis-L1000-
  rbz <- function(x) (x - median(x)) / (mad(x) * 1.4826)
  norm_exprs <- apply(plate_data$data, MARGIN = 1, FUN = rbz)
  stopifnot(all(rownames(norm_exprs) == plate_data$metadata$distil_id))
  
  # append z-scores for each of our treated samples with known pert_descs
  for (i in 1:nrow(plate_data$metadata)) {
    if (grepl('^trt', plate_data$metadata$pert_type[i]) & plate_data$metadata$pert_desc[i] != '-666') {
      if (.self$append(id = plate_data$metadata$distil_id[i], data = norm_exprs[i, rownames(plate_data$data)], type = "ZSPC")) {
        .self$.log("info", paste("OK saved ZSPC scores for", plate_data$metadata$distil_id[i]))
      } else {
        .self$.log("error", paste("ERR failed to save ZSPC scores for", plate_data$metadata$distil_id[i]))
      }
    }
  }
})


Slinky$methods(.zsvc = function(plate_data, .self) {

  # these are the two types of controls we are interested in using
  ct_types <- c('ctl_vector', 'ctl_vehicle')
  ct_sel <- which(plate_data$metadata$pert_type %in% ct_types)
  
  # copy eric's original z-score implementation for now
  if (length(ct_sel)) {
    ctrl.m <- apply(plate_data$data[, ct_sel], 1, mean)
    for (i in 1:nrow(plate_data$metadata)) {
      if (grepl('^trt', plate_data$metadata$pert_type[i]) & plate_data$metadata$pert_desc[i] != '-666') {
        fc <- log2(plate_data$data[,i] / ctrl.m)
        fc <- (fc - median(fc)) / mad(fc)
        if (.self$append(id = plate_data$metadata$distil_id[i], data = fc, type = "ZSVC")) {
          .self$.log("info", paste("OK saved ZSVC scores for", plate_data$metadata$distil_id[i]))        
        } else {
          .self$.log("error", paste("ERR failed to save ZSVC scores for", plate_data$metadata$distil_id[i]))
        }
      }
    }
  } else {
    .self$.log("error", paste("No controls found on plate", plate_data$metadata$det_plate[1]))
  }
})



Slinky$methods(append = function(id, data, type) {
  "Append data to an instance.  DATA MUST HAVE THE SAME NUMBER OF ROWS AS PRE-EXISTING
   gene_ids, AND BE IN THE SAME ORDER! 
  \\subsection{Parameters}{
  \\itemize{
  \\item{\\code{id} The distil_id of the doc to which to append.}
  \\item{\\code{data} The data to append.}
  \\item{\\code{type} The type of data.  This will be the name of the new top level field to which 
        the data is saved.  E.g. 'zsvc' or 'zspc'}
  }}
  \\subsection{Return Value}{List with metadata and data (gene expression) components}"
  doc <- .self$getInstance(id)[[1]]
  doc[[type]] <- data
  url <- paste(.self$.endpoint, "/instances", sep="")
  res <- .self$.POST(url, body=doc, encode = "json", verbose=TRUE)
  return(status_code(res) == 200)
})


Slinky$methods(getData = function(cols) {
  #   "Get a subset if sample ids based on metadata.  Returns vector of \\code{distil_ids}
  #   relative expression values, a \\code{type} of document to store the scores
  #   \\subsection{Parameters}{
  #   \\itemize{
  #   \\item{\\code{field} Which field of metadata to search?}
  #   \\item{\\code{value} What value to search on?  Uses grep so knock yourself out.}
  #   \\item{\\code{cols} Want to subset a subset?  Just provide an initial set of cols to start with.
  #                      Default is all columns. }
  #   }}
  #   \\subsection{Return Value}{distil_id(s) of resulting instances.}"
  
  if(!exists('metadata')) {
    data("metadata")
  }
  if(typeof(cols) != "character") {
    cols <- metadata$distil_id[]
  }
  if(!length(cols)) {
    cols <- 1:nrow(metadata)
  } else {
    if(class(cols) == "character")
      cols <- which(metadata$distil_id %in% cols)
  }
  ix <- grep(value, metadata[cols, field])
  return(metadata$distil_id[cols[ix]])  
})



#----------------------------------------------------------------------------------------------------------------------
#
#  ETL UTILITY FUNCTIONS (should probably move this somewhere else someday)
#
#

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





#----------------------------------------------------------------------------------------------------------------------
#
# private functions below
#

#
# .checkParam (private)
#  Verify applicable instance by parameters (i.e., perturbagen treated, gold instance)
#
#
Slinky$methods(.checkParam = function(param, check_gold = FALSE) {
  isok <- TRUE;
  if(length(param$pert_desc) == 0 || is.na(param$pert_desc)) {
    .self$.log("warn", paste("NOpert_desc (no pert_description)", 
                             param$cell_id, param$pert_desc, param$pert_dose, param$pert_time))            
    isok <- FALSE;
  } else if (param$pert_type != "trt_cp" || param$pert_desc == "-666") {
    # to do: support perturbagens with only BRD id and no pert_description
    .self$.log("warn", paste("NOCHEM (not a chemical perturbagen, treatment type", param$pert_type, ")", 
                             param$cell_id, param$pert_desc, param$pert_dose, param$pert_time))            
    isok <- FALSE;
  } else if (check_gold) {
    if (param$is_gold) {  
      # above is hacking around issue of "true" vs. true in metadata
      .self$.log("warn", paste("NOGOLD (instance not gold)", 
                               param$cell_id, param$pert_desc, param$pert_dose, param$pert_time))            
      isok <- FALSE;
    }
  }
  return(isok)
})



# TODO: patch this when endpoint exists again
#
# .checkZ (private)
#  See if a zscore document already exists
#
#
Slinky$methods(.checkZ = function(id) {
  exists <- FALSE
  q <- sprintf('select Meta().id from LINCS where Meta().id = "%s";', id)
  u <- sprintf("http://%s:8093/query/service", .self$.ip)
  res <- .self$.POST(u, body = list(statement = q), encode = "json", verbose = TRUE)
  tryCatch({
    parsed <- jsonlite::fromJSON(content(res, type = 'text'))
    if (length(parsed$results)) {
      exists <- TRUE
      .self$.log("info", paste("Z-score exists for id:", id))
    }
  }, error = function(e) {
    .self$.log("error", paste("EXCHECK (unknown error on checking for existance)", e, "id:", id))
  })
  return(exists)
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

#
# .extract (private method)
# Collect a specified element from a list, converting to vector as needed
# and return as a singleton.  Used for transforming compound lists into
# dataframes or matrices.
#
# .extract (private method)
# Collect a specified element from a list, converting to vector as needed
# and return as a singleton.  Used for transforming compound lists into
# dataframes or matrices.
Slinky$methods(.extract = function(x, el) {
  if(exists(el, x)) {
    return(unlist(x[[el]]))  
  } else {
    return(NULL)
  }
})
