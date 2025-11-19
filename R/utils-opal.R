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
      # get permissions for each dataset inside each project
      opalr::opal.table_perm(x, project, tables[j]) |>
        dplyr::mutate(table = tables[j], .before = 1)
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
