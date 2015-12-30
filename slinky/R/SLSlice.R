SLSlice <- setRefClass("SLSlice", 
                       fields = list(.slinky = "refClass",
                                     .ids = "character",
                                     .data = "numeric",
                                     .dataType = "character"),
                        methods = list(
                         query = function(x) {}
                        )
)

SLSlice$methods(initialize = function(slinky, dataType=NULL) {
  if(!length(dataType)) {
    stop("Must specify dataType (e.g. 'q2norm') when initializing SLSlice object")
  }
  .self$.slinky <<- slinky
  .self$ids <<- NULL
})
  
SLSlice$methods(setIds = function(ids) {
  .self$.ids <<- ids
})

SLSlice$methods(getIds = function() {
  .self$.ids
})

SLSlice$methods(data = function() {
  .self$.data <- .self$.slinky(getData(.self$.ids, .self$.type))
})

slFilter = function(slice, field, value) {
  slice$setIds <- .self$.slinky$sliceMetadata(field, value, slice$getIds())
  slice
}
                       
slCollapse = function(slice, fun) {
  sl$data()
  slice$setIds <- .self$.slinky$sliceMetadata(field, value, slice$getIds())
  slice
}

#                        # z score
#                        # ds1 <- sl$query(..., data=...) %>% sl$query(...)
#                        # ds2 <- sl$extract(...) %>% sl$extract(...)
#                        
#                        A <- SLSlice$new();
#                        B <- SLSlice$new();
#                        A$extract(...) %>% A$extract(...) %>% A$collapse(..._) %>% A$extract()
#                        B$extract(...) %>% B$extract(...) %>% B$collapse(..._)
#                        
#                        an <- SLAnalysis$new(A, B, collate=);
#                        
#                        
#                        #object <- as.list(substitute(list(...)))[-1L]
#                        
#                        # sl$colate(ds1, ds2, fields)
#                        # 
#                                                  
#                                                  
#                        
#                        What about something along these lines:
#                          
#                          # create a slice containing ALL the perturbed samples of interest
#                          sl <- Slinky$new()
#                        A %<>%  SLSlice$new(sl, .) %>% select(“pert_type”, “trt_cp”) %>% select(“type”, “q2norm”)
#                        
#                        # now let’s get fancy…we will create  a new variable
#                        A$extract(“control”, c(“plate”, “pert_vehicle”, “pert_duration”))
#                        
#                        # create a slice containing ALL the controls of interest, and collapse replicates by taking their mean
#                        B %<>% SLSlice$new(sl, .) %>% select(“plate”, “plate1”) %>% select(“pert_type”, “ctrl_vehicle”) %>% select(“type”, “q2norm”) %>% collapse(“mean”) 
#                        
#                        # note that this time we extract pert_desc instead of pert_vehicle so that controls in A map to perturbations in B
#                        B$extract(“control”, c(“plate”, “pert_desc”, “pert_duration”))
#                        
#                        # so we can do this…
#                        rzs <- function(a, b) { … # calculate robust zscore } 
#                          sl$analyze(A, B, method=”rzs”, collate=”control”, collapse=”median”) 
#                          
#                          