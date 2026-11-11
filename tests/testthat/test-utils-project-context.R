# helper: mock the backend requests about a project and count them
mock_asset_requests <- function(.env = parent.frame()) {
  calls <- new.env(parent = emptyenv())
  calls$exists <- 0L
  calls$tables <- 0L
  calls$resources <- 0L

  testthat::local_mocked_bindings(
    project_exists = function(x, ...) {
      calls$exists <- calls$exists + 1L
      invisible(TRUE)
    },
    backend_tables = function(x, project, ...) {
      calls$tables <- calls$tables + 1L
      list(list(name = "T1"), list(name = "T2"))
    },
    backend_resources = function(x, project, ...) {
      calls$resources <- calls$resources + 1L
      list()
    },
    .env = .env
  )

  calls
}

test_that("get_project_context() creates a context for the project", {
  con <- fake_opal_con()

  context <- get_project_context(con, "P1")

  expect_true(is_project_context(context))
  expect_equal(context$project, "P1")
  expect_identical(context$connection, con)
})

test_that("get_project_context() creates a context without an RO-Crate", {
  con <- fake_opal_con()
  crate <- structure(list(), class = "rocrate")

  expect_true(is_project_context(get_project_context(con, "P1", NULL)))
  expect_true(is_project_context(get_project_context(con, "P1", crate)))
})

test_that("get_project_context() reuses the context stored in the RO-Crate", {
  con <- fake_opal_con()
  crate <- structure(list(), class = "rocrate")
  context <- get_project_context(con, "P1", crate)
  crate <- set_project_context(crate, context)

  expect_identical(get_project_context(con, "P1", crate), context)
})

test_that("get_project_context() does not reuse another project's context", {
  con <- fake_opal_con()
  crate <- structure(list(), class = "rocrate")
  crate <- set_project_context(crate, get_project_context(con, "P1", crate))

  other <- get_project_context(con, "P2", crate)

  expect_equal(other$project, "P2")
  expect_false(identical(other, get_project_context(con, "P1", crate)))
})

test_that("get_project_context() does not reuse another connection's one", {
  crate <- structure(list(), class = "rocrate")
  context <- get_project_context(fake_opal_con("user_a"), "P1", crate)
  crate <- set_project_context(crate, context)

  other <- get_project_context(fake_opal_con("user_b"), "P1", crate)

  expect_false(identical(other, context))
  expect_equal(other$connection$username, "user_b")
})

test_that("set_project_context() keeps the contexts of other projects", {
  con <- fake_opal_con()
  crate <- structure(list(), class = "rocrate")
  context_1 <- new_project_context(con, "P1")
  context_2 <- new_project_context(con, "P2")

  crate <- crate |>
    set_project_context(context_1) |>
    set_project_context(context_2)

  expect_identical(get_project_context(con, "P1", crate), context_1)
  expect_identical(get_project_context(con, "P2", crate), context_2)
  expect_equal(sort(names(attr(crate, "project_context"))), c("P1", "P2"))
})

test_that("set_project_context() leaves the crate and its context untouched", {
  con <- fake_opal_con()
  crate <- structure(
    list(`@graph` = list(list(`@id` = "a"))),
    class = "rocrate"
  )
  crate <- set_crate_context(crate, connection = con, project = "P1")

  res <- set_project_context(crate, new_project_context(con, "P1"))

  expect_s3_class(res, "rocrate")
  expect_equal(unclass(res)$`@graph`, unclass(crate)$`@graph`)
  expect_equal(get_crate_context(res, "project"), "P1")
  # the input object is not modified
  expect_null(attr(crate, "project_context"))
})

test_that("reset_project_context() removes the stored contexts", {
  con <- fake_opal_con()
  crate <- structure(list(), class = "rocrate")
  crate <- set_project_context(crate, new_project_context(con, "P1"))

  res <- reset_project_context(crate)

  expect_null(attr(res, "project_context"))
  expect_false(
    identical(
      get_project_context(con, "P1", res),
      get_project_context(con, "P1", crate)
    )
  )
})

test_that("project_context_exists() asks the backend only once", {
  calls <- mock_asset_requests()
  context <- new_project_context(fake_opal_con(), "P1")

  expect_invisible(project_context_exists(context))
  project_context_exists(context)
  project_context_exists(context)

  expect_equal(calls$exists, 1L)
})

test_that("project_context_exists() does not remember a missing project", {
  calls <- new.env(parent = emptyenv())
  calls$exists <- 0L
  local_mocked_bindings(
    project_exists = function(x, ...) {
      calls$exists <- calls$exists + 1L
      stop("project not found", call. = FALSE)
    }
  )
  context <- new_project_context(fake_opal_con(), "P1")

  expect_error(project_context_exists(context), "project not found")
  expect_error(project_context_exists(context), "project not found")
  expect_equal(calls$exists, 2L)
})

test_that("project_context_assets() lists each type of asset once", {
  calls <- mock_asset_requests()
  context <- new_project_context(fake_opal_con(), "P1")

  first <- project_context_assets(context, "tables")
  second <- project_context_assets(context, "tables")
  project_context_assets(context, "resources")
  project_context_assets(context, "resources")

  expect_identical(first, second)
  expect_equal(first$name, c("T1", "T2"))
  expect_equal(calls$tables, 1L)
  expect_equal(calls$resources, 1L)
  # ... and the project is verified only once
  expect_equal(calls$exists, 1L)
})

test_that("project_context_assets() remembers that there are no assets", {
  calls <- mock_asset_requests()
  context <- new_project_context(fake_opal_con(), "P1")

  expect_null(project_context_assets(context, "resources"))
  expect_null(project_context_assets(context, "resources"))

  expect_equal(calls$resources, 1L)
})

test_that("project_context_assets() verifies the project before listing", {
  calls <- new.env(parent = emptyenv())
  calls$tables <- 0L
  local_mocked_bindings(
    project_exists = function(x, ...) stop("project not found", call. = FALSE),
    backend_tables = function(x, project, ...) {
      calls$tables <- calls$tables + 1L
      list(list(name = "T1"))
    }
  )
  context <- new_project_context(fake_opal_con(), "P1")

  expect_error(project_context_assets(context, "tables"), "project not found")
  expect_equal(calls$tables, 0L)
})

test_that("filtering the shared assets does not change them", {
  mock_asset_requests()
  context <- new_project_context(fake_opal_con(), "P1")

  assets <- project_context_assets(context, "tables")
  filtered <- dplyr::filter(assets, name == "T1")

  expect_equal(nrow(filtered), 1)
  expect_equal(project_context_assets(context, "tables")$name, c("T1", "T2"))
})

test_that("project_context_assets() requires a valid type", {
  context <- new_project_context(fake_opal_con(), "P1")

  expect_error(project_context_assets(context, "users"), "should be one of")
})
