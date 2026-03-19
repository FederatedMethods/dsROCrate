#' Audit Safe Project details
#'
#' Audit Safe Project details from a 'DataSHIELD' server, an RO-Crate object or
#' a file path pointing to an RO-Crate.
#'
#' @inheritParams audit_safe_people
#' @param ... Other optional arguments, see full documentation for details.
#'
#' @returns Audit RO-Crate with 5 Safes Components.
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
  project,
  user = NULL,
  logs_from = -Inf,
  logs_to = Inf,
  path = NULL
) {
  # generate audit crate
  crate <- audit_engine(
    x,
    project = project,
    user = user,
    logs_from = logs_from,
    logs_to = logs_to,
    path = path
  )

  # attach input args as attributes to the RO-Crate
  attr(crate, "audit_type") <- "Safe Project"
  attr(crate, "path") <- path
  attr(crate, "project") <- project

  # return new RO-Crate
  return(crate)
}
