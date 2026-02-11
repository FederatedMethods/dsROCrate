setup({
  skip_on_cran()
  skip_if_offline()

  source("opal-demo-server.R")
})

test_that("init() dispatches to init.opal() with real Opal connection", {
  crate <- rocrateR::rocrate_5s()

  res <- init(
    opal_con,
    rocrate = crate,
    project = PROJECT,
    tables = TABLES,
    user = PEOPLE
  )

  expect_s3_class(res, "rocrate")
  expect_identical(attr(res, "connection"), opal_con)
})

test_that("init.opal() attaches metadata using demo Opal server", {
  crate <- rocrateR::rocrate_5s()

  res <- init.opal(
    opal_con,
    rocrate = crate,
    path = tempdir(),
    project = PROJECT,
    tables = TABLES,
    user = PEOPLE
  )

  expect_identical(attr(res, "connection"), opal_con)
  expect_identical(attr(res, "project"), PROJECT)
  expect_identical(attr(res, "tables"), TABLES)
  expect_identical(attr(res, "user"), PEOPLE)
  expect_true(dir.exists(attr(res, "path")))
})

test_that("init.rocrate() reuses stored attributes with demo Opal server", {
  crate <- rocrateR::rocrate_5s()

  attr(crate, "connection") <- opal_con
  attr(crate, "project") <- PROJECT
  attr(crate, "tables") <- TABLES
  attr(crate, "user") <- PEOPLE
  attr(crate, "path") <- tempdir()

  res <- init(crate)

  expect_identical(attr(res, "connection"), opal_con)
  expect_identical(attr(res, "project"), PROJECT)
  expect_identical(attr(res, "tables"), TABLES)
  expect_identical(attr(res, "user"), PEOPLE)
  expect_identical(attr(res, "path"), attr(crate, "path"))
})

test_that("init.opal() errors on invalid connection object", {
  crate <- rocrateR::rocrate_5s()

  expect_error(
    init.opal(list(not = "opal"), rocrate = crate),
    class = "error"
  )
})
