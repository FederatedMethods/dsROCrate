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
  UseMethod("audit_safe_people")
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
  name <- principal <- project_tables_all <- subject <- type <- NULL

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
    dplyr::filter(!(tolower(name) %in% c("admin", "administrator"))) |>
    dplyr::filter(tolower(name) == user)

  if (nrow(safe_people_tbl) == 0) {
    stop(
      sprintf(
        "No Safe People details were found for the user '%s'!",
        user
      ),
      call. = FALSE
    )
  }

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
  attr(crate, "audit_type") <- "Safe People"
  attr(crate, "path") <- path
  attr(crate, "project") <- project
  attr(crate, "user") <- user

  # return new RO-Crate
  return(crate)
}
