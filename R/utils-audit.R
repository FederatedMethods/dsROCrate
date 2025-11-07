#' Safe people details
#'
#' Safe people details for the RO-Crate.
#'
#' @param x PENDING
#' @param ... Other optional arguments.
# @param rocrate RO-Crate object (see \link[rocrateR]{rocrate}).
#'
#' @returns Updated RO-Crate object with Safe People information.
#' @export
#'
# @examples
audit_safe_people <- function(x, ...) {
  UseMethod("audit_safe_people", x)
}

#' @export
audit_safe_people.default <- function(x, ...) {
  stop("Unknown class, please try either a file path or",
       " an object with `rocrate` class!")
}

#' @export
audit_safe_people.rocrate <- function(x, ...) {
  stop("Unknown class, please try either a file path or",
       " an object with `rocrate` class!")
}
