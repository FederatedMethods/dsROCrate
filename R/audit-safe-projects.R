#' Audit safe project details
#'
#' Audit safe project details from a 'DataSHIELD' server, an RO-Crate object or
#' a file path pointing to an RO-Crate.
#'
#' @inheritParams safe_people
#' @param ... Other optional arguments, see full documentation for details.
#' @param project String with project name from which to extra Safe Project
#'     details.
#'
#' @returns Updated RO-Crate object with Safe Project information.
#' @export
audit_safe_project <- function(x, ...) {
  UseMethod("audit_safe_project", x)
}

#' @rdname audit_safe_project
#' @export
audit_safe_project.character <- function(x, ...) {
  message("TODO: This generic method hasn't been implemented yet!")
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

  # validate Opal connection
  is_opal_admin_con(x)
  # validate_opal_con(x)

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

    # cycle through the data sources and extract project and table names
    suppressWarnings({
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
    })
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

  # create RO-Create with projects and datasets, plus information of users that
  # have access to them
  safe_project_crate <- rocrateR::rocrate_5s()

  ## add safe data and safe project details
  for (p in unique(project_table_permissions_tbl$project)) {
    # filter out tables for the current project
    project_tables <- project_table_permissions_tbl |>
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

  # get users' details
  safe_people_tbl <- opalr::oadmin.users(x)

  # filter out table permissions based on the users found previously:
  project_table_permissions_tbl <- project_table_permissions_tbl |>
    dplyr::filter(subject %in% safe_people_tbl$name)

  # add Safe People details
  for (i in seq_len(nrow(safe_people_tbl))) {
    safe_project_crate <- safe_project_crate |>
      dsROCrate::safe_people(user = safe_people_tbl$name[i], connection = x)
  }

  # extract Dataset entities from the RO-Crate: @id & name
  safe_data_entities_tbl <- safe_project_crate |>
    flatten_safe_data() |>
    dplyr::rename("table_id" = "id")

  # extract Person entities from the RO-Crate: @id & name
  safe_people_entities_tbl <- safe_project_crate |>
    flatten_safe_people() |>
    dplyr::rename("user_id" = "id")

  ## combine the table permissions with Dataset & People entities' @ids
  project_table_permissions_tbl_v2 <- project_table_permissions_tbl |>
    dplyr::left_join(safe_data_entities_tbl, by = c("table" = "name")) |>
    dplyr::left_join(safe_people_entities_tbl, by = c("subject" = "name")) |>
    dplyr::rename(user = subject)

  ## generate user permission entities and add to the RO-Crate
  user_perm_entity_lst <- project_table_permissions_tbl_v2 |>
    purrr::pmap(user_perm_entity) |>
    purrr::list_c()
  for (i in seq_along(user_perm_entity_lst)) {
    safe_project_crate <- safe_project_crate |>
      rocrateR::add_entity(user_perm_entity_lst[[i]])
  }

  # add Safe Setting details
  safe_project_crate <- x |>
    extract_safe_setting(rocrate = safe_project_crate)

  # return new RO-Crate
  return(invisible(safe_project_crate))
}

#' @rdname audit_safe_project
#' @export
audit_safe_project.rocrate <- function(x, ...) {
  # validate RO-Crate object
  rocrateR::is_rocrate(x)
}
