#' Safe outputs details
#'
#' Safe outputs details for the RO-Crate.
#'
#' All research outputs are checked to ensure individuals cannot be identified
#' even in the public domain.
#'
#' This means the other four Safes no longer apply.
#'
#' Before outputs are released from the TRE, they are checked to make sure it
#' is reasonably unlikely that any individuals can be identified on publication.
#' Compliance with the Digital Economy Act also requires that the TRE applies
#' methods and standards for output checking that are accredited by the UK
#' Statistics Authority.
#'
#' @inheritParams safe_data
#' @param ... Other optional arguments. See the full documentation,
#'     [`?dsROCrate::safe_output`][safe_output()].
#' @param path String to path pointing to the root of the RO-Crate. This will
#'     be used to store log files. If not provided, logs will be stored within
#'     the updated RO-Crate returned by this function.
#' @param user String with the name of the user for which outputs will be
#'     extracted. Optional, if no user is provided, then this will be extracted
#'     from the `author` in the root (`./`) entity of the RO-Crate.
#' @param logs_to Upper limit timestamp to filter outputs to be extracted
#'     (default: `Sys.time()`, current system time).
#' @param logs_from Lower limit timestamp to filter outputs to be extracted
#'     (default: `Sys.time() - 24 * 60 ^ 2`, last 24 hours)
#'
#' @returns Updated RO-Crate object with Safe Outputs information.
#' @export
#'
#' @source
#' \itemize{
#'  \item Research Data Scotland, 2025. "What is the Five Safes framework?".
#'  <https://www.researchdata.scot/engage-and-learn/data-explainers/what-is-the-five-safes-framework/>
#' }
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
  `@timestamp` <- logger_name <- safe_people_id <- NULL

  # x is a valid opal connection object
  # TODO validate connection

  # TODO: validate that connection user has administrative rights

  # TODO: validate that `logs_to` and `logs_from` have the class 'POSIXct'

  # verify if `user` is NULL, if so, retrieve information from the RO-crate
  if (is.null(user)) {
    # get `author` section from the root (./) entity
    rocrate_author <- rocrate |>
      rocrateR::get_entity(id = "./") |>
      lapply(getElement, name = "author") |>
      sapply(\(x) x)

    # extract @id attribute(s)
    if (length(rocrate_author) > 1) {
      safe_people_id <- rocrate_author |>
        sapply(getElement, name = "@id") |>
        sapply(unlist)
    } else {
      safe_people_id <- rocrate_author["@id"][[1]]
    }

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
       writeLines(userlogs, file.path(path, log_filename))
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
