#' Safe people details
#'
#' Safe people details for the RO-Crate.
#'
#' @param x This can be a connection to a 'DataSHIELD' server (e.g., object with
#'     the `opal` class, see [opalr::opal.login()]), an RO-Crate
#'     ([rocrate][rocrateR::rocrate()] class) or a string with the path to an
#'     RO-Crate.
#' @param ... Other optional arguments.
#' @param user String with the user name for which to extract Safe People
#'     details.
#' @param project String with project name from which to extra Safe People
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

  # TODO: validate Opal connection

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

  # add safe people details
  safe_people_crate <- safe_people_crate |>
    dsROCrate::safe_people(user = user, connection = x)

  # opalr::oadmin.users(o)
  # opalr::oadmin.user_profiles(o)
  # p <- opalr::opal.projects(o)
  # opalr::opal.table_perm(o, "CNSIM", "CNSIM1")
  # opalr::opal.table_perm(o, "CADSET-coh1", NA)
  # opalr::opal.perms(o, subject = "dsuser")

  # return new RO-Crate
  return(invisible(safe_people_crate))
}

#' @rdname audit_safe_people
#' @export
audit_safe_people.rocrate <- function(x, ...) {
  # TODO: validate RO-Crate object

  # extract author `@id`s from the root directory
  author_ids <- rocrateR::get_entity(x, id = "./", type = "Dataset") |>
    lapply(\(x) getElement(x, "author")) |>
    sapply(\(x) getElement(x, "@id"))

  # extract entities with type = 'Person'
  person_entities <- rocrateR::get_entity(x, type = "Person")

  # filter out person-entities in the `author_ids`
  idx <- person_entities |>
    sapply(\(x) getElement(x, "@id") %in% author_ids)
  person_entities_v2 <- person_entities[idx]

  # check if any entities were found
  if (length(person_entities_v2) == 0) {
    stop(
      "No matching entities were found for the Author(s) in the root ",
      "entity (./):\n",
      paste0("  - ", author_ids, collapse = "\n"),
      call. = FALSE
    )
  } else {
    message(
      length(person_entities_v2),
      " 'Author' entit",
      ifelse(length(person_entities_v2) == 1, "y was", "ies were"),
      " found!"
    )
  }

  # return invisibly
  return(invisible(person_entities_v2))
}
