test_that("character method prints TODO message", {
  expect_message(
    audit_safe_project("some/path"),
    "TODO: This generic method hasn't been implemented yet!"
  )
})

test_that("default method errors for unsupported classes", {
  expect_error(
    audit_safe_project(123),
    "Unknown class"
  )
})

test_that("rocrate method validates RO-Crate object", {
  crate <- rocrateR::rocrate_5s()

  expect_no_error(
    audit_safe_project(crate)
  )
})

test_that("rocrate method fails for invalid object", {
  expect_error(
    audit_safe_project(list()),
    class = "error"
  )
})

test_that("opal method returns RO-Crate with expected attributes", {
  # setup
  crate <- rocrateR::rocrate_5s()
  opal_con <- opal_demo_con()

  # ignore warning about empty logs
  suppressWarnings(
    crate <- audit_safe_project(opal_con)
  )

  expect_s3_class(crate, "rocrate")

  expect_equal(attr(crate, "audit_type"), "Safe Project")
  expect_true("project" %in% names(attributes(crate)))
})

test_that("opal method works with specific project", {
  # setup
  opal_con <- opal_demo_con()

  # ignore warning about empty logs
  suppressWarnings(
    crate <- audit_safe_project(
      opal_con,
      project = attr(opal_con, "PROJECT")
    )
  )

  expect_s3_class(crate, "rocrate")
  expect_equal(attr(crate, "project"), attr(opal_con, "PROJECT"))
})

test_that("opal method errors for unknown project", {
  # setup
  opal_con <- opal_demo_con()

  expect_error(
    audit_safe_project(opal_con, project = "NON_EXISTENT_PROJECT"),
    "No data details were found",
    fixed = TRUE
  )
})

test_that("path argument is stored as attribute", {
  # setup
  opal_con <- opal_demo_con()

  # ignore warning about empty logs
  suppressWarnings(
    crate <- audit_safe_project(
      opal_con,
      path = tempdir()
    )
  )

  expect_equal(attr(crate, "path"), tempdir())
})
