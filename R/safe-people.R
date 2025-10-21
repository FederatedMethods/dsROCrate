#' Safe people details
#'
#' Safe people details for the RO-Crate.
#'
#' @param x PENDING
#' @param ... Other optional arguments.
#' @param rocrate RO-Crate object (see \link[rocrateR]{rocrate}).
#'
#' @returns Updated RO-Crate object with Safe People information.
#' @export
#'
# @examples
safe_people <- function(x, ..., rocrate = NULL) {
  UseMethod("safe_people", x)
}

#' @export
safe_people.default <- function(x, ...) {
  stop("Unknown class, please try either a file path or",
       " an object with `rocrate` class!")
}

#' @export
safe_people.character <- function(x, ..., rocrate = NULL) {

}

#' @export
safe_people.opal <- function(x, ..., rocrate = NULL) {
  # x is a valid opal connection object
  # TODO validate connection

  # extract user information
  ## currently only username
  ## create entity for user
  user_entity <- rocrateR::entity(
    x = digest::digest(x$username),
    type = "Person",
    name = x$username
  )

  # add user to the RO-Crate
  rocrate <- rocrate |>
    rocrateR::add_entity(rocrate, overwrite = TRUE) |>
    # link new user entity @id to the root (./) author property
    rocrateR::add_entity_value("./", "author", getElement(rocrate, "@id"))

  # return RO-Crate with the new entity
  return(rocrate)
}

#' @export
safe_people.rocrate <- function(x, ...) {

}
