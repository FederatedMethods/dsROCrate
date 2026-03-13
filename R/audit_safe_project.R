#' Audit Safe Project details
#'
#' Audit Safe Project details from a 'DataSHIELD' server, an RO-Crate object or
#' a file path pointing to an RO-Crate.
#'
#' @inheritParams audit_safe_people
#' @param ... Other optional arguments, see full documentation for details.
#'
#' @returns Updated RO-Crate object with Safe Project information.
#' @export
audit_safe_project <- function(x, ...) {
  UseMethod("audit_safe_project")
}

#' @rdname audit_safe_project
#' @export
audit_safe_project.default <- function(x, ...) {
  stop(
    "Unknown class, please try with a connection object (e.g., OBiBa's Opal)!"
  )
}

#' @rdname audit_safe_project
#' @export
audit_safe_project.opal <- function(
  x,
  ...,
  project = NULL,
  logs_from = -Inf,
  logs_to = Inf,
  path = NULL
) {
  # local bindings
  name <- principal <- project_tables_all <- subject <- table <- type <- NULL

  # validate Opal connection
  is_opal_admin_con(x)
  # validate_opal_con(x)

  # if `project` is missing, then extract all project names
  if (is.null(project)) {
    # extract all data sources
    ds <- opalr::opal.datasources(x)

    project <- ds[, "name"]
  }

  suppressWarnings({
    project_tables_all <- x |>
      get_project_details(project)
  })

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
  # ignore warnings about existing permission entities
  suppressWarnings({
    safe_project_crate <- user_perm_entity_lst |>
      purrr::reduce(
        rocrateR::add_entity,
        overwrite = TRUE,
        .init = safe_project_crate
      )
  })

  # add Safe Setting details
  safe_project_crate <- x |>
    extract_safe_setting(rocrate = safe_project_crate)

  # add Safe Output details
  for (u in safe_people_entities_tbl$name) {
    # # suppress warnings, as some users might not have logs in the given period
    # suppressWarnings({
    safe_project_crate <- x |>
      extract_safe_output(
        path = path,
        user = u,
        logs_to = logs_to,
        logs_from = logs_from,
        rocrate = safe_project_crate,
      )
    # })
  }

  # attach input args as attributes to the RO-Crate
  attr(safe_project_crate, "audit_type") <- "Safe Project"
  attr(safe_project_crate, "path") <- path
  attr(safe_project_crate, "project") <- project

  # return new RO-Crate
  return(safe_project_crate)
}
