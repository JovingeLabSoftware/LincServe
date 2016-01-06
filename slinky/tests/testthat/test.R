# usage:  testthat::auto_test("R/", "tests/testthat/")
# or ... debugSource('/mnt/lincs/CouchLincs/esandbox/LincServe/slinky/tests/testthat/test.R')
# or ... test_dir("tests/testthat")


prof = FALSE;
syst = TRUE;
if(prof) {
  library(profvis)
}

sl <- Slinky$new(ip = "127.0.0.1", port = "8081", loglevel='none')

context("Class instantiation")
test_that("Slinky object can be created", {  
  # don't access private slots in real life
  expect_equal(sl$.ip, "127.0.0.1")
  sl$setIp("54.152.59.84");  
  expect_equal(sl$.ip, "54.152.59.84")
  
  # don't access private slots in real life
  expect_equal(sl$.port, "8081")
  sl$setPort("8080");  
  expect_equal(sl$.port, "8080")
})

context("Instance data")
test_that("Data from several instances can be retrieved", {
  ids <- c( "CPC005_A375_6H_X1_B3_DUO52HI53LO:K06", "CPC005_A375_6H_X2_B3_DUO52HI53LO:K06", "CPC005_A375_6H_X3_B3_DUO52HI53LO:K06")
  data <- sl$getInstanceData(ids)
  expect_equal(ncol(data), 3)
})

test_that("An entire instance can be retrieved", {
  ids <- c( "CPC005_A375_6H_X1_B3_DUO52HI53LO:K06")
  data <- sl$getInstance(ids)
  expect_equal(length(data[[1]]), 7)
})

test_that("Data can be appended to an instance", {
  ids <- c( "CPC005_A375_6H_X1_B3_DUO52HI53LO:K06")
  data <- sl$getInstance(ids)[[1]]
  test <- unlist(data$data) * 1000
  sl$append(ids[1], test, "appendtest")
  check <- sl$getInstance(ids)
  expect_equal(length(check[[1]]), 7)
  expect_equal(unlist(check[[1]]$appendtest)[1], 11049.5)
})


test_that("Data can be retrieved by query", {
  q = list(distil_id = 'CPC014_VCAP_6H_X2_F1B3_DUO52HI53LO:P05');
  #f = c("metadata.distil_id", "metadata.det_plate", "doctype", "metadata.pert_desc");
  f <- NA
  data <- sl$query(q, f)
  expect_equal(as.character(data$metadata$det_plate[1]), "CPC014_VCAP_6H_X2_F1B3_DUO52HI53LO")
})

test_that("Entire plate of metadata can be retrieved", {
  # skip("skipped")
  q = list(det_plate = 'CPC014_VCAP_6H_X2_F1B3_DUO52HI53LO');
  
  # note use of field selector...
  # f = c("data", "metadata.distil_id", "metadata.det_plate", "metadata.pert_desc");
  
  plate_dat <- sl$query(q)
  
#   if(prof) { 
#     print(profvis({
#       data <- sl$query(q, f)
#     }))
#   } else if (syst) {
#     cat("\n"); print(system.time(data <- sl$query(q, f))); cat("\n")
#     
#   }  else {
#     data <- sl$query(q, f)
#   }
  expect_equal(as.character(plate_dat$metadata$pert_desc[191]), "GR-103")
})

