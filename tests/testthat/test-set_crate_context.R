context_attrs <- c(
  "connection",
  "path",
  "profile",
  "project",
  "resources",
  "tables",
  "user"
)

test_that("set_crate_context() attaches the context as attributes", {
  con <- fake_opal_con()
  crate <- structure(list(`@graph` = list()), class = "rocrate")

  res <- set_crate_context(
    crate,
    connection = con,
    path = "path/to/crate",
    profile = "default",
    project = "CNSIM",
    resources = c("RSRC1", "RSRC2"),
    tables = "CNSIM1",
    user = "dsuser"
  )

  expect_identical(attr(res, "connection"), con)
  expect_equal(attr(res, "path"), "path/to/crate")
  expect_equal(attr(res, "profile"), "default")
  expect_equal(attr(res, "project"), "CNSIM")
  expect_equal(attr(res, "resources"), c("RSRC1", "RSRC2"))
  expect_equal(attr(res, "tables"), "CNSIM1")
  expect_equal(attr(res, "user"), "dsuser")
})

test_that("set_crate_context() leaves the crate itself untouched", {
  crate <- structure(
    list(`@graph` = list(list(`@id` = "a"))),
    class = "rocrate"
  )

  res <- set_crate_context(crate, project = "CNSIM")

  expect_s3_class(res, "rocrate")
  expect_equal(unclass(res)$`@graph`, unclass(crate)$`@graph`)
  # the input object is not modified
  expect_null(attr(crate, "project"))
})

test_that("set_crate_context() removes the attributes that are set to NULL", {
  crate <- structure(list(), class = "rocrate")
  crate <- set_crate_context(crate, project = "CNSIM", tables = "CNSIM1")

  res <- set_crate_context(crate, project = "CNSIM")

  expect_equal(attr(res, "project"), "CNSIM")
  expect_null(attr(res, "tables"))
})

test_that("set_crate_context() preserves attributes that are not part of the context", {
  crate <- structure(list(), class = "rocrate", custom = "keep me")

  res <- set_crate_context(crate, user = "dsuser")

  expect_equal(attr(res, "custom"), "keep me")
  expect_s3_class(res, "rocrate")
})

test_that("set_crate_context() only sets the documented attributes", {
  crate <- structure(list(), class = "rocrate")

  res <- set_crate_context(
    crate,
    connection = fake_opal_con(),
    path = "p",
    profile = "default",
    project = "CNSIM",
    resources = "R",
    tables = "T",
    user = "u"
  )

  expect_setequal(setdiff(names(attributes(res)), "class"), context_attrs)
})
