test_that("the package defines its own %||% (base R only has it from 4.4.0)", {
  # on R >= 4.4 the base version would hide a missing definition, so check
  # the package namespace directly
  expect_true(
    exists("%||%", envir = asNamespace("dsROCrate"), inherits = FALSE)
  )
})

test_that("%||% returns x when it is not NULL", {
  expect_equal("a" %||% "b", "a")
  expect_equal(1L %||% 2L, 1L)
  expect_equal(list(a = 1) %||% list(), list(a = 1))
})

test_that("%||% only treats NULL as missing", {
  # unlike the helper used before 0.2.4, NA and "" are kept
  expect_identical(NA %||% "b", NA)
  expect_identical(NA_character_ %||% "b", NA_character_)
  expect_identical("" %||% "b", "")
  expect_identical(FALSE %||% TRUE, FALSE)
  expect_identical(0 %||% 1, 0)
  expect_identical(character(0) %||% "b", character(0))
})

test_that("%||% returns y when x is NULL", {
  expect_equal(NULL %||% "b", "b")
  expect_equal(NULL %||% list(), list())
  expect_null(NULL %||% NULL)
})

test_that("%||% works with vectors longer than one", {
  # the old helper used `&&` and errored for these on R >= 4.3
  expect_equal(c("a", "b") %||% "z", c("a", "b"))
})

test_that("%||% evaluates y lazily", {
  expect_equal("a" %||% stop("y must not be evaluated"), "a")
  expect_error(NULL %||% stop("y is evaluated"), "y is evaluated")
})

test_that("%||% agrees with base R's version", {
  skip_if(getRversion() < "4.4.0")
  base_or <- get("%||%", envir = baseenv())

  for (x in list(NULL, "a", NA, "", character(0), 1:3)) {
    expect_identical(x %||% "y", base_or(x, "y"))
  }
})
