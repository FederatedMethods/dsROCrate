test_that("character method prints TODO message", {
  expect_message(
    audit_safe_people("some/path"),
    "TODO: This generic method hasn't been implemented yet!"
  )
})

test_that("default method errors for unsupported classes", {
  expect_error(
    audit_safe_people(123),
    "Unknown class"
  )
})

test_that("rocrate method validates RO-Crate object", {
  # setup
  opal_con <- opal_demo_con()
  crate <- rocrateR::rocrate_5s() |>
    safe_project(connection = opal_con, project = attr(opal_con, "PROJECT")) |>
    safe_people(user = attr(opal_con, "PEOPLE"))

  expect_no_error(
    audit_safe_people(crate)
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
    "The given `project`, does not have any permissions set for the given `user`!",
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
})
