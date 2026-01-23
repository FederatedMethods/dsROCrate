#' Audit Study details
#'
#' Audit Study details from a 'DataSHIELD' server, an RO-Crate object or
#' a file path pointing to an RO-Crate.
#'
#' @inheritParams safe_people
#' @param ... Other optional arguments, see full documentation for details.
#' @param project String with project name from which to extra Study
#'     details.
#' @param logs_from Lower limit timestamp to filter out the outputs generated
#'     (default: `-Inf`, everything up to `logs_to`)
#' @param logs_to Upper limit timestamp to filter out the outputs generated
#'     (default: `Inf`, everything from `logs_from` onwards).
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
    "Unknown class, please try either a file path or",
    " an object with `rocrate` class!"
  )
}

#' @rdname audit_study
#' @export
audit_study.list <- function(
  x,
  ...,
  project = NULL,
  logs_from = -Inf,
  logs_to = Inf
) {
  # local bindings
  name <- principal <- project_tables_all <- subject <- table <- type <- NULL

  capture.output(
    suppressMessages(suppressWarnings({
      safe_project_reports <- x |>
        purrr::map(function(conn) {
          audit_safe_project(
            conn,
            project = project,
            logs_from = logs_from,
            logs_to = logs_to
          ) #|>
          # rocrate_report(render = FALSE)
        })
    })),
    file = nullfile()
  )

  # return list with new RO-Crates (one per connection given)
  return(safe_project_reports)
}
