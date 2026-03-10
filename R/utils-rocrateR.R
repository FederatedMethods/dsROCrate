#' Wrapper for [rocrateR::get_entity()]
#'
#' This wrapper is used to suppress warning messages like
#' 'No matching entities were found with ...'.
#'
#' @importFrom rocrateR get_entity
#'
#' @returns List with entity of objects
#' @noRd
.get_entity <- function(rocrate, id = NULL, type = NULL) {
  suppressWarnings(rocrateR::get_entity(rocrate, id = id, type = type))
}
