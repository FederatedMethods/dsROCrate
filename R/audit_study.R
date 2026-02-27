#' Audit Study details
#'
#' Audit Study details from a 'DataSHIELD' server, an RO-Crate object or
#' a file path pointing to an RO-Crate.
#'
#' @inheritParams audit_safe_people
#' @param ... Other optional arguments, see full documentation for details.
#'
#' @returns Updated RO-Crate object with Study information.
#' @export
audit_study <- function(x, ...) {
  UseMethod("audit_study", x)
}

#' @rdname audit_study
#' @export
audit_study.default <- function(x, ...) {
  stop(
    "Unknown class, please try a named list of connections (e.g., OBiBa's Opal)",
    " or a single connection object!"
  )
}

#' @rdname audit_study
#' @export
audit_study.list <- function(
  x,
  ...,
  project = NULL,
  logs_from = -Inf,
  logs_to = Inf,
  path = NULL
) {
  # local bindings
  name <- principal <- project_tables_all <- subject <- table <- type <- NULL

  utils::capture.output(
    suppressMessages(suppressWarnings({
      safe_project_reports <- x |>
        purrr::map(function(conn) {
          audit_study(
            conn,
            project = project,
            logs_from = logs_from,
            logs_to = logs_to,
            path = path
          )
        })
    })),
    file = nullfile()
  )

  # attach input args as attributes to the RO-Crate
  attr(safe_project_reports, "audit_type") <- "Study"
  attr(safe_project_reports, "path") <- path
  attr(safe_project_reports, "project") <- project

  # return list with new RO-Crates (one per connection given)
  return(safe_project_reports)
}

#' @rdname audit_study
#' @export
audit_study.opal <- function(
  x,
  ...,
  project = NULL,
  logs_from = -Inf,
  logs_to = Inf,
  path = NULL
) {
  # local bindings
  name <- principal <- project_tables_all <- subject <- table <- type <- NULL

  utils::capture.output(
    suppressMessages(suppressWarnings({
      safe_project_reports <- x |>
        audit_safe_project(
          project = project,
          logs_from = logs_from,
          logs_to = logs_to,
          path = path
        )
    })),
    file = nullfile()
  )

  # attach input args as attributes to the RO-Crate
  attr(safe_project_reports, "audit_type") <- "Study"
  attr(safe_project_reports, "path") <- path
  attr(safe_project_reports, "project") <- project

  # return list with new RO-Crates (one per connection given)
  return(safe_project_reports)
}
