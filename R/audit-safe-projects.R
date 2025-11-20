#' Safe project details
#'
#' Safe project details for the RO-Crate.
#'
#' @param x This can be a connection to a 'DataSHIELD' server (e.g., object with
#'     the `opal` class, see [opalr::opal.login()]), an RO-Crate
#'     ([rocrate][rocrateR::rocrate()] class) or a string with the path to an
#'     RO-Crate.
#' @param ... Other optional arguments.
#' @param project String with project name from which to extra Safe Project
#'     details.
#'
#' @returns Updated RO-Crate object with Safe Project information.
#' @export
#'
# @examples
audit_safe_project <- function(x, ...) {
  UseMethod("audit_safe_project", x)
}

#' @rdname audit_safe_project
#' @export
audit_safe_project.default <- function(x, ...) {
  stop(
    "Unknown class, please try either a file path or",
    " an object with `rocrate` class!"
  )
}

#' @rdname audit_safe_project
#' @export
audit_safe_project.opal <- function(x, ..., project = NULL) {
  # local bindings
  project_tables_all <- subject <- type <- NULL

  # TODO: validate Opal connection
  validate_opal_con(x)

  # if `project` is given, then extract tables associated to that project
  if (!is.null(project)) {
    # check if the given project exists
    project_exists(x, project)

    # retrieve tables for the given project
    project_tables <- get_project_tables(x, project)
    project_tables_all <- tibble::tibble(
      project = project,
      table = project_tables
    )
  } else {
    # extract all data sources
    ds <- opalr::opal.datasources(x)

    # cycle through the data sourcew and extract project and table names
    project_tables_all <- seq_len(nrow(ds)) |>
      lapply(function(i) {
        tryCatch(
          {
            project_name <- ds[i, "name"]
            project_tables <- get_project_tables(x, project_name)
            tibble::tibble(
              project = project_name,
              table = unlist(project_tables)
            )
          },
          error = function(e) {
            return(tibble::tibble(project = project_name))
          }
        )
      }) |>
      dplyr::bind_rows() |>
      dplyr::filter(!is.na(table))
  }

  # get permissions for each table in the project
  # get table permissions
  project_table_permissions_tbl <- seq_len(nrow(project_tables_all)) |>
    lapply(function(i) {
      get_table_permissions(
        x,
        project_tables_all[i, "project"][[1]],
        project_tables_all[i, "table"][[1]]
      )
    }) |>
    dplyr::bind_rows()

  # # filter out project permissions for the given user
  # project_table_permissions_tbl_v2 <- project_table_permissions_tbl |>
  #   dplyr::filter(subject == user, type == "user")
  #
  # # check if any permission records were found for the current project
  # if (nrow(project_table_permissions_tbl_v2) == 0) {
  #   stop(
  #     "The given `project`, does not have any permissions set for the given `user`!",
  #     call. = FALSE
  #   )
  # }

  # create RO-Create with projects and datasets, plus information of users that
  # have access to them
  safe_project_crate <- rocrateR::rocrate_5s()

  ## add safe data and safe project details
  for (p in unique(project_table_permissions_tbl_v2$project)) {
    # filter out tables for the current project
    project_tables <- project_table_permissions_tbl_v2 |>
      dplyr::filter(project == p)
    # add tables for the current project
    safe_project_crate <- safe_project_crate |>
      dsROCrate::safe_data(
        project = p,
        tables = project_tables$table,
        connection = x
      )
    # add project details
    safe_project_crate <- safe_project_crate |>
      dsROCrate::safe_project(project = p, connection = x)
  }

  # TODO: add safe people details; this might require individual RO-crates,
  # as the current setup means that all users have access to all tables in a
  # project, which won't be the case always.

  # return new RO-Crate
  return(invisible(safe_project_crate))
}

#' @rdname audit_safe_project
#' @export
audit_safe_project.rocrate <- function(x, ...) {}
