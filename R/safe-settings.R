#' Safe settings details
#'
#' Safe settings details for the RO-Crate.
#'
#' @param x PENDING
#' @param ... Other optional arguments.
#' @param rocrate RO-Crate object (see \link[rocrateR]{rocrate}).
#' @param connection Connection object for the DataSHIELD server where the
#'     values will be extracted from (e.g., OBiBa's Opal).
#'
#' @returns Updated RO-Crate object with Safe Settings information.
#' @export
#'
# @examples
safe_setting <- function(x, ...) {
  UseMethod("safe_setting", x)
}

#' @export
safe_setting.default <- function(x, ...) {
  stop("Unknown class, please try either a file path or",
       " an object with `rocrate` class!")
}

#' @export
safe_setting.character <- function(x, ..., rocrate = NULL) {

}

#' @rdname safe_setting
#' @export
safe_setting.opal <- function(x, ..., rocrate = NULL) {
  # x is a valid opal connection object
  # TODO validate connection

  # TODO: validate that connection user has administrative rights

  # extract disclosure settings and create `PropertyValue` entities
  disc_setting_entities <- opalr::dsadmin.get_options(x) |>
    tibble::as_tibble() |>
    purrr::pmap(function(name, value, ...) {
      rocrateR::entity(
        x = paste0("_:localid:", name, ":", value),
        type = "PropertyValue",
        name = name,
        value = value
      )
    })

  # add disclosure settings' entities to the `rocrate` object
  for (i in seq_along(disc_setting_entities)) {
    rocrate <- rocrate |>
      rocrateR::add_entity(disc_setting_entities[[i]], overwrite = TRUE)
  }

  # update the hasPart section of the "safe project" to link these entities
  # TODO: explore whether this is needed

  # extract information about R packages installed in the environment
  inst_packages_entities <- opalr::dsadmin.package_descriptions(x) |>
    tibble::as_tibble() |>
    purrr::pmap(function(Package, Version, Description, Author, ...) {
      # create new entity
      rocrateR::entity(
        x = digest::digest(paste0(Package, "_", Version)),
        type = "SoftwareApplication",
        name = Package,
        version = Version,
        description = Description
      )
    })

  # add installed packages' entities to the `rocrate` object
  for (i in seq_along(inst_packages_entities)) {
    rocrate <- rocrate |>
      rocrateR::add_entity(inst_packages_entities[[i]], overwrite = TRUE)
  }

  # return RO-Crate with the new entity
  return(rocrate)
}

#' @rdname safe_setting
#' @export
safe_setting.rocrate <- function(x, ..., connection = NULL) {
  # check if the connection was given
  if (is.null(connection)) {
    stop("A `connection` object is required!", call. = FALSE)
  }

  # TODO: Validate `connection` object

  # call method with given `connection` object:
  safe_setting(connection, rocrate = x)
}
