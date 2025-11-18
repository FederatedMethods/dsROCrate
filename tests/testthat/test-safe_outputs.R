test_that("safe_output works", {
  # open connection to OBiBa's Opal demo server
  source("opal-demo-server.R")

  basic_rocrate <- rocrateR::rocrate_5s()

  # attempt calling function with invalid class
  expect_error(
    dsROCrate::safe_output(structure(list(), class = "InvalidClass"))
  )

  # attempt calling with invalid connection
  expect_error(
    basic_rocrate |>
      dsROCrate::safe_output(connection = NULL)
  )

  # attempt extracting outputs from an RO-Crate without safe people details
  expect_warning(
    basic_rocrate |>
      dsROCrate::safe_output(connection = opal_con)
  )

  # add safe people details
  ## add project entity to the RO-Crate
  basic_rocrate_2 <- basic_rocrate |>
    rocrateR::add_entity(rocrateR::entity("Fake Project", type = "Project"))

  ## add safe people details for
  basic_rocrate_3 <- basic_rocrate_2 |>
    dsROCrate::safe_people(connection = opal_con, user = PEOPLE)

  # call the function with an RO-Crate with multiple users
  basic_rocrate_4 <- basic_rocrate_3 |>
    # add another username
    dsROCrate::safe_people(
      connection = opal_con,
      user = list(id = "extra_username", name = "Extra username")
    ) |>
    # set multiple users as the author
    rocrateR::add_entity_value(
      id = "./",
      key = "author",
      value = list(
        list(`@id` = "extra_username"),
        list(`@id` = paste0("#person:", digest::digest("dsuser")))
      )
    )

  # test for warning about multiple authors in the root entity
  expect_warning(
    basic_rocrate_4 |>
      dsROCrate::safe_output(connection = opal_con)
  )

  # close connection to OBiBa's Opal demo server
  opalr::opal.logout(opal_con)

  # simulate DataSHIELD operations
  ## run some test commands with dsBaseClient
  ### needed to defined the OpalDriver class in the current environment
  DSOpal::Opal()
  ### create new login object, note that here we use the `dsuser`
  builder <- DSI::newDSLoginBuilder()
  builder$append(
    server = "study1",
    url = SERVER,
    user = "dsuser",
    password = DSUSERPASS,
    driver = "OpalDriver"
  )
  logindata <- builder$build()
  conns <- DSI::datashield.login(logins = logindata)

  ### assign data
  DSI::datashield.assign.table(
    conns["study1"],
    symbol = "dsROCrate_test",
    table = paste0(PROJECT, ".", TABLES[1]),
    errors.print = TRUE
  )

  dsBaseClient::ds.ls(datasources = conns["study1"])

  ## open connection to OBiBa's Opal demo server
  source("opal-demo-server.R")

  expect_warning(
    basic_rocrate_5 <- basic_rocrate_3 |>
      dsROCrate::safe_output(
        connection = opal_con,
        logs_from = Sys.time() - 60, # capture the last min
        logs_to = Sys.time(),
        user = "dsuser"
      )
  )

  # run function with logs for an invalid period (no logs)
  expect_warning(
    basic_rocrate_6 <- basic_rocrate_3 |>
      dsROCrate::safe_output(
        connection = opal_con,
        logs_from = Sys.time() - 60^2 * 24, # 1 day ago
        logs_to = Sys.time() - 60^2 * 23,
        user = "dsuser"
      )
  )

  # provide invalid path to write the logs
  expect_warning(
    basic_rocrate_7 <- basic_rocrate_3 |>
      dsROCrate::safe_output(
        connection = opal_con,
        logs_from = Sys.time() - 60^2 * 24, # 1 day ago
        logs_to = Sys.time(),
        user = "dsuser",
        path = "/invalid/path/rocrateR"
      )
  )

  # write logs in temporary file
  tempdir_name <- tempdir()
  on.exit(unlink(tempdir_name, force = TRUE, recursive = TRUE))
  expect_true(dir.exists(tempdir_name))
  basic_rocrate_8 <- basic_rocrate_3 |>
    dsROCrate::safe_output(
      connection = opal_con,
      logs_from = Sys.time() - 60, # capture the last min
      logs_to = Sys.time(),
      user = "dsuser",
      path = tempdir_name
    )
  unlink(tempdir_name, force = TRUE, recursive = TRUE)
  expect_false(dir.exists(tempdir_name))

  # close connection to OBiBa's Opal demo server
  opalr::opal.logout(opal_con)
})
