test_that("default method errors for unsupported classes", {
  expect_error(
    audit_study(123),
    "Unknown class"
  )
})

test_that("list method validates a list object with", {
  expect_no_error(
    audit_study(list())
  )
})

test_that("list method fails for invalid object", {
  # setup
  crate <- rocrateR::rocrate_5s()

  expect_error(
    audit_study(crate),
    class = "error"
  )
})

test_that("list method returns list with expected attributes", {
  # setup
  opal_con <- opal_demo_con()

  # ignore warning about empty logs
  suppressWarnings(
    crate <- audit_study(list(demo = opal_con))
  )

  expect_equal(attr(crate, "audit_type"), "Study")
  expect_true("demo" %in% names(crate))
  expect_true(length(crate) == 1)

  # close connection to OBiBa's Opal demo server
  opalr::opal.logout(opal_con)
})

test_that("list method works with specific project", {
  # setup
  opal_con <- opal_demo_con()

  # ignore warning about empty logs
  suppressWarnings(
    crate <- audit_study(
      list(demo = opal_con),
      project = attr(opal_con, "PROJECT")
    )
  )

  expect_equal(attr(crate, "project"), attr(opal_con, "PROJECT"))

  # close connection to OBiBa's Opal demo server
  opalr::opal.logout(opal_con)
})

test_that("list method errors for unknown project", {
  # setup
  opal_con <- opal_demo_con()

  expect_error(
    audit_study(list(demo = opal_con), project = "NON_EXISTENT_PROJECT"),
    "The `project = 'NON_EXISTENT_PROJECT'` was not found",
    fixed = TRUE
  )

  # close connection to OBiBa's Opal demo server
  opalr::opal.logout(opal_con)
})

test_that("path argument is stored as attribute", {
  # setup
  opal_con <- opal_demo_con()

  # ignore warning about empty logs
  suppressWarnings(
    crate <- audit_study(
      list(demo = opal_con),
      path = tempdir()
    )
  )

  expect_equal(attr(crate, "path"), tempdir())

  # close connection to OBiBa's Opal demo server
  opalr::opal.logout(opal_con)
})
