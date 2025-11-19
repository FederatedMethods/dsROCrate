#' Get project tables
#'
#' Wrapper for [opalr::opal.project()].
#'
#' @inheritParams get_table_permissions
#'
#' @returns List of project tables
#' @keywords internal
#'
#' @family Opal
get_project_tables <- function(x, project) {
  # verify if project exists
  project_exists(x, project)

  # extract table names associated to `project`
  project_tables <- opalr::opal.project(x, project) |>
    getElement("datasource") |>
    getElement("table") |>
    unlist()

  # verify if `project_tables` is missing or NULL, if so, print warning message
  if (all(is.na(project_tables)) || all(is.null(project_tables))) {
    warning(
      "The given `project`, does not have any tables associated!",
      call. = FALSE
    )
  }

  # return project tables
  return(project_tables)
}

#' Get table permissions
#'
#' Wrapper for the [opalr::opal.table_perm()] function.
#'
#' @param x Connection to OBiBa's Opal server (see [opalr::opal.login()]).
#' @param project String with project name.
#' @param tables String (or vector of strings) with table names for the given
#'     project.
#'
#' @returns Data frame with permissions for each table in `tables`.
#' @keywords internal
#'
#' @family Opal
get_table_permissions <- function(x, project, tables) {
  seq_along(tables) |>
    lapply(function(j) {
      tryCatch(
        {
          tibble::tibble(
            project = project,
            table = tables[j],
            # get permissions for each dataset inside each project
            opalr::opal.table_perm(x, project, tables[j])
          )
        },
        error = function(e) {
          if (grepl("HTTP 403", e$message)) {
            stop(
              "The provided connection does not have access to retrieve ",
              "table permissions!",
              call. = FALSE
            )
          } else if (grepl("HTTP 404", e$message)) {
            warning(
              "Error when retrieving permissions for ",
              paste0(project, ".", tables[j], "!"),
              call. = FALSE
            )
          } else {
            warning(e$message, call. = FALSE)
          }

          # return empty tibble, only with `project` and `table` details
          return(tibble::tibble(
            project = project,
            table = tables[j]
          ))
        }
      )
    }) |>
    # combine results from the permissions for each table
    dplyr::bind_rows()
}

#' Verify if project exists
#'
#' Wrapper for the [opalr::opal.project_exists()] function.
#'
#' @inheritParams get_table_permissions
#'
#' @returns Nothing, call for its side effect. Stop execution of script if
#' `project` does not exist in the given server.
#'
#' @keywords internal
#'
#' @family Opal
project_exists <- function(x, project) {
  if (!opalr::opal.project_exists(x, project)) {
    stop(
      "The project given `project` was not found in the given Opal connection!",
      call. = FALSE
    )
  }
}
