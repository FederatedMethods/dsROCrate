test_that("safe_project works", {
  # open connection to OBiBa's Opal demo server
  source("opal-demo-server.R")

  basic_rocrate <- rocrateR::rocrate_5s()

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -#
  # - - - - - - - - - - - - - - - - - ERRORS - - - - - - - - - - - - - - - - - #
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -#
  # attempt calling function with invalid class
  expect_error(
    dsROCrate::safe_project(
      structure(list(), class = "InvalidClass"),
      project = NULL
    )
  )

  # attempt calling with invalid connection
  expect_error(
    basic_rocrate |>
      dsROCrate::safe_project(connection = NULL, project = NULL)
  )

  # attempt adding invalid project
  expect_error(
    basic_rocrate |>
      dsROCrate::safe_project(
        project = "Invalid Project",
        connection = opal_con
      )
  )

  # attempt calling without a project
  expect_error(
    basic_rocrate |>
      dsROCrate::safe_project(connection = opal_con)
  )

  # attempt calling with project = NULL
  expect_error(
    basic_rocrate |>
      dsROCrate::safe_project(connection = opal_con, project = NULL)
  )

  # attempt calling with multiple projects
  expect_error(
    basic_rocrate |>
      dsROCrate::safe_project(connection = opal_con, project = c("A", "B"))
  )

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -#
  # - - - - - - - - - - - - - - - - - VALID  - - - - - - - - - - - - - - - - - #
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -#
  # add details for Project without Dataset entities
  basic_rocrate_2 <- basic_rocrate |>
    dsROCrate::safe_project(project = PROJECT, connection = opal_con)

  # add all datasets for a valid project
  basic_rocrate_3 <- basic_rocrate |>
    dsROCrate::safe_data(project = PROJECT, connection = opal_con) |>
    # add the Safe Project details
    dsROCrate::safe_project(project = PROJECT, connection = opal_con)
  ## extract datasets
  basic_rocrate_3_sd <- basic_rocrate_3 |>
    rocrateR::get_entity(type = "Dataset")
  ## extract datasets' names
  basic_rocrate_3_sd_names <- basic_rocrate_3_sd |>
    sapply(getElement, name = "name")
  ## verify that CNSIM1, CNSIM2 and CNSIM3 are part in the crate
  expect_true(all(
    c("CNSIM1", "CNSIM2", "CNSIM3") %in% basic_rocrate_3_sd_names
  ))

  # close connection to OBiBa's Opal demo server
  opalr::opal.logout(opal_con)
})
