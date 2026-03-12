#' Audit Safe People details
#'
#' Audit Safe People details from a 'DataSHIELD' server, an RO-Crate object or
#' a file path pointing to an RO-Crate.
#'
#' @inheritParams init
#' @param x This can be a connection to a 'DataSHIELD' server (e.g., object with
#'     the `opal` class, see [opalr::opal.login()]).
#' @param ... Other optional arguments, see full documentation for details.
#' @param user String with the user name for which to extract Safe People
#'     details.
#' @param project String with project name(s) from which to extra Safe People
#'     details.
#' @param logs_from Lower limit timestamp to filter out the outputs generated
#'     (default: `-Inf`, everything up to `logs_to`)
#' @param logs_to Upper limit timestamp to filter out the outputs generated
#'     (default: `Inf`, everything from `logs_from` onwards).
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
audit_safe_people.default <- function(x, ...) {
  stop(
    "Unknown class, please try with a connection object (e.g., OBiBa's Opal)!"
  )
}

#' @rdname audit_safe_people
#' @export
audit_safe_people.opal <- function(
  x,
  ...,
  user,
  project = NULL,
  logs_from = -Inf,
  logs_to = Inf,
  path = NULL
) {
  # local bindings
  project_tables_all <- subject <- type <- NULL

  # validate Opal connection
  is_opal_admin_con(x)

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
    dplyr::filter(subject %in% user, type == "user")

  # check if any permission records were found for the current project
  if (nrow(project_table_permissions_tbl_v2) == 0) {
    stop(
      "The given `project`, does not have any permissions set for the given `user`!",
      call. = FALSE
    )
  }

  # create RO-Create with user, projects and datasets they have access to
  safe_people_crate <- rocrateR::rocrate_5s()

  ## add Safe Data and Safe Project details
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
  for (i in seq_len(length(user))) {
    safe_people_crate <- safe_people_crate |>
      dsROCrate::safe_people(
        user = user[i],
        connection = x,
        set_author = FALSE,
        set_project = FALSE
      )
  }

  # extract Dataset entities from the RO-Crate: @id & name
  safe_data_entities_tbl <- safe_people_crate |>
    flatten_safe_data() |>
    dplyr::rename("table_id" = "id")

  # extract Person entities from the RO-Crate: @id & name
  safe_people_entities_tbl <- safe_people_crate |>
    flatten_safe_people() |>
    dplyr::rename("user_id" = "id")

  ## combine the table permissions with Dataset & People entities' @ids
  project_table_permissions_tbl_v3 <- project_table_permissions_tbl |>
    dplyr::filter(subject %in% user, type == "user") |>
    dplyr::left_join(safe_data_entities_tbl, by = c("table" = "name")) |>
    dplyr::left_join(safe_people_entities_tbl, by = c("subject" = "name")) |>
    dplyr::rename(user = subject)

  ## generate user permission entities and add to the RO-Crate
  user_perm_entity_lst <- project_table_permissions_tbl_v3 |>
    purrr::pmap(user_perm_entity) |>
    purrr::list_c()

  # ignore warnings about existing permission entities
  suppressWarnings({
    safe_people_crate <- user_perm_entity_lst |>
      purrr::reduce(
        rocrateR::add_entity,
        overwrite = TRUE,
        .init = safe_people_crate
      )
  })

  # add Safe Setting details
  safe_people_crate <- x |>
    extract_safe_setting(rocrate = safe_people_crate)

  # add Safe Output details
  safe_people_crate <- x |>
    extract_safe_output(
      path = path,
      user = safe_people_entities_tbl$name,
      logs_to = logs_to,
      logs_from = logs_from,
      rocrate = safe_people_crate
    )

  # attach input args as attributes to the RO-Crate
  attr(safe_people_crate, "audit_type") <- "Safe People"
  attr(safe_people_crate, "path") <- path
  attr(safe_people_crate, "project") <- project
  attr(safe_people_crate, "user") <- user

  # return new RO-Crate
  return(safe_people_crate)
}
