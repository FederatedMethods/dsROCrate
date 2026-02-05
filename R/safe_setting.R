#' Safe settings details
#'
#' Safe settings details for the RO-Crate.
#'
#' The organisational and technical settings used to access data are designed
#' to minimise the risk of accidental disclosure of data.
#'
#' These settings also prevent the deliberate disclosure of data to others.
#'
#' Physical settings for data access can include locations like
#' [SafePods](https://safepodnetwork.ac.uk/) – secured rooms that use controlled
#' door access, CCTV and secure technology to ensure that sensitive data cannot
#' be mishandled or removed from the Safe Setting. Researchers can analyse the
#' data in these secure rooms, but do not have access to the internet, external
#' devices (such as printers), or any other way of removing protected data from
#' the space.
#'
#' Digital Safe Settings provide secure access to data from a remote location.
#' To be approved for remote data access, researchers will need to prove that
#' their organisation meets physical and IT security standards.
#'
#'@inheritParams safe_data
#' @param ... Other optional arguments. See the full documentation,
#'     [`?dsROCrate::safe_setting`][safe_setting()].
#'
#' @returns Updated RO-Crate object with Safe Settings information.
#' @export
#'
#' @source
#' \itemize{
#'  \item Research Data Scotland, 2025. "What is the Five Safes framework?".
#'  <https://www.researchdata.scot/engage-and-learn/data-explainers/what-is-the-five-safes-framework/>
#' }
safe_setting <- function(x, ...) {
  UseMethod("safe_setting", x)
}

#' @export
safe_setting.default <- function(x, ...) {
  stop(
    "Unknown class, please try either a file path or",
    " an object with `rocrate` class!"
  )
}

#' @export
safe_setting.character <- function(x, ..., rocrate = rocrateR::rocrate_5s()) {}

#' @rdname safe_setting
#' @export
safe_setting.opal <- function(
  x,
  ...,
  rocrate = rocrateR::rocrate_5s(),
  path = NULL,
  project = NULL,
  tables = NULL,
  user = NULL
) {
  # x is a valid opal connection object
  validate_opal_con(x)

  # validate that connection user has administrative rights
  is_opal_admin_con(x)

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

  # update the hasPart section of the "Safe Project" to link these entities
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

  # attach input arguments as attributes
  attr(rocrate, "connection") <- x
  attr(rocrate, "path") <- path
  attr(rocrate, "project") <- project
  attr(rocrate, "tables") <- tables
  attr(rocrate, "user") <- user

  # return RO-Crate with the new entity
  return(rocrate)
}

#' @rdname safe_setting
#' @export
safe_setting.rocrate <- function(
  x,
  ...,
  connection = attr(x, "connection"),
  path = attr(x, "path"),
  project = attr(x, "project"),
  tables = attr(x, "tables"),
  user = attr(x, "user")
) {
  # check if the connection was given
  if (is.null(connection)) {
    stop("A `connection` object is required!", call. = FALSE)
  }

  # call method with given `connection` object:
  safe_setting(
    connection,
    rocrate = x,
    path = path,
    project = project,
    tables = tables,
    user = user
  )
}
