#!/usr/bin/env Rscript
library(slinky)
library(ggplot2)
library(borgmisc)

data("metadata")


dd <- '/mnt/lincs/LINCStest/'
couch_ip <- readRDS(paste0(dd, 'couch_ip.rds'))
slo <- Slinky$new(ip = couch_ip, port = '8080')


# here is how you can get a specific z-score
# http://52.35.41.246:8092/LINCS/_design/dev_data/_view/zspc?full_set=true&inclusive_end=true&key=["ZSPC_L1000","A549","Cimaterol",10,6]&stale=false&connection_timeout=60000&limit=10&skip=0

# Validate zscore calculation #30
qnorm <- readRDS(paste0(dd, "q2norm_test_set.rds"))

# get our list of L1000 ids to trim down data
score <- GET(paste0('http://', slo$.ip, ':8092/LINCS/_design/dev_data/_view/zspc?full_set=true&inclusive_end=true&key=["ZSPC_L1000","A549","Cimaterol",10,6]&stale=false&connection_timeout=60000&limit=10&skip=0'))
ss <- jsonlite::fromJSON(content(score, 'text'))
l1000 <- unlist(ss$rows$value$gene_ids)
rownames(qnorm) <- trim(rownames(qnorm))
qnorm <- qnorm[which(rownames(qnorm) %in% l1000), ]

# set up a metadata object in the same order as qnorm
ord <- match(colnames(qnorm), metadata$distil_id)
mm <- metadata[ord, ]
stopifnot(all(mm$distil_id == colnames(qnorm)))

# we agg these at this level...
mm$key <- paste(mm$pert_desc, mm$cell_id, mm$pert_dose, mm$pert_time, sep = "_")
keys <- unique(mm$key)
keys <- keys[!grepl("^-666", keys)]

results <- vector(mode = 'list', length = length(keys))
names(results) <- keys

for (i in seq_along(keys)) {
  print(i)
  k <- keys[i]
  
  # a few of these bail -- either scores are not in DB or .checkParam is not satisfied
  e <- try({

    # check if there are any samples we would have excluded
    tmp <- filter(mm, key == k)
    to_drop <- c()
    for (i in 1:nrow(tmp)) {
      param <- tmp[i,c('pert_desc', 'cell_id', 'pert_dose', 'pert_time', 'pert_type')]
      if (!slo$.checkParam(param = param, check_gold = FALSE)) to_drop <- c(to_drop, i)
    }
    if (length(to_drop)) tmp <- tmp[-to_drop, ]
  
    # compute plate-level z-scores for each sample that passes
    zscores <- do.call(rbind, lapply(1:nrow(tmp), function(x) {
      p <- tmp[x, 'det_plate']
      
      # figure out the controls on the plate
      controls <- filter(mm, pert_type == "ctl_vehicle" & det_plate == p) %>% 
        select(distil_id) %>% unlist %>% unname
      
      # replicate eric's calculation from Slinky$methods(ZbyPlate)
      ctrl.m <- apply(qnorm[,controls], 1, mean)
  
      exp <- qnorm[ ,tmp[x, 'distil_id']]
      geneids <- names(exp)
      fc <- log2(exp/ctrl.m)
      return((fc - median(fc)) / mad(fc))

    }))
  
  
  # we take the mean of all these per-plate signatures as our final signature
  final_scores <- apply(zscores, 2, mean)
  
    # pull the scores from couchbase for comparison
    u <- paste0('http://', slo$.ip, ':8092/LINCS/_design/data/_view/zsvc?inclusive_end=true&key=["ZSVC_L1000","', tmp$cell_id[1], '","', tmp$pert_desc[1], '",', tmp$pert_dose[1], ',', tmp$pert_time[1], ']&stale=false&connection_timeout=60000&limit=10&skip=0')
    res <- slo$.GET(url = u)
    inst <- jsonlite::fromJSON(content(res, 'text'))
    couch_scores <- setNames(unlist(inst$rows$value$data), unlist(inst$rows$value$gene_ids))  
    couch_scores <- couch_scores[names(final_scores)] # match order
    
    pass <- all.equal(final_scores, couch_scores, tolerance = 0.001)
    
    results[[k]] <- list(
      key = k,
      pass = pass,
      mean_difference = mean(final_scores - couch_scores),
      hdf5_scores = final_scores, 
      couch_scores = couch_scores
    )
  })
  if (inherits(e, 'try-error')) {
    message("Couldn't parse scores for ", k)
    results[[k]] <- NULL
  }

}

saveRDS(object = results, file = paste0(dd, 'z-score-validation-results.rds'))


xtrakt <- function(x) {
  if (!is.null(x)) {
    data.frame(key = x$key, pass = x$pass, mean_difference = x$mean_difference)
  } else {
    x
  }
} 
dat <- do.call(rbind, lapply(results, xtrakt))

hist(dat$mean_difference, col = 'grey', xlab = "HDF5 Scores - Couchbase Scores", 
     main = "Validation of 2000 Z-scores")

miss_sel <- which(is.na(dat$mean_difference))

k <- 3
test <- results[[miss_sel[k]]]
dat[miss_sel[k], ]
sum(!is.na(dat$mean_difference))


# Compare zsvc to zspc zscores #31
# zpc <- readRDS(paste0(dd, "zspc_test_set.rds"))
# 
# 
# 
# # we processed these in groups -- split by group
# data(metadata)
# metadata <- filter(metadata, pert_desc != "-666")
# meta <- metadata[metadata$distil_id %in% colnames(zpc), ]
# meta$key <- sapply(1:nrow(meta), function(i) paste(meta[i, c('pert_desc', 'cell_id', 'pert_dose', 'pert_time')], collapse = "_"))
# meta$key <- paste("ZSVC_L1000", meta$key, sep = "_")
# 
# metadata$key <- sapply(1:nrow(metadata), function(i) paste(metadata[i, c('pert_desc', 'cell_id', 'pert_dose', 'pert_time')], collapse = "_"))
# 
# ZSVC_L1000_A375_7903753_10_6
# 
# 
# keys <- unique(meta$key)
# 
# # compute an average z-score for our grouping
# avg_z <- do.call(cbind, lapply(split(meta, meta$key, drop = TRUE), function(x) {
#   apply(zpc[,x$distil_id, drop = FALSE], MARGIN = 1, mean)
# }))
# 
# saveRDS(object = avg_z, file = paste0("~/", "zspc-avg-z-scores.rds"))
# 
# 
# # look @ 1 first one
# k <- filter(meta, key == keys[1])
# 
# 




