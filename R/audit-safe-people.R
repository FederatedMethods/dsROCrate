#' Audit Safe People details
#'
#' Audit Safe People details from a 'DataSHIELD' server, an RO-Crate object or
#' a file path pointing to an RO-Crate.
#'
#' @param x This can be a connection to a 'DataSHIELD' server (e.g., object with
#'     the `opal` class, see [opalr::opal.login()]), an RO-Crate
#'     ([rocrate][rocrateR::rocrate()] class) or a string with the path to an
#'     RO-Crate.
#' @param ... Other optional arguments, see full documentation for details.
#' @param user String with the user name for which to extract Safe People
#'     details.
#' @param project String with project name(s) from which to extra Safe People
#'     details.
#'
#' @returns Updated RO-Crate object with Safe People information.
#' @export
#'
# @examples
audit_safe_people <- function(x, ...) {
  UseMethod("audit_safe_people", x)
}

#' @rdname audit_safe_people
#' @export
audit_safe_people.character <- function(x, ...) {
  message("TODO: This generic method hasn't been implemented yet!")
}

#' @rdname audit_safe_people
#' @export
audit_safe_people.default <- function(x, ...) {
  stop(
    "Unknown class, please try either a file path or",
    " an object with `rocrate` class!"
  )
}

#' @rdname audit_safe_people
#' @export
audit_safe_people.opal <- function(x, ..., user, project = NULL) {
  # local bindings
  project_tables_all <- subject <- type <- NULL

  # validate Opal connection
  is_opal_admin_con(x)

  # if `project` is given, then extract tables associated to that project
  if (!is.null(project)) {
    # check if the given project(s) can be found in the given server
    sapply(project, \(p) project_exists(x, p))

    # retrieve tables for the given project(s)
    project_tables_all <- project |>
      lapply(function(p) {
        tibble::tibble(
          project = p,
          table = get_project_tables(x, p)
        )
      }) |>
      dplyr::bind_rows()
  } else {
    # extract all data sources
    ds <- opalr::opal.datasources(x)

    # cycle through the data sources and extract project and table names
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

  # filter out project permissions for the given user
  project_table_permissions_tbl_v2 <- project_table_permissions_tbl |>
    dplyr::filter(subject == user, type == "user")

  # check if any permission records were found for the current project
  if (nrow(project_table_permissions_tbl_v2) == 0) {
    stop(
      "The given `project`, does not have any permissions set for the given `user`!",
      call. = FALSE
    )
  }

  # create RO-Create with user, projects and datasets they have access to
  safe_people_crate <- rocrateR::rocrate_5s()

  ## add safe data and safe project details
  for (p in unique(project_table_permissions_tbl_v2$project)) {
    # filter out tables for the current project
    project_tables <- project_table_permissions_tbl_v2 |>
      dplyr::filter(project == p)
    # add tables for the current project
    safe_people_crate <- safe_people_crate |>
      dsROCrate::safe_data(
        project = p,
        tables = project_tables$table,
        connection = x
      )
    # add project details
    safe_people_crate <- safe_people_crate |>
      dsROCrate::safe_project(project = p, connection = x)
  }

  # add Safe People details
  safe_people_crate <- safe_people_crate |>
    dsROCrate::safe_people(user = user, connection = x)

  # add Safe Setting details
  safe_people_crate <- x |>
    extract_safe_setting(rocrate = safe_people_crate)

  # return new RO-Crate
  return(invisible(safe_people_crate))
}

#' @rdname audit_safe_people
#' @export
audit_safe_people.rocrate <- function(x, ...) {
  # validate RO-Crate object
  rocrateR::is_rocrate(x)

  # extract Safe People entities
  safe_people_ents <- extract_safe_people(x)

  # return invisibly
  return(invisible(safe_people_ents))
}
