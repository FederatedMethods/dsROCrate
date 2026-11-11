# helper: mock all the backend requests made by `safe_project()` and
# `safe_data()`, and count them
mock_project_backend <- function(.env = parent.frame()) {
  calls <- new.env(parent = emptyenv())
  for (name in c(
    "validate",
    "exists",
    "project",
    "project_perms",
    "tables",
    "resources",
    "table_perms",
    "resource_perms"
  )) {
    calls[[name]] <- 0L
  }
  count <- function(name) {
    calls[[name]] <- calls[[name]] + 1L
  }
  timestamps <- list(
    created = "2026-10-13T04:26:14.076Z",
    lastUpdate = "2026-10-13T14:17:32.082Z"
  )

  testthat::local_mocked_bindings(
    validate_backend = function(x, ...) {
      count("validate")
      invisible(TRUE)
    },
    project_exists = function(x, ...) {
      count("exists")
      invisible(TRUE)
    },
    backend_project = function(x, project, ...) {
      count("project")
      list(name = project, timestamps = timestamps)
    },
    backend_project_perms = function(x, project, ...) {
      count("project_perms")
      data.frame(
        subject = "administrator",
        type = "user",
        permission = "administrate",
        stringsAsFactors = FALSE
      )
    },
    backend_tables = function(x, project, ...) {
      count("tables")
      list(
        list(name = "T1", timestamps = timestamps),
        list(name = "T2", timestamps = timestamps)
      )
    },
    backend_resources = function(x, project, ...) {
      count("resources")
      list()
    },
    backend_table_perms = function(x, project, ...) {
      count("table_perms")
      data.frame(
        subject = "dsuser",
        type = "user",
        permission = "view",
        stringsAsFactors = FALSE
      )
    },
    backend_resource_perms = function(x, project, ...) {
      count("resource_perms")
      data.frame(
        subject = character(),
        type = character(),
        permission = character(),
        stringsAsFactors = FALSE
      )
    },
    .env = .env
  )

  calls
}

test_that("safe_project() and safe_data() share requests about a project", {
  calls <- mock_project_backend()
  con <- fake_opal_con()

  crate <- init(con, project = "CNSIM") |>
    safe_project() |>
    safe_data()

  expect_equal(calls$exists, 1L)
  expect_equal(calls$tables, 1L)
  expect_equal(calls$resources, 1L)
  # the permissions of each table are still requested (see issue #42)
  expect_equal(calls$table_perms, 2L)
  expect_s3_class(crate, "rocrate")
})

test_that("safe_project() alone requests the project and assets once", {
  calls <- mock_project_backend()
  con <- fake_opal_con()

  safe_project(con, project = "CNSIM")

  expect_equal(calls$exists, 1L)
  expect_equal(calls$tables, 1L)
  expect_equal(calls$resources, 1L)
})

test_that("safe_data() alone requests the project and assets once", {
  calls <- mock_project_backend()
  con <- fake_opal_con()

  safe_data(con, project = "CNSIM")

  expect_equal(calls$exists, 1L)
  expect_equal(calls$tables, 1L)
  expect_equal(calls$resources, 1L)
})

test_that("functions called with a new RO-Crate do not share requests", {
  calls <- mock_project_backend()
  con <- fake_opal_con()

  safe_project(con, project = "CNSIM")
  safe_data(con, project = "CNSIM")

  expect_equal(calls$exists, 2L)
  expect_equal(calls$tables, 2L)
  expect_equal(calls$resources, 2L)
})

test_that("each project in the RO-Crate has its own shared requests", {
  calls <- mock_project_backend()
  con <- fake_opal_con()

  crate <- init(con) |>
    safe_project(project = "P1") |>
    safe_project(project = "P2") |>
    safe_data(project = "P1") |>
    safe_data(project = "P2")

  expect_equal(calls$exists, 2L)
  expect_equal(calls$tables, 2L)
  expect_equal(calls$resources, 2L)
  expect_equal(sort(names(attr(crate, "project_context"))), c("P1", "P2"))
})

test_that("init() discards the requests shared by a previous initialisation", {
  calls <- mock_project_backend()
  con <- fake_opal_con()

  crate <- init(con, project = "CNSIM") |> safe_project()
  expect_equal(calls$tables, 1L)

  crate <- init(con, rocrate = crate, project = "CNSIM")
  expect_null(attr(crate, "project_context"))

  safe_data(crate)
  expect_equal(calls$tables, 2L)
})

test_that("the requests are not shared with a different connection", {
  calls <- mock_project_backend()
  crate <- init(fake_opal_con("user_a"), project = "CNSIM") |> safe_project()

  safe_data(fake_opal_con("user_b"), rocrate = crate, project = "CNSIM")

  expect_equal(calls$tables, 2L)
})

test_that("sharing the requests does not change the RO-Crate", {
  mock_project_backend()
  con <- fake_opal_con()

  shared <- init(con, project = "CNSIM") |>
    safe_project() |>
    safe_data()

  # same steps, without sharing the requests
  separate <- init(con, project = "CNSIM") |>
    safe_project() |>
    reset_project_context() |>
    safe_data()

  expect_equal(shared$`@graph`, separate$`@graph`)
})

test_that("a missing project is reported by every function", {
  local_mocked_bindings(
    validate_backend = function(x, ...) invisible(TRUE),
    project_exists = function(x, ...) stop("project not found", call. = FALSE)
  )
  con <- fake_opal_con()

  expect_error(safe_project(con, project = "NOPE"), "project not found")
  expect_error(safe_data(con, project = "NOPE"), "project not found")
})
