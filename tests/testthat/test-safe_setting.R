test_that("safe_setting works", {
  # open connection to OBiBa's Opal demo server
  opal_con <- opal_demo_con()

  basic_rocrate <- rocrateR::rocrate_5s()

  # attempt calling function with invalid class
  expect_error(
    dsROCrate::safe_setting(structure(list(), class = "InvalidClass"))
  )

  # attempt calling with invalid connection
  expect_error(
    basic_rocrate |>
      dsROCrate::safe_setting(connection = NULL)
  )

  # get settings for current server
  basic_rocrate_2 <- basic_rocrate |>
    dsROCrate::safe_setting(connection = opal_con)
  ## extract list of all settings
  basic_rocrate_2_ss <- basic_rocrate_2 |>
    rocrateR::get_entity(type = "PropertyValue")
  ## extract list of software tools
  basic_rocrate_2_tools <- basic_rocrate_2 |>
    rocrateR::get_entity(type = "SoftwareApplication")

  ## check that at least one setting was found in the RO-Crate
  expect_true(length(basic_rocrate_2_ss) >= 1)

  ## check that at least one tool was found in the RO-Crate
  expect_true(length(basic_rocrate_2_tools) >= 1)

  # close connection to OBiBa's Opa
})
