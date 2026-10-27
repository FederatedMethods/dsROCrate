test_that("validate_con works with real Opal connection", {
  # open connection to OBiBa's Opal demo server
  opal_con <- opal_demo_con()

  expect_no_error(validate_con(opal_con))

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

# shape of `opal.tables(df = FALSE)` / `opal.resources(df = FALSE)` on the Opal
# demo server (project CNSIM).
fixture_opal_tables <- function() {
  list(
    list(
      name = "CNSIM1",
      entityType = "Participant",
      link = "/datasource/CNSIM/table/CNSIM1",
      datasourceName = "CNSIM",
      timestamps = list(
        created = "2026-10-13T04:26:14.076Z",
        lastUpdate = "2026-10-13T14:17:32.082Z"
      ),
      status = "READY"
    ),
    list(
      name = "CNSIM2",
      entityType = "Participant",
      link = "/datasource/CNSIM/table/CNSIM2",
      datasourceName = "CNSIM",
      timestamps = list(
        created = "2026-10-13T04:26:14.076Z",
        lastUpdate = "2026-10-13T14:17:32.082Z"
      ),
      status = "READY"
    )
  )
}

# time zones on both sides of UTC, with and without daylight saving
test_zones <- c("UTC", "America/New_York", "Europe/London", "Pacific/Auckland")

test_that("safe_time() reads backend timestamps as UTC in any time zone", {
  inputs <- c(
    z = "2026-10-13T04:26:14Z",
    fraction = "2026-10-13T04:26:14.076Z",
    nanoseconds = "2026-10-13T04:26:14.076468641Z",
    plus_0000 = "2026-10-13T04:26:14+0000",
    plus_offset = "2026-10-13T06:26:14+02:00",
    minus_offset = "2026-10-12T23:26:14-0500",
    space_separator = "2026-10-13 04:26:14"
  )

  for (tz in test_zones) {
    withr::with_timezone(tz, {
      for (nm in names(inputs)) {
        expect_equal(
          safe_time(inputs[[nm]]),
          "2026-10-13T04:26:14Z",
          info = paste(tz, nm)
        )
      }
    })
  }
})

test_that("safe_time() accepts POSIXct values, whatever their time zone", {
  withr::local_timezone("America/New_York")

  utc <- as.POSIXct("2026-10-13 04:26:14", tz = "UTC")
  ny <- as.POSIXct("2026-10-13 00:26:14", tz = "America/New_York")

  expect_equal(safe_time(utc), "2026-10-13T04:26:14Z")
  expect_equal(safe_time(ny), "2026-10-13T04:26:14Z")
})

test_that("safe_time() returns an empty string for missing or invalid input", {
  withr::local_timezone("America/New_York")

  expect_identical(safe_time(NULL), "")
  expect_identical(safe_time(NA), "")
  expect_identical(safe_time(NA_character_), "")
  expect_identical(safe_time(""), "")
  expect_identical(safe_time("not a date"), "")
  expect_identical(safe_time(c("2026-10-13T04:26:14Z", "x")), "")
})

test_that("safe_time() is idempotent (it is applied twice to asset timestamps)", {
  for (tz in test_zones) {
    withr::with_timezone(tz, {
      once <- safe_time("2026-10-13T04:26:14.076Z")

      expect_equal(safe_time(once), once, info = tz)
      expect_identical(safe_time(safe_time(NULL)), "", info = tz)
    })
  }
})

test_that("safe_time() gives the same result in every time zone", {
  results <- vapply(
    test_zones,
    function(tz) {
      withr::with_timezone(tz, safe_time("2026-10-13T04:26:14.076Z"))
    },
    character(1)
  )

  expect_length(unique(results), 1)
})

test_that("get_project_assets() returns UTC timestamps for tables", {
  local_mocked_bindings(
    project_exists = function(x, project, ...) TRUE,
    backend_tables = function(x, project, ...) fixture_opal_tables()
  )

  for (tz in test_zones) {
    withr::with_timezone(tz, {
      assets <- get_project_assets(fake_opal_con(), "CNSIM", "tables")

      expect_equal(
        assets$created,
        rep("2026-10-13T04:26:14Z", 2),
        info = tz
      )
      expect_equal(
        assets$updated,
        rep("2026-10-13T14:17:32Z", 2),
        info = tz
      )
    })
  }
})

test_that("table entities have dateCreated/dateModified in UTC", {
  local_mocked_bindings(
    project_exists = function(x, project, ...) TRUE,
    backend_tables = function(x, project, ...) fixture_opal_tables()
  )

  for (tz in test_zones) {
    withr::with_timezone(tz, {
      assets <- get_project_assets(fake_opal_con(), "CNSIM", "tables")
      entities <- build_asset_entities(
        assets,
        project_id = "#project:abc",
        asset_id_suffix = "#dataset:"
      )

      expect_length(entities, 2)
      for (e in entities) {
        expect_equal(e$dateCreated, "2026-10-13T04:26:14Z", info = tz)
        expect_equal(e$dateModified, "2026-10-13T14:17:32Z", info = tz)
      }
    })
  }
})

test_that("resource entities have dateCreated/dateModified in UTC", {
  local_mocked_bindings(
    project_exists = function(x, project, ...) TRUE,
    backend_resources = function(x, project, ...) {
      list(
        list(
          name = "RSRC1",
          created = "2026-10-13T04:26:14.076Z",
          updated = "2026-10-13T14:17:32.082Z",
          parameters = "",
          resource = list(url = "https://example.org/data.csv")
        )
      )
    }
  )

  for (tz in test_zones) {
    withr::with_timezone(tz, {
      assets <- get_project_assets(fake_opal_con(), "CNSIM", "resources")
      entities <- build_asset_entities(
        assets,
        project_id = "#project:abc",
        asset_id_suffix = "#dataset:"
      )

      expect_equal(entities[[1]]$dateCreated, "2026-10-13T04:26:14Z", info = tz)
      expect_equal(
        entities[[1]]$dateModified,
        "2026-10-13T14:17:32Z",
        info = tz
      )
    })
  }
})

test_that("assets without timestamps get empty dates, not NA", {
  local_mocked_bindings(
    project_exists = function(x, project, ...) TRUE,
    backend_tables = function(x, project, ...) {
      list(list(name = "CNSIM1", timestamps = list()))
    }
  )
  withr::local_timezone("America/New_York")

  assets <- get_project_assets(fake_opal_con(), "CNSIM", "tables")
  entities <- build_asset_entities(assets, "#project:abc", "#dataset:")

  expect_identical(entities[[1]]$dateCreated, "")
  expect_identical(entities[[1]]$dateModified, "")
})
