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
  name <- principal <- NULL

  # create RO-Create with projects and datasets, plus information of users that
  # have access to them
  crate <- rocrateR::rocrate_5s()

  # validate Opal connection
  is_opal_admin_con(x)

  # if `project` is missing, then extract all project names
  if (is.null(project)) {
    # extract all data sources
    ds <- opalr::opal.datasources(x)

    project <- ds[, "name"]
  }

  # Safe People ----
  # get users' details
  safe_people_tbl <- opalr::opal.get(x, "/system/subject-profiles/") |>
    dplyr::bind_rows() |>
    dplyr::rename(name = principal) |>
    # exclude system administrators from the report
    dplyr::filter(!(tolower(name) %in% c("admin", "administrator")))

  crate <- safe_people_tbl$name |>
    purrr::reduce(
      \(crate, username) {
        safe_people(
          crate,
          connection = x,
          user = username,
          set_author = FALSE,
          set_project = FALSE
        )
      },
      .init = crate
    )

  # Safe Projects ----
  crate <- project |>
    purrr::reduce(
      \(crate, p) {
        safe_project(crate, connection = x, project = p)
      },
      .init = crate
    )

  # Safe Data ----
  crate <- project |>
    purrr::reduce(
      \(crate, p) {
        safe_data(crate, connection = x, project = p)
      },
      .init = crate
    )

  # remove permissions associated with admin users
  non_admin_user_ids <- safe_people_tbl$name |>
    purrr::map_chr(id_hash, prefix = "#person:")
  admin_perm_ents <- crate$`@graph` |>
    purrr::keep(\(x) grepl("^#perm:", getElement(x, "@id"))) |>
    purrr::discard(\(x) getElement(x, "agent")[[1]] %in% non_admin_user_ids)
  crate <- admin_perm_ents |>
    purrr::reduce(rocrateR::remove_entity, .init = crate)

  # Safe Settings ----
  crate <- safe_setting(x, rocrate = crate)

  # Safe Outputs ----
  crate <- safe_people_tbl$name |>
    purrr::reduce(
      \(crate, u) {
        safe_output(
          crate,
          connection = x,
          path = path,
          user = u,
          logs_to = logs_to,
          logs_from = logs_from
        )
      },
      .init = crate
    )

  # attach input args as attributes to the RO-Crate
  attr(crate, "audit_type") <- "Safe Project"
  attr(crate, "path") <- path
  attr(crate, "project") <- project

  # return new RO-Crate
  return(crate)
}
