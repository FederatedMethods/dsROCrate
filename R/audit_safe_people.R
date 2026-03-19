#' Audit Safe People details
#'
#' Audit Safe People details from a 'DataSHIELD' server, an RO-Crate object or
#' a file path pointing to an RO-Crate.
#'
#' @inheritParams audit_engine
#' @param ... Other optional arguments, see full documentation for details.
#'
#' @returns Audit RO-Crate with 5 Safes Components.
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
  attr(crate, "audit_type") <- "Safe People"
  attr(crate, "path") <- path
  attr(crate, "project") <- project
  attr(crate, "user") <- user

  # return new RO-Crate
  return(crate)
}
