test_that("default method errors for unsupported classes", {
  expect_error(
    audit_safe_people(123),
    "Unknown class"
  )
})

test_that("rocrate method fails for invalid object", {
  expect_error(
    audit_safe_people(list()),
    class = "error"
  )
})

test_that("opal method returns RO-Crate with expected attributes", {
  # setup
  opal_con <- opal_demo_con()

  # ignore warning about empty logs
  suppressWarnings(
    crate <- audit_safe_people(opal_con, user = attr(opal_con, "PEOPLE"))
  )

  expect_s3_class(crate, "rocrate")

  expect_equal(attr(crate, "audit_type"), "Safe People")
  expect_true("project" %in% names(attributes(crate)))

  # close connection to OBiBa's Opal demo server
  opalr::opal.logout(opal_con)
})

test_that("opal method works with specific project", {
  # setup
  opal_con <- opal_demo_con()

  # ignore warning about empty logs
  suppressWarnings(
    crate <- audit_safe_people(
      opal_con,
      project = attr(opal_con, "PROJECT"),
      user = attr(opal_con, "PEOPLE")
    )
  )

  expect_s3_class(crate, "rocrate")
  expect_equal(attr(crate, "project"), attr(opal_con, "PROJECT"))

  # close connection to OBiBa's Opal demo server
  opalr::opal.logout(opal_con)

  # close connection to OBiBa's Opal demo server
  opalr::opal.logout(opal_con)
})

test_that("opal method errors for unknown project", {
  # setup
  opal_con <- opal_demo_con()

  expect_error(
    audit_safe_people(
      opal_con,
      project = "NON_EXISTENT_PROJECT",
      user = attr(opal_con, "PEOPLE")
    ),
    "The `project = 'NON_EXISTENT_PROJECT'` was not found in the given Opal connection!",
    fixed = TRUE
  )
})

test_that("path argument is stored as attribute", {
  # setup
  opal_con <- opal_demo_con()

  # ignore warning about empty logs
  suppressWarnings(
    crate <- audit_safe_people(
      opal_con,
      path = tempdir(),
      user = attr(opal_con, "PEOPLE")
    )
  )

  expect_equal(attr(crate, "path"), tempdir())

  # close connection to OBiBa's Opal demo server
  opalr::opal.logout(opal_con)
})
