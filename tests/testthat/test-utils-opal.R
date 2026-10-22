test_that("validate_con works with real Opal connection", {
  # open connection to OBiBa's Opal demo server
  opal_con <- opal_demo_con()

  expect_no_error(validate_con(opal_con))

  # close connection to OBiBa's Opal demo server
  opalr::opal.logout(opal_con)
})

test_that("is_admin_con detects admin connection correctly", {
  # open connection to OBiBa's Opal demo server
  opal_con <- opal_demo_con()

  res <- is_admin_con(opal_con)

  expect_type(res, "logical")
  expect_true(res)

  # close connection to OBiBa's Opal demo server
  opalr::opal.logout(opal_con)
})

test_that("validate_con errors on invalid connection object", {
  bad_con <- list(handle = list(handle = NULL))

  expect_error(
    validate_con(bad_con),
    "Unsupported connection type"
  )
})

test_that("user_perm_entity works for all values of 'permission'", {
  input_tbl <- tibble::tibble(
    person = "dsuser",
    person_id = "dsuser",
    asset = "tab1",
    asset_id = "tab1",
    permission = c(
      "view",
      "view-values",
      "edit",
      "edit-values",
      "administrate"
    )
  )

  expect_no_error(
    output_tbl <- purrr::pmap(input_tbl, user_perm_entity)
  )

  expect_length(output_tbl, 5)
  expect_type(output_tbl, "list")
})

test_that("user_perm_entity returns NULL for unknown 'permission'", {
  input_tbl <- tibble::tibble(
    person = "dsuser",
    person_id = "dsuser",
    asset = "tab1",
    asset_id = "tab1",
    permission = "INVALID"
  )

  expect_no_error(
    output_tbl <- purrr::pmap(input_tbl, user_perm_entity)
  )

  expect_null(output_tbl[[1]])
  expect_length(output_tbl, 1)
  expect_type(output_tbl, "list")
})

test_that("safe_desc() returns the description when there is one", {
  expect_equal(
    safe_desc("Baseline cohort", "CNSIM1", "table"),
    "Baseline cohort"
  )
})

test_that("safe_desc() falls back to '<type> <name>' for missing values", {
  expect_equal(safe_desc(NULL, "CNSIM1", "table"), "table CNSIM1")
  expect_equal(safe_desc(NA, "CNSIM1", "table"), "table CNSIM1")
  expect_equal(safe_desc(NA_character_, "CNSIM1", "table"), "table CNSIM1")
  expect_equal(safe_desc("", "CNSIM1", "table"), "table CNSIM1")
})

test_that("safe_desc() uses the asset type in the fallback", {
  expect_equal(safe_desc("", "RSRC", "resource"), "resource RSRC")
})

test_that("safe_desc() returns a single string", {
  res <- safe_desc("", "CNSIM1", "table")

  expect_type(res, "character")
  expect_length(res, 1)
})

test_that("get_project_assets() keeps missing table fields as empty values", {
  local_mocked_bindings(
    project_exists = function(x, project, ...) TRUE,
    backend_tables = function(x, project, ...) {
      list(
        # no `description`, as returned by the demo server
        list(
          name = "CNSIM1",
          link = "/datasource/CNSIM/table/CNSIM1",
          timestamps = list(
            created = "2026-10-13T04:26:14.076Z",
            lastUpdate = "2026-10-13T14:17:32.082Z"
          )
        ),
        # no `link`, but a description
        list(
          name = "CNSIM2",
          description = "Second table",
          timestamps = list(
            created = "2026-10-13T04:26:14.076Z",
            lastUpdate = "2026-10-13T14:17:32.082Z"
          )
        )
      )
    }
  )

  assets <- get_project_assets(fake_opal_con(), "CNSIM", "tables")

  expect_equal(assets$name, c("CNSIM1", "CNSIM2"))
  expect_equal(assets$description, c("", "Second table"))
  expect_false(is.na(assets$url[1]))
  expect_true(is.na(assets$url[2]))
})

test_that("tables without a description get the fallback in the entity", {
  local_mocked_bindings(
    project_exists = function(x, project, ...) TRUE,
    backend_tables = function(x, project, ...) {
      list(
        list(name = "CNSIM1", timestamps = list()),
        list(name = "CNSIM2", description = "Second table", timestamps = list())
      )
    }
  )

  assets <- get_project_assets(fake_opal_con(), "CNSIM", "tables")
  entities <- build_asset_entities(
    assets,
    project_id = "#project:abc",
    asset_id_suffix = "#dataset:"
  )

  expect_equal(entities[[1]]$description, "table CNSIM1")
  expect_equal(entities[[2]]$description, "Second table")
})
