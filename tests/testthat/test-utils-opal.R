test_that("validate_opal_con works with real Opal connection", {
  con <- opal_demo_con()

  expect_no_error(validate_opal_con(con))
})

test_that("is_opal_admin_con detects admin group correctly", {
  con <- opal_demo_con()

  res <- is_opal_admin_con(con)

  expect_type(res, "logical")
  expect_true(res)
})

test_that("get_project_tables retrieves real tables from demo server", {
  con <- opal_demo_con()
  project <- attr(con, "PROJECT")

  tables <- get_project_tables(con, project)

  expect_type(tables, "character")
  expect_true(length(tables) >= 1)
  expect_true(all(nzchar(tables)))
})

test_that("get_project_resources returns resources list from Opal", {
  con <- opal_demo_con()
  project <- attr(con, "PROJECT")

  expect_warning(
    res <- get_project_resources(con, project),
    "The given `project`, does not have any resources associated!"
  )

  expect_true(is.list(res) || is.character(res))
})

test_that("get_project_details works end-to-end with demo Opal project", {
  con <- opal_demo_con()
  project <- attr(con, "PROJECT")

  res <- get_project_details(con, project)

  expect_s3_class(res, "data.frame")
  expect_true("project" %in% names(res))
  expect_true("table" %in% names(res))
  expect_true(nrow(res) >= 1)
  expect_true(all(res$project == project))
})

test_that("get_table_permissions errors for non-admin connection", {
  con <- opal_demo_con(admin = FALSE)
  project <- attr(con, "PROJECT")
  tables <- attr(con, "TABLES")

  expect_error(
    get_table_permissions(con, project, tables),
    "The provided connection does not have access to retrieve table permissions!"
  )
})

test_that("get_table_permissions throws a warning for an invalid project", {
  con <- opal_demo_con()
  tables <- attr(con, "TABLES")

  expect_warning(
    get_table_permissions(con, "INVALID PROJECT", tables),
    "404"
  )
})

test_that("get_table_permissions retrieves real permissions", {
  con <- opal_demo_con()
  project <- attr(con, "PROJECT")
  tables <- attr(con, "TABLES")

  res <- get_table_permissions(con, project, tables)

  expect_s3_class(res, "data.frame")
  expect_true(all(c("project", "table") %in% names(res)))
  expect_equal(unique(res$project), project)
  expect_equal(unique(res$table), tables)
})

test_that("get_project_details handles non-existent project gracefully", {
  con <- opal_demo_con()

  res <- get_project_details(con, "THIS_PROJECT_DOES_NOT_EXIST_123")

  expect_s3_class(res, "data.frame")
  expect_equal(nrow(res), 0)
})

test_that("validate_opal_con errors on invalid connection object", {
  bad_con <- list(handle = list(handle = NULL))

  expect_error(
    validate_opal_con(bad_con),
    "connection is not valid"
  )
})
