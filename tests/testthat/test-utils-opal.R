test_that("validate_opal_con works with real Opal connection", {
  # open connection to OBiBa's Opal demo server
  opal_con <- opal_demo_con()

  expect_no_error(validate_opal_con(opal_con))

  # close connection to OBiBa's Opal demo server
  opalr::opal.logout(opal_con)
})

test_that("is_opal_admin_con detects admin group correctly", {
  # open connection to OBiBa's Opal demo server
  opal_con <- opal_demo_con()

  res <- is_opal_admin_con(opal_con)

  expect_type(res, "logical")
  expect_true(res)

  # close connection to OBiBa's Opal demo server
  opalr::opal.logout(opal_con)
})

test_that("validate_opal_con errors on invalid connection object", {
  bad_con <- list(handle = list(handle = NULL))

  expect_error(
    validate_opal_con(bad_con),
    "connection is not valid"
  )
})

test_that("update_project_datasets updates project entities of an RO-Crate", {
  # open connection to OBiBa's Opal demo server
  opal_con <- opal_demo_con()

  # create basic RO-Crate with a project
  rocrate <- rocrateR::rocrate_5s() |>
    dsROCrate::safe_project(
      connection = opal_con,
      project = attr(opal_con, "PROJECT")
    )

  # update project datasets
  expect_no_error(
    rocrate <- rocrate |>
      update_project_datasets(project = attr(opal_con, "PROJECT"), ds_ids = 1:5)
  )

  # extract `hasPart` for the project entity
  expect_no_error(
    has_part <- rocrateR::get_entity(rocrate, type = "Project") |>
      sapply(getElement, name = "hasPart") |>
      sapply(getElement, name = "@id") |>
      unlist()
  )

  expect_equal(length(has_part), 5)
  expect_equal(has_part, 1:5)

  # close connection to OBiBa's Opal demo server
  opalr::opal.logout(opal_con)
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
