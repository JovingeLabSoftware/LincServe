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


Slinky$methods(calc = function(method = NULL, cores = NULL, cluster = NULL) {
  "Calculate zscores and stores them in the document store.
  \\subsection{Parameters}{
  \\itemize{
  \\item{\\code{cluster} An optional cluster object to use for calculations. 
  Each node must have this package installed on it.}
  }}
  \\subsection{Return Value}{None.  Called for side effect of populating 
  document store with zscores}"
  
  if (is.null(method)) stop('You must provide a calculation method...')
  
  if (is.null(cores) & is.null(cluster)) {
    message("Running calculations serially. Specify cores to run in parallel...")
  } else if (!is.null(cluster)) {
    if (!("cluster" %in% class(cluster))) stop('Cluster must be created by snow library...')
    registerDoSNOW(cluster)
    clusterEvalQ(cluster, library(slinky))
    clusterExport(cluster, ls())
  } else if (!is.null(cores)) {
    registerDoMC(cores)
  }
  
  if (!exists('metadata')) {
    data("metadata")
  }
  metadata$key <- paste(metadata$cell_id, metadata$pert_desc, metadata$pert_dose, metadata$pert_time, sep = "_")
  
  # choose which calculation we want, filter the "keys" we need to compute signatures for
  switch(method,
         "zvscChem" = {
           
         },
         "zvscSh" = {
           
         },
         "zspc" = {
           subber <- filter(metadata, pert_desc != "-666")
           keys <- unique(subber$key)
           .self$zspc(keys, meta = subber) 
         }
  )

})


Slinky$methods(zvscChem = function(ncores = 5, cluster = NULL) {
  "Calculate zscores for specific instances relative to mean 
  of appropriate vehicle controls on same plate.
  \\subsection{Parameters}{
  \\itemize{
  \\item{\\code{id} Ids of instance for which scores are desired. Should be monotonically increasing.}
  }}
  \\subsection{Return Value}{None.}"
  
  # smart way: use the metadata to fine the minimal set of z-scores
  # you need to compute
  if(!exists('metadata')) {
    data("metadata")
    metadata$key <- paste(metadata$cell_id, metadata$pert_desc, metadata$pert_dose, metadata$pert_time, sep = "_")
  }
  subber <- metadata[,c('pert_desc', 'cell_id', 'pert_dose', 'pert_time')]
  subber <- metadata[!duplicated(subber),]
  
  foreach (i = 1:nrow(subber)) %dopar% {
    
    if (i %% 1000 == 0) .self$.log(level = "info", message = paste("Calculated", i, 'zscores'))
    
    # TODO: re-implement REST endpoint for this
    if(.self$.checkZ(i)) next
    instance <- subber[i, ]
    if (.self$.checkParam(instance)) {
      replicates <- .self$.getReplicates(
        pert = instance$pert_desc, cell = instance$cell_id, 
        dose = instance$pert_dose, 
        duration = instance$pert_time,
        gold = FALSE
      )
      
      if (nrow(replicates) > 1) {
        scores <- do.call(cbind, lapply(replicates$id, .self$ZbyPlate))
        gids <- rownames(scores)
        scores <- apply(scores, 1, mean)
        .self$saveZ(doc_type = "ZSVC_L1000", z_scores = scores, 
                    gene_ids = gids, instance = instance)
      } else {
        .self$.log(level = "error", message = paste("NOREPS for instance", i))
      }
    }
  }
})

Slinky$methods(zvscSh = function(ncores = 5, cluster = NULL) {
  
  # smart way: use the metadata to fine the minimal set of z-scores
  # you need to compute
  if(!exists('metadata')) {
    data("metadata")
    metadata$key <- paste(metadata$cell_id, metadata$pert_desc, metadata$pert_dose, metadata$pert_time, sep = "_")
  }
  
  subber <- filter(metadata, pert_type == 'trt_sh' & pert_desc != "-666")
  subber <- subber[,c('pert_desc', 'cell_id', 'pert_dose', 'pert_time')]
  subber <- subber[!duplicated(subber),]

  foreach (i = 1:nrow(subber)) %dopar% {
    
    if (i %% 1000 == 0) .self$.log(level = "info", message = paste("Calculated", i, 'zscores'))
    
    # TODO: re-implement REST endpoint for this
    instance <- subber[i, ]
    replicates <- .self$.getReplicates(
      pert = instance$pert_desc, cell = instance$cell_id, 
      dose = instance$pert_dose, 
      duration = instance$pert_time,
      gold = FALSE
    )
    
    if (nrow(replicates) > 1) {
      scores <- do.call(cbind, lapply(replicates$id, .self$ZbyPlate, endpoint = "/sh_controls", control_type = 'ctl_vector'))
      gids <- rownames(scores)
      scores <- apply(scores, 1, mean)
      .self$saveZ(doc_type = "ZSVC_L1000", z_scores = scores, 
                  gene_ids = gids, instance = instance)
    } else {
      .self$.log(level = "error", message = paste("NOREPS for instance", i))
    }
  }
})


Slinky$methods(wholePlateZ = function(plate_info) {
  
  # grab plate info from n1ql API endpoint
  q <- sprintf('SELECT metadata FROM LINCS WHERE metadata.det_plate = "%s" AND doctype="LINCS normalized expression"', plate_info$det_plate[1])
  u <- sprintf("http://%s:8093/query/service", .self$.ip)
  res <- .self$.POST(u, body = list(statement = q), encode = "json", verbose = TRUE)
  kk <- jsonlite::fromJSON(content(res, 'text'))
  distils <- kk$results$metadata$distil_id
  # doc_ids <- kk$results$`$1`$id

  # make sure you have q2norm data uploaded for the sample b4 doing all of this
  if (any(plate_info$distil_id %in% distils)) {

    q <- sprintf('SELECT * FROM LINCS WHERE metadata.det_plate = "%s" AND doctype="LINCS normalized expression"', plate_info$det_plate[1])
    u <- sprintf("http://%s:8093/query/service", .self$.ip)
    res <- .self$.POST(u, body = list(statement = q), encode = "json", verbose = TRUE)
    kk <- rjson::fromJSON(content(res, 'text'))
    instances <- kk$results

    f <- function(x) x$LINCS$data; fid <- function(x) x$LINCS$metadata$distil_id; 
    exprs <- do.call(cbind, lapply(instances, f))
    rownames(exprs) <- instances[[1]]$LINCS$gene_ids
    colnames(exprs) <- lapply(instances, fid)

    # robust z-score description
    # http://support.lincscloud.org/hc/en-us/articles/202099616-Signature-Generation-and-Analysis-L1000-
    rbz <- function(x) (x - median(x)) / (mad(x) * 1.4826)
    norm_exprs <- apply(exprs, MARGIN = 1, FUN = rbz)
    ksel <- which(rownames(norm_exprs) %in% plate_info$distil_id)
    return(norm_exprs[ksel, ])
    
  } else {
    .self$.log(
      level = "error", 
      message = paste("Could not find", paste(plate_info$distil_id, collapse = '/'), "on plate", plate_info$det_plate[1])
      )
    return(NULL)
  }
})


Slinky$methods(zspc = function(keys, meta) {

  # if we have a parallel back-end registered, split our instances into chunks
  # to be processed in parallel
  if (is.null(getDoParName())) {
    chunks <- list(keys)
    message('Processing serially')
  } else if (getDoParWorkers() > 1) {
    chunks <- split(keys, cut(seq_along(keys), getDoParWorkers()))
  } else {
    chunks <- list(keys)
    message('Processing serially')
  }

  foreach (j = chunks) %dopar% {
    for (i in j)  {
      
      if (!.self$.checkZ(paste0("ZSPC_L1000_", i))) {
        ki <- filter(meta, key == i) 
        kil <- split(ki, ki$det_plate)
        rep_zs <- do.call(rbind, lapply(kil, .self$wholePlateZ))
        if (length(rep_zs)) {
          if (is.matrix(rep_zs)) {
            agg_z <- apply(rep_zs, MARGIN = 2, FUN = mean)
          } else if (is.vector(agg_z)) {
            agg_z <- rep_zs
          }
          inst <- ki[1, ]
          .self$saveZ(doc_type = "ZSPC_L1000", z_scores = unname(agg_z), 
                      gene_ids = names(agg_z), instance = inst)
        } else {
          .self$.log(
            level = "error", 
            message = paste("Failed to calculate scores for", keys[i], "skipping...")
          )
        }
      }
    }
  }

})

Slinky$methods(ZbyPlate = function(id, ...) {
  "Calculate zscores for specific instance relative to mean 
  of appropriate vehicle controls on same plate.
  \\subsection{Parameters}{
  \\itemize{
  \\item{\\code{id} Id of instance for which scores are desired.}
  }}
  \\subsection{Return Value}{Vector containing robust z-scores for each gene.}"
  
  ctrl <- .self$getPlateControls(id, ...)
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

Slinky$methods(getPlateControls = function(id, endpoint = "/controls", control_type = 'ctl_vehicle') {
  "Fetch normalized expression data for control samples from same plate as id
  and treated only with the vehicle used for sample id.
  \\subsection{Parameters}{
  \\itemize{
  \\item{\\code{id} Id of instance for which control data is desired.}
  }}
  \\subsection{Return Value}{dataframe containing normalized gene expression
  for controls.}"
  
  q <- sprintf('SELECT metadata.det_plate FROM LINCS WHERE Meta().id = "%s";', id)
  u <- sprintf("http://%s:8093/query/service", .self$.ip)
  res <- .self$.POST(u, body = list(statement = q), encode = "json", verbose = TRUE)
  kk <- jsonlite::fromJSON(content(res, 'text'))
  plate <- kk$results$det_plate
  
  q <- sprintf('SELECT data FROM LINCS WHERE metadata.det_plate = "%s" AND metadata.pert_type = "%s";', plate, control_type)
  res <- .self$.POST(u, body = list(statement = q), encode = "json", verbose = TRUE)
  kk <- jsonlite::fromJSON(content(res, 'text'))
  
  if (length(kk$results$data)) {
    return(do.call(cbind, kk$results$data))
  } else {
    return(NULL)
  }
  
  
#   veh <- .self$.GET(paste(.self$.endpoint, "/instances/", id, endpoint, sep=""))
#   if(length(veh)) {
#     veh <- gsub('\"', '"', content(veh, "text")) # need to get rid of escapes 
#     veh <- fromJSON(veh)
#     f <- function(x) {
#       return(x$value$data)
#     }
#     return(do.call(cbind, lapply(veh, f)))
#   } else {
#     return(NULL)
#   }
  
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


Slinky$methods(saveZ = function(doc_type, z_scores, gene_ids, instance) { 
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
  
  if (is.null(instance$is_gold)) instance$is_gold <- FALSE
  
  url <- paste(.self$.endpoint, "/pert", sep="")
  query <- list(
    perturbagen = jsonlite::unbox(instance$pert_desc),
    dose = jsonlite::unbox(instance$pert_dose),
    duration = jsonlite::unbox(instance$pert_time),
    cell = jsonlite::unbox(instance$cell_id),
    method = jsonlite::unbox(doc_type), 
    gold = jsonlite::unbox(instance$is_gold),
    gene_ids = gene_ids,
    data = z_scores
  )

  res <- .self$.POST(url = url, body = query, encode = "json", verbose = TRUE)

  if (res$status_code != 200L) {
    .self$.log("error", paste("ERR failed to save zscores for instance", instance$cell_id, instance$pert_desc, instance$pert_dose, instance$pert_time))
  } else {
    .self$.log("info", paste("OK saved zscores for", instance$cell_id, instance$pert_desc, instance$pert_dose, instance$pert_time))
  }
  
})


Slinky$methods(sliceMetadata = function(field, value, cols=NULL) {
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
  if(!length(cols)) {
    cols <- 1:nrow(metadata)
  } else {
    if(class(cols) == "character")
      cols <- which(metadata$distil_id %in% cols)
  }
  ix <- grep(value, metadata[cols, field])
  return(metadata$distil_id[cols[ix]])  
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

