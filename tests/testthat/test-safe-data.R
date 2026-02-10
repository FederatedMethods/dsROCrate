test_that("safe_data works", {
  # open connection to OBiBa's Opal demo server
  source("opal-demo-server.R")

  basic_rocrate <- rocrateR::rocrate_5s()

  # attempt calling function with invalid class
  expect_error(
    dsROCrate::safe_data(structure(list(), class = "InvalidClass"))
  )

  # attempt calling with invalid connection
  expect_error(
    basic_rocrate |>
      dsROCrate::safe_data(connection = NULL)
  )

  # attempt adding invalid project
  expect_error(
    basic_rocrate |>
      dsROCrate::safe_data(project = "Invalid Project", connection = opal_con)
  )

  # add all datasets for a valid project
  basic_rocrate_2 <- basic_rocrate |>
    dsROCrate::safe_data(project = PROJECT, connection = opal_con)
  ## extract datasets
  basic_rocrate_2_sd <- basic_rocrate_2 |>
    rocrateR::get_entity(type = "Dataset")
  ## extract datasets' names
  basic_rocrate_2_sd_names <- basic_rocrate_2_sd |>
    sapply(getElement, name = "name")
  ## verify that CNSIM1, CNSIM2 and CNSIM3 are part in the crate
  expect_true(all(
    c("CNSIM1", "CNSIM2", "CNSIM3") %in% basic_rocrate_2_sd_names
  ))

  # add specific datasets for a valid project
  basic_rocrate_3 <- basic_rocrate |>
    dsROCrate::safe_data(
      project = PROJECT,
      tables = TABLES,
      connection = opal_con
    )
  ## extract datasets
  basic_rocrate_3_sd <- basic_rocrate_3 |>
    rocrateR::get_entity(type = "Dataset")
  ## verify the length of the datasets is equal to 1 + 1 (root directory)
  expect_equal(length(basic_rocrate_3_sd), 2)

  # close connection to OBiBa's Opal demo server
  opalr::opal.logout(opal_con)
})
