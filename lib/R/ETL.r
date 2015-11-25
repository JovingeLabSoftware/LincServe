library(rhdf5)
#library(GEOquery)
# detach just in case to prevent biobase content overriding httr content
tryCatch({detach('package:httr')}, error = function(e) {})
library(httr)
tryCatch({detach('package:rjson')}, error = function(e) {})
library(rjson)
library(tidyjson)
library(dplyr)

config <- fromJSON(file="./config.json")
url <- paste("http://", config$couch_url, ":", config$couch_port, "/query/service", sep="")
rest <- config$lincs_rest

calc <- function() {
  range <- content(GET( paste(rest, "/nidrange", sep="")))
  step <- floor((range$max - range$min) / 200000);
    
  for(i in seq(0, range$max, step)) {
    url <- paste(rest, "/summaries/nid?first=", i, "&last=", i+step, sep="")
    res <- GET(url, query=list(first=i, last=i+step));
    data <- summaryToDF(content(res, as = 'text'));  
    for(ii in 1:nrow(data)) {
      param = data[ii,]
      if(param$type == "trt_cp" && param$desc != "-666" && param$gold) {
        instances <- getReplicates(pert = param$desc, cell = param$cell, dose = param$dose, duration = param$time)
        scores <- do.call(cbind, lapply(instances$id, ZbyPlate))
        gids <- rownames(scores)
        scores <- apply(scores, 1, mean)
        saveDoc(param$cell, param$desc, param$dose, param$time, gids, scores, "ZSVC_L1000", "1.0", "true")
      }
    }
  }  
}


getReplicates <- function(pert, 
                          cell, 
                          dose, 
                          duration, 
                          gold=TRUE) { 
  query <- list(pert = pert, cell=cell, dose=dose, duration=duration, gold=gold, limit=10000)
  res <- GET(paste(rest, "/instances", sep=""), query=query)
  data <- gsub('\"', '"', content(res, "text")) # need to get rid of escapes
  ids <- data %>% 
    gather_array %>% 
    spread_values(id = jstring("id")) %>%
    select(id)
  ids
}

ZbyPlate <- function(id) {
  ctrl <- getPlateControls(id)
  ctrl.m <- apply(ctrl, 1, mean)
  save(ctrl.m, file=tempfile(fileext = "rda"))
  url <- paste(rest, "/instances/", id, sep="")
  print(url)
  exp <- GET(url)
  exp <- gsub('\"', '"', content(exp, "text")) # need to get rid of escapes 
  geneids <- fromJSON(exp)$gene_ids
  exp <- fromJSON(exp)$norm_exp
  fc <- log2(exp/ctrl.m)
  fc <- (fc - median(fc)) / mad(fc)
  names(fc) <- geneids
  fc
}

getPlateControls <- function(id) {
  veh <- GET(paste(rest, "/instances/", id, "/controls", sep=""))
  veh <- gsub('\"', '"', content(veh, "text")) # need to get rid of escapes 
  veh <- fromJSON(veh)
  f <- function(x) {
    return(x$value$norm_exp);
  }
  return(do.call(cbind, lapply(veh, f)))
}

summaryToDF <- function(json) {
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
}

saveDoc <- function(cell_line, pert, dose, duration, gene_ids, zscores, type, version, gold) {
  url <- paste(rest, "/zscores", sep="")
  query=list(cell_line = cell_line, 
             pert = pert, 
             dose = dose, 
             duration = duration,
             gene_ids = toJSON(as.vector(gene_ids)),
             zscores = toJSON(as.vector(zscores)),
             type = type,
             version = version,
             gold = gold)
  res <- POST(url, query=query);
  res
}

# careful now...
flush <- function() {
  cat("Are you sure you want to delete all data from this bucket?  (yes/no):\n")
  confirm <- readLines(n=1)
  res <- NULL
  if(confirm == "yes") {
    url <- paste(config$couch_url, ":8091/pools/default/buckets/LINCS1/controller/doFlush", sep="")
    print(url)
    res <- POST(url)
  }
  # status_code(res) should be 200
  return(res)
}

init <- function() {
  statement <- "CREATE PRIMARY INDEX ON LINCS1"
  # will fail silently if already exists...
  res <- POST(url, query=list(statement=statement))  
  statement <- "CREATE INDEX ix_pert_desc ON LINCS1(metadata.pert_desc)"
  res <- POST(url, query=list(statement=statement))  
  statement <- "CREATE INDEX ix_pert_id ON LINCS1(metadata.pert_id)"
  res <- POST(url, query=list(statement=statement))  
  statement <- "CREATE INDEX ix_cell_id ON LINCS1(metadata.cell_id)"
  res <- POST(url, query=list(statement=statement))  
}


# :( this is only 20% of the data
load_all <- function () {
  # fetch superseries metadata to identify sub-series
  ss <- GET("http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE70138&form=text")
  ss <- unlist(strsplit(content(ss, as = 'text'), "\\r*\\n"))
  gse_list <- gsub(".*acc=", "", grep("!Series_summary = GSE.*:", ss, value = TRUE))
  for(gse in gse_list) {
    ids <- GET(paste("http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=", gse, "&targ=self&view=brief&form=text", sep=""))
    ids <- unlist(strsplit(content(ids, as='text'), "\\r*\\n"))
    ids <- gsub(".* = ", "", grep("!Series_sample_id = GSM", ids, value = TRUE))
    
    
    count <- 1
    for(id in ids) {
      print(paste(gse, count, "of", length(ids), ":", id))
      loadGEO <- tryCatch(
        {
          data <- getGEO(GEO = id, destdir = "/tmp")
          fh <- paste("/tmp/", id, ".soft", sep="")
          unlink(fh)
        },
          error=function(e) e
      )

      if(inherits(loadGEO, "error")) {
        write(paste("ERROR:", gse, "processing failed."), file="errors.log", append=TRUE)
        next
      }
      
      treatment <- gsub(".*:", "", data@header$treatment_protocol_ch1)

      metadata <- list(
        gsm = id,
        cell_line = gsub(".*:", "", data@header$source_name_ch1),
        type = treatment[1],
        lincs_id = treatment[2],
        name = treatment[3],
        dose = treatment[4],
        dose_unit = treatment[5],
        time = treatment[6],
        time_unit = treatment[7]  
      )

      write(paste(id, metadata$name, metadata$lincs_id, metadata$cell_line, sep="\t"), file="loading.log", append=TRUE)

      gene_id <- as.character(data@dataTable@table[1:978,1])
      zscore <- as.numeric(data@dataTable@table[1:978,4])
      statement <- paste("INSERT INTO LINCS1 (KEY, VALUE) VALUES('", id, "', ", toJSON(list(metadata=metadata, data=list(gene_id=gene_id, zscore=zscore))), ")", sep="");
      res <- POST(url, query=list(statement=statement))
      count <- count + 1
    }
  }
}

unique_drugs <- function() {
  statement <- "SELECT DISTINCT metadata.name FROM LINCS1"
  res <- POST(url, query=list(statement=statement))
  unlist(content(res)$results)
}

load_from_hdf5 <- function(col) {
  h5read("/mnt/lincs/inst_info.gctx", "0/META/COL/id", index=list(2))
  
  if(!exists('md')) {
    md <- readRDS("../../../ExpSpect/data/metadata.rds")
  }
  
  data <- h5read("../../../q2norm_n1328098x22268.gctx", "0/DATA/0/matrix", index=list(c(1:978), col))
  ids <- h5read("../../../q2norm_n1328098x22268.gctx", "/0/META/ROW/id", index=list(c(1:978)))
  ids <- gsub(" ", "", ids)
  colids <- h5read("../../../q2norm_n1328098x22268.gctx", "/0/META/COL/id", index=list(col))
  colids <- gsub(" ", "", colids)
  
  # verify matching data
  if(! sum(colids == md$distil_id[col]) == length(col)) {
    stop("ID mismatch between metadata and expression data")
  }
  
  doc <- list();
  for(i in 1:length(col)) {
    doc <- list( metadata = md[col[i],], gene_ids = ids, norm_exp = data[,i])
    statement <- paste("INSERT INTO LINCS1 (KEY, VALUE) VALUES('", colids[i], "', ", toJSON(doc), ")", sep="");    
    res <- POST(url, query=list(statement=statement))
    if(status_code(res) != 200) {
      print(paste("Error uploading document for", colids[i], sep=" "))
    } 
  }
}

load_all_hdf5 <- function() {
  for(i in seq(1, length(h5read("../../../q2norm_n1328098x22268.gctx", "/0/META/COL/id")), by = 500)) {
    ii <- min(i+499, length(h5read("../../../q2norm_n1328098x22268.gctx", "/0/META/COL/id")))
    load_from_hdf5(i:ii)  
    cat(i)
  }
}

get_gold_instances <- function() {
  url = "http://api.lincscloud.org/a2/siginfo?q={%22is_gold%22:%22true%22}&user_key=lincsdemo&l=1000&f={%22distil_id%22:1}&sk="
  for(i in seq(0, 240901, by = 1000)) {
    g <- c(g, unlist(content(GET(paste(url, i, sep="")))))
    print(i)
  }
  g
  ix <- which(names(g) == "_id")
  unique(g[-ix])
}




