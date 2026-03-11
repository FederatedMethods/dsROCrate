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
#' @param ... Other optional arguments. See the full documentation,
#'     [`?dsROCrate::safe_setting`][safe_setting()].
#' @inheritParams init
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

#' @rdname safe_setting
#' @export
safe_setting.character <- function(
  x,
  ...,
  connection = attr(x, "connection"),
  path = attr(x, "path"),
  project = attr(x, "project"),
  tables = attr(x, "tables"),
  user = attr(x, "user")
) {
  # attempt loading the RO-Crate
  rocrate <- rocrateR::load_rocrate(x)

  # call method with given `rocrate` object:
  safe_setting(
    rocrate,
    connection = connection,
    path = path,
    project = project,
    tables = tables,
    user = user
  )
}

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
  # validate connection ----
  # x is a valid opal connection object
  validate_opal_con(x)
  # validate that connection user has administrative rights
  is_opal_admin_con(x)

  # statistical disclosure controls ----
  # extract disclosure settings and create `PropertyValue` entities
  disc_setting_entities <- opalr::dsadmin.get_options(x) |>
    tibble::as_tibble() |>
    purrr::pmap(function(name, value, ...) {
      rocrateR::entity(
        id = id_hash("#disc:", paste0(name, value)),
        type = "PropertyValue",
        name = name,
        value = value
      )
    })

  # computational environment ----
  # extract information about R packages installed in the environment
  pkg_entities <- opalr::dsadmin.package_descriptions(x) |>
    tibble::as_tibble() |>
    purrr::pmap(function(Package, Version, Description, Author, ...) {
      # create new entity
      rocrateR::entity(
        id = id_hash("#software:", paste0(Package, Version)),
        type = "SoftwareApplication",
        name = Package,
        version = Version,
        description = Description |> trimws()
      )
    })

  software_env <- rocrateR::entity(
    id = "#env:software", # id_hash("#env:", "software")
    type = "CreativeWork",
    name = "Approved Analytical Software Environment",
    description = paste(
      "Software packages installed in the controlled Opal/DataSHIELD",
      "environment used for federated analysis."
    ),
    hasPart = purrr::map(pkg_entities, ~ list("@id" = .x$`@id`))
  )

  # technical controls ----
  tech_controls <- list(
    rocrateR::entity(
      id = "#control:output-checking",
      type = "CreativeWork",
      name = "Statistical Disclosure Output Checking",
      description = paste(
        "Automated disclosure control prevents release of",
        "small-cell counts and disclosive statistics."
      )
    ),
    rocrateR::entity(
      id = "#control:server-side-analysis",
      type = "CreativeWork",
      name = "Server-Side Analysis Enforcement",
      description = paste(
        "Raw data never leaves the secure server;",
        "analysis occurs via vetted aggregate functions."
      )
    ),
    rocrateR::entity(
      id = "#control:session-logging",
      type = "CreativeWork",
      name = "Comprehensive Session Logging",
      description = "All analytical actions are logged and auditable."
    )
  )

  # physical controls ----
  physical_controls <- list(
    rocrateR::entity(
      id = "#control:secure-facility",
      type = "CreativeWork",
      name = "Secure Data Facility",
      description = "Access restricted to approved secure premises."
    )
  )

  # organisational controls ----
  org_controls <- list(
    rocrateR::entity(
      id = "#control:access-governance",
      type = "CreativeWork",
      name = "Access Governance Process",
      description = "Data access committee review and approval required."
    )
  )

  # root safe setting entity ----
  safe_setting_root <- rocrateR::entity(
    id = "#safesetting:technical",
    type = "CreativeWork",
    name = "Safe Setting Controls",
    description = paste(
      "Technical, physical and organisational safeguards applied to minimise",
      "disclosure risk."
    ),
    additionalProperty = disc_setting_entities,
    hasPart = c(
      list(list("@id" = "#env:software")),
      purrr::map(
        c(tech_controls, physical_controls, org_controls),
        \(x) list("@id" = x$`@id`)
      )
    )
  )

  # add entities to RO-Crate
  all_entities <- c(
    disc_setting_entities,
    pkg_entities,
    tech_controls,
    physical_controls,
    org_controls,
    list(software_env, safe_setting_root)
  )

  rocrate <- purrr::reduce(
    all_entities,
    rocrateR::add_entity,
    .init = rocrate
  )

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
