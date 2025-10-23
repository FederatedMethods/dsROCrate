#' Safe outputs details
#'
#' Safe outputs details for the RO-Crate.
#'
#' @param x PENDING
#' @param ... Other optional arguments.
#' @param rocrate RO-Crate object (see \link[rocrateR]{rocrate}).
#'
#' @returns Updated RO-Crate object with Safe Outputs information.
#' @export
#'
# @examples
safe_output <- function(x, ..., rocrate = NULL) {
  UseMethod("safe_output", x)
}

#' @export
safe_output.default <- function(x, ...) {
  stop("Unknown class, please try either a file path or",
       " an object with `rocrate` class!")
}

#' @export
safe_output.character <- function(x, ..., rocrate = NULL) {

}

#' @export
safe_output.opal <- function(x, ..., rocrate = NULL, username = NULL) {
  # x is a valid opal connection object
  # TODO validate connection

  # TODO: validate that connection user has administrative rights

  # verify if `username` is NULL, if so, retrieve information from the RO-crate
  if (is.null(username)) {
    safe_people_id <- rocrate |>
      rocrateR::get_entity(id = "./") |>
      sapply(getElement, name = "author") |>
      getElement("@id")
    # retrieve safe people entity for the current user
    safe_people_information <- rocrate |>
      rocrateR::get_entity(id = safe_people_id)
    # update username
    username <- getElement(safe_people_information, "name")
  }

  # parse timestamp
  parse_timestamp <- function(x, format = "%Y-%m-%dT%H:%M:%S") {
    x |>
      sub(pattern = "\\..*Z$", replacement = "") |>
      as.POSIXct(format = format, tz = "UTC") |>
      format(format)
  }

  # parse logs
  userlogs <- opalr::dsadmin.log(o) |>
    tibble::as_tibble() |>
    dplyr::filter(logger_name == "datashield.user") |>
    dplyr::filter(username == !!username) |>
    glue::glue_data(
      "[{level}][{parse_timestamp(`@timestamp`)}]{stringr::str_pad(paste0('[', ds_action, ']'), 12, 'right', ' ')}{message}"
    )

  log_filename <- paste0("./", Sys.Date(), "-dslogs-", username, ".log")
  # TODO: change location where the logs are stored
  # userlogs |>
  #   readr::write_lines(log_filename)

  # create new data entity for log file
  log_entity <- rocrateR::entity(
    x = basename(log_filename),
    type = "File",
    dateModified = Sys.time(),
    name = basename(log_filename)
  )

  # add entity to the RO-Crate
  dsROCrate <- dsROCrate |>
    rocrateR::add_entity(log_entity) |>
    rocrateR::add_entity_value(id = "./", key = "hasPart", value = list(`@id` = log_entity$`@id`))

  # return RO-Crate with the new entity
  return(rocrate)
}

#' @export
safe_output.rocrate <- function(x, ...) {

}
