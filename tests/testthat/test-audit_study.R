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
})

test_that("list method errors for unknown project", {
  # setup
  opal_con <- opal_demo_con()

  expect_error(
    audit_study(list(demo = opal_con), project = "NON_EXISTENT_PROJECT"),
    "No data details were found",
    fixed = TRUE
  )
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
})
