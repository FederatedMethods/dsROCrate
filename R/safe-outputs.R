#' Safe outputs details
#'
#' Safe outputs details for the RO-Crate.
#'
#' @param x PENDING
#' @param ... Other optional arguments.
#' @param rocrate RO-Crate object (see \link[rocrateR]{rocrate}).
#' @param path description
#' @param user description
#' @param logs_to description
#' @param logs_from description
#' @param connection Connection object for the DataSHIELD server where the
#'     values will be extracted from (e.g., OBiBa's Opal).
#'
#' @returns Updated RO-Crate object with Safe Outputs information.
#' @export
#'
# @examples
safe_output <- function(x, ...) {
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

#' @rdname safe_output
#' @export
safe_output.opal <- function(x, ..., rocrate = NULL, path = NULL, user = NULL, logs_to = Sys.time(), logs_from = logs_to - 24 * 60 ^ 2) {
  # local bindings
  `@timestamp` <- logger_name <- NULL

  # x is a valid opal connection object
  # TODO validate connection

  # TODO: validate that connection user has administrative rights

  # TODO: validate that `logs_to` and `logs_from` have the class 'POSIXct'

  # verify if `user` is NULL, if so, retrieve information from the RO-crate
  if (is.null(user)) {
    safe_people_id <- rocrate |>
      rocrateR::get_entity(id = "./") |>
      sapply(getElement, name = "author") |>
      sapply(getElement, name = "@id") |>
      sapply(unlist)

    # check if safe people section wasn't found
    if (is.null(safe_people_id)) {
      warning("Safe people section not found (i.e., no author for root entity) ",
              "in the given RO-Crate. \nEither run `dsROCrate::safe_people()` ",
              "or set `user` when calling `dsROCrate::safe_output()`!",
              call. = FALSE)

      # return the input RO-Crate
      return(rocrate)
    }

    # retrieve safe people entity for the current user
    safe_people_information <- safe_people_id |>
      sapply(\(x) rocrateR::get_entity(rocrate, id = x))

    # update user
    user <- safe_people_information |>
      sapply(getElement, name = "name") |>
      unique()

    # check if for any reason multiple users were found
    if (length(user) != 1) {
      warning("Error when retrieving the safe people section in the given ",
              "RO-Crate. ", length(user), " entries in the 'author' ",
              "section of root (./) entity were found!",
              call. = FALSE)

      # return the input RO-Crate
      return(rocrate)
    }
  }

  # parse logs
  userlogs <- opalr::dsadmin.log(x) |>
    tibble::as_tibble() |>
    dplyr::mutate(`@timestamp` = as.POSIXct(`@timestamp`,
                                            format = "%Y-%m-%dT%H:%M:%S")) |>
    # filter logs
    dplyr::filter(dplyr::between(`@timestamp`, logs_from, logs_to)) |>
    dplyr::filter(logger_name == "datashield.user") |>
    dplyr::filter(user == !!user) |>
    glue::glue_data(
      "[{level}][{format(`@timestamp`, '%Y-%m-%dT%H:%M:%S')}]{stringr::str_pad(paste0('[', ds_action, ']'), 12, 'right', ' ')}{message}"
    )

  # check if any logs were found in the given time frame
  if (length(userlogs) == 0) {
    warning("No logs were found for the following configuration:",
            "\n User: ", user,
            "\n Period: ", logs_from, " -- ", logs_to,
            call. = FALSE)

    # return the input RO-Crate
    return(rocrate)
  }

  log_filename <- paste0(Sys.Date(), "-dslogs-", user, ".log")

  # create new data entity for log file
  log_entity <- rocrateR::entity(
    x = basename(log_filename),
    type = "File",
    dateModified = Sys.time(),
    name = basename(log_filename),
    encodingFormat = "text/plain"
  )

  # check if a `path` was not provided, then display warning and store contents
  # inside the RO-Crate entity
  if (is.null(path)) {
    warning("A `path` wasn't provided! The logs will be included in the ",
            "RO-Crate object, under the `content` tag!",
            call. = FALSE)
    log_entity$content <- list(userlogs)
  } else {
    # validate if the given path is valid
    if (!dir.exists(path)) {
      warning("The given `path` is not valid! The logs will be included in the ",
              "RO-Crate object, under the `content` tag!",
              call. = FALSE)
      log_entity$content <- list(userlogs)
    } else {
       writeLines(userlogs, log_filename)
    }
  }

  # add entity to the RO-Crate
  rocrate <- rocrate |>
    rocrateR::add_entity(log_entity) |>
    rocrateR::add_entity_value(id = "./",
                               key = "hasPart",
                               value = list(`@id` = log_entity$`@id`))

  # return RO-Crate with the new entity
  return(rocrate)
}

#' @rdname safe_output
#' @export
safe_output.rocrate <- function(x, ..., path = NULL, user = NULL, logs_to = Sys.time(), logs_from = logs_to - 24 * 60 ^ 2, connection = NULL) {
  # check if the connection was given
  if (is.null(connection)) {
    stop("A `connection` object is required!", call. = FALSE)
  }

  # TODO: Validate `connection` object

  # call method with given `connection` object:
  safe_output(connection, rocrate = x, path = path, user = user, logs_to = logs_to, logs_from = logs_from)
}
