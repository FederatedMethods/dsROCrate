#' Audit Safe Project details
#'
#' Audit Safe Project details from a 'DataSHIELD' server, an RO-Crate object or
#' a file path pointing to an RO-Crate.
#'
#' @inheritParams safe_people
#' @param ... Other optional arguments, see full documentation for details.
#' @param project String with project name from which to extra Safe Project
#'     details.
#' @param logs_from Lower limit timestamp to filter out the outputs generated
#'     (default: `-Inf`, everything up to `logs_to`)
#' @param logs_to Upper limit timestamp to filter out the outputs generated
#'     (default: `Inf`, everything from `logs_from` onwards).
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
audit_safe_project.opal <- function(
  x,
  ...,
  project = NULL,
  logs_from = -Inf,
  logs_to = Inf
) {
  # local bindings
  project_tables_all <- subject <- table <- type <- NULL

  # validate Opal connection
  is_opal_admin_con(x)
  # validate_opal_con(x)

  # if `project` is given, then extract tables associated to that project
  if (!is.null(project)) {
    project_tables_all <- project |>
      lapply(function(p) {
        tryCatch(
          {
            # check if the given project exists
            project_exists(x, project = p)

            # retrieve tables for the given project
            project_tables <- get_project_tables(x, p)
            tibble::tibble(
              project = p,
              table = project_tables
            )
          },
          error = function(e) {
            return(tibble::tibble(project = p, table = NA))
          }
        )
      }) |>
      dplyr::bind_rows() |>
      dplyr::filter(!is.na(table))
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

  # add check to determine if project information was found:
  if (nrow(project_tables_all) == 0) {
    stop(
      paste0(
        "No data details were found for given project",
        ifelse(length(project) == 1, "", "s"),
        "!"
      ),
      call. = FALSE
    )
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

  ## add Safe Data and Safe Project details
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
  safe_people_tbl <- opalr::opal.get(x, "/system/subject-profiles/") |>
    dplyr::bind_rows() |>
    dplyr::rename(name = principal) |>
    # exclude system administrators from the report
    dplyr::filter(!(tolower(name) %in% c("admin", "administrator"))) |>
    # filter out users that don't have access to the given project(s)
    dplyr::filter(name %in% project_table_permissions_tbl$subject)

  # filter out table permissions based on the users found previously:
  project_table_permissions_tbl <- project_table_permissions_tbl |>
    dplyr::filter(subject %in% safe_people_tbl$name)

  # add Safe People details
  for (i in seq_len(nrow(safe_people_tbl))) {
    safe_project_crate <- safe_project_crate |>
      dsROCrate::safe_people(
        user = safe_people_tbl$name[i],
        connection = x,
        set_author = FALSE,
        set_project = FALSE
      )
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

  # add Safe Output details
  for (u in safe_people_entities_tbl$name) {
    # # suppress warnings, as some users might not have logs in the given period
    # suppressWarnings({
    safe_project_crate <- x |>
      extract_safe_output(
        user = u,
        logs_to = logs_to,
        logs_from = logs_from,
        rocrate = safe_project_crate
      )
    # })
  }

  # return new RO-Crate
  return(safe_project_crate)
}

#' @rdname audit_safe_project
#' @export
audit_safe_project.rocrate <- function(x, ...) {
  # validate RO-Crate object
  rocrateR::is_rocrate(x)
}
