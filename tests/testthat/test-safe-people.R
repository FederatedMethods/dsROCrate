test_that("safe_people works", {
  # open connection to OBiBa's Opal demo server
  source("opal-demo-server.R")

  basic_rocrate <- rocrateR::rocrate_5s()

  # attempt calling function with invalid class
  expect_error(
    dsROCrate::safe_people(structure(list(), class = "InvalidClass"))
  )

  # attempt adding user to RO-Crate without project entity, `@type = 'Project`
  expect_warning(
    basic_rocrate_1 <- opal_con |>
      dsROCrate::safe_people(rocrate = basic_rocrate, user = PEOPLE)
  )

  # attempt calling with invalid connection
  expect_error(
    basic_rocrate |>
      dsROCrate::safe_people(user = PEOPLE, connection = NULL)
  )

  # add project entity to the RO-Crate
  basic_rocrate_2 <- basic_rocrate |>
    rocrateR::add_entity(rocrateR::entity("Fake Project", type = "Project"))

  # add default safe people details (user logged in)
  basic_rocrate_3 <- basic_rocrate_2 |>
    dsROCrate::safe_people(connection = opal_con)
  ## retrieve safe_people entity
  basic_rocrate_2_sp <- basic_rocrate_3 |>
    rocrateR::get_entity(type = "Person")
  expect_equal(length(basic_rocrate_2_sp), 1)

  # add custom safe people
  basic_rocrate_4 <- basic_rocrate_2 |>
    dsROCrate::safe_people(
      connection = opal_con,
      user = list(id = "test_user", name = "Test User")
    )
  ## retrieve safe_people entity
  basic_rocrate_4_sp <- basic_rocrate_4 |>
    rocrateR::get_entity(type = "Person")
  expect_equal(length(basic_rocrate_4_sp), 1)

  # close connection to OBiBa's Opal demo server
  opalr::opal.logout(opal_con)
})
