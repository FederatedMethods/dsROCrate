test_that("validate_backend() validates an unvalidated crate", {
  con <- fake_opal_con()
  crate <- structure(list(), class = "rocrate")
  calls <- new.env(parent = emptyenv())
  calls$con <- 0L
  calls$version <- 0L
  calls$permissions <- 0L

  local_mocked_bindings(
    validate_con = function(x, ...) {
      calls$con <- calls$con + 1L
      invisible(TRUE)
    },
    validate_backend_version = function(x, ...) {
      calls$version <- calls$version + 1L
      invisible(TRUE)
    },
    check_permissions = function(x, ...) {
      calls$permissions <- calls$permissions + 1L
      invisible(TRUE)
    }
  )

  expect_invisible(validate_backend(con, rocrate = crate))
  expect_identical(calls$con, 1L)
  expect_identical(calls$version, 1L)
  expect_identical(calls$permissions, 1L)
})

test_that("validate_backend() skips checks for a crate validated with the same connection", {
  con <- fake_opal_con()
  crate <- structure(list(), class = "rocrate")
  attr(crate, "connection") <- con
  attr(crate, "backend_validated") <- TRUE

  local_mocked_bindings(
    validate_con = function(...) {
      testthat::fail("validate_con() should not be called")
    },
    validate_backend_version = function(...) {
      testthat::fail("validate_backend_version() should not be called")
    },
    check_permissions = function(...) {
      testthat::fail("check_permissions() should not be called")
    }
  )

  expect_invisible(validate_backend(con, rocrate = crate))
})

test_that("validate_backend() revalidates a crate when the connection differs", {
  original_con <- fake_opal_con(username = "original")
  new_con <- fake_opal_con(username = "different")
  crate <- structure(list(), class = "rocrate")
  attr(crate, "connection") <- original_con
  attr(crate, "backend_validated") <- TRUE

  calls <- new.env(parent = emptyenv())
  calls$con <- 0L
  calls$version <- 0L
  calls$permissions <- 0L

  local_mocked_bindings(
    validate_con = function(x, ...) {
      calls$con <- calls$con + 1L
      expect_identical(x, new_con)
      invisible(TRUE)
    },
    validate_backend_version = function(x, ...) {
      calls$version <- calls$version + 1L
      expect_identical(x, new_con)
      invisible(TRUE)
    },
    check_permissions = function(x, ...) {
      calls$permissions <- calls$permissions + 1L
      expect_identical(x, new_con)
      invisible(TRUE)
    }
  )

  expect_invisible(validate_backend(new_con, rocrate = crate))
  expect_identical(calls$con, 1L)
  expect_identical(calls$version, 1L)
  expect_identical(calls$permissions, 1L)
})

test_that("validate_backend() does not continue after a validation failure", {
  con <- fake_opal_con()
  crate <- structure(list(), class = "rocrate")
  calls <- new.env(parent = emptyenv())
  calls$version <- 0L
  calls$permissions <- 0L

  local_mocked_bindings(
    validate_con = function(x, ...) stop("connection invalid", call. = FALSE),
    validate_backend_version = function(x, ...) {
      calls$version <- calls$version + 1L
      invisible(TRUE)
    },
    check_permissions = function(x, ...) {
      calls$permissions <- calls$permissions + 1L
      invisible(TRUE)
    }
  )

  expect_error(validate_backend(con, rocrate = crate), "connection invalid")
  expect_identical(calls$version, 0L)
  expect_identical(calls$permissions, 0L)
})

test_that("backend_validated.opal() requires a true flag and an identical connection", {
  con <- fake_opal_con()
  other_con <- fake_opal_con(username = "other")
  crate <- structure(list(), class = "rocrate")

  expect_false(backend_validated(con, rocrate = crate))

  attr(crate, "backend_validated") <- TRUE
  expect_false(backend_validated(con, rocrate = crate))

  attr(crate, "connection") <- con
  expect_true(backend_validated(con, rocrate = crate))
  expect_false(backend_validated(other_con, rocrate = crate))

  attr(crate, "backend_validated") <- NA
  expect_false(backend_validated(con, rocrate = crate))
})

test_that("a crating session validates once and reuses the context flag", {
  con <- fake_opal_con()
  crate <- structure(list(), class = "rocrate")
  calls <- new.env(parent = emptyenv())
  calls$con <- 0L
  calls$version <- 0L
  calls$permissions <- 0L

  local_mocked_bindings(
    validate_con = function(x, ...) {
      calls$con <- calls$con + 1L
      invisible(TRUE)
    },
    validate_backend_version = function(x, ...) {
      calls$version <- calls$version + 1L
      invisible(TRUE)
    },
    check_permissions = function(x, ...) {
      calls$permissions <- calls$permissions + 1L
      invisible(TRUE)
    }
  )

  # Initialisation validates the connection before marking the crate context.
  expect_invisible(validate_backend(con, rocrate = crate))
  crate <- set_crate_context(crate, connection = con)

  # Subsequent operations in the same session reuse the validation result.
  expect_invisible(validate_backend(con, rocrate = crate))
  expect_invisible(validate_backend(con, rocrate = crate))

  expect_identical(calls$con, 1L)
  expect_identical(calls$version, 1L)
  expect_identical(calls$permissions, 1L)
})
