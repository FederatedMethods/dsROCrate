test_that("show() prints expired credentials message", {
  obj <- new(
    "ArmadilloCredentials",
    auth_type = "bearer",
    token_type = "JWT",
    expires_at = Sys.time() - 3600
  )

  expect_output(
    show(obj),
    "Connection expired!"
  )
})

test_that("show() prints credential details when not expired", {
  expires_at <- as.POSIXct("2030-01-01 00:00:00", tz = "UTC")

  obj <- new(
    "ArmadilloCredentials",
    auth_type = "bearer",
    token_type = "JWT",
    expires_at = expires_at
  )

  expect_output(show(obj), "<ArmadilloCredentials>")
  expect_output(show(obj), "auth type: bearer")
  expect_output(show(obj), "token type: JWT")
  expect_output(
    show(obj),
    format(expires_at, tz = "UTC")
  )
})

test_that("show() output is correct for expired credentials", {
  obj <- new(
    "ArmadilloCredentials",
    auth_type = "bearer",
    token_type = "JWT",
    expires_at = Sys.time() - 1
  )

  out <- paste(capture.output(show(obj)), collapse = "\n")

  expect_true(grepl("<ArmadilloCredentials>", out))
  expect_true(grepl("Connection expired!", out))
  expect_true(grepl("armadillo_login", out))
})
