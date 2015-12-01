sl <- Slinky$new(ip = "127.0.0.1", port = "8081")

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

context("Score calculation")
test_that("Plate controls can be retrieved", {
  val <- apply(sl$getPlateControls('CPC006_MCF7_6H_X2_F1B3_DUO52HI53LO:O15'), 1, mean)[1]
  expect_equal(val, 11.41145)
})

test_that("Zscores can be calculated", {
  scores <- sl$ZbyPlate('CPC006_MCF7_6H_X2_F1B3_DUO52HI53LO:O15')
  expect_equal(mean(scores), 0.01266456, tolerance=1e-6)
})


