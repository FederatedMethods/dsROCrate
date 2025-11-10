test_that("safe_project works", {
  # open connection to OBiBa's Opal demo server
  source("opal-demo-server.R")

  basic_rocrate <- rocrateR::rocrate_5s()

  # attempt calling function with invalid class
  expect_error(
    dsROCrate::safe_project(structure(list(), class = "InvalidClass"))
  )

  # attempt calling with invalid connection
  expect_error(
    basic_rocrate |>
      dsROCrate::safe_project(connection = NULL)
  )

  # attempt adding invalid project
  expect_error(
    basic_rocrate |>
      dsROCrate::safe_project(project = "Invalid Project", connection = opal_con)
  )

  # add details for Project without Dataset entities
  basic_rocrate_2 <- basic_rocrate |>
    dsROCrate::safe_project(project = PROJECT, connection = opal_con)

  # add all datasets for a valid project
  basic_rocrate_3 <- basic_rocrate |>
    dsROCrate::safe_data(project = PROJECT, connection = opal_con) |>
    # add the safe project details
    dsROCrate::safe_project(project = PROJECT, connection = opal_con)
  ## extract datasets
  basic_rocrate_3_sd <- basic_rocrate_3 |>
    rocrateR::get_entity(type = "Dataset")
  ## verify the length of the datasets is equal to 3 + 1 (root directory)
  expect_equal(length(basic_rocrate_3_sd), 4)

  # close connection to OBiBa's Opal demo server
  opalr::opal.logout(opal_con)
})
