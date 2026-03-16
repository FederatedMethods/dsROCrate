#' Safe Project details
#'
#' Safe Project details for the RO-Crate.
#'
#' Data must be used ethically, for research that delivers clear public benefit.
#'
#' As part of their application, researchers are asked to provide an overview
#' of their project, including how the data will be used and what outputs will
#' be achieved. This allows data providers to make an informed decision about
#' whether they are comfortable preparing data for the researcher to use for
#' ethical purposes serving a public good.
#'
#' @param ... Other optional arguments. See the full documentation,
#'     [`?dsROCrate::safe_project`][safe_project()].
#' @inheritParams safe_data
#'
#' @returns Updated RO-Crate object with Safe Project information.
#' @export
#'
#' @source
#' \itemize{
#'  \item Research Data Scotland, 2025. "What is the Five Safes framework?".
#'  <https://www.researchdata.scot/engage-and-learn/data-explainers/what-is-the-five-safes-framework/>
#' }
#'
#' @aliases safe_project,armadillo-method
#' @usage
#' \S4method{safe_project}{armadillo}(
#'   x,
#'   ...,
#'   profile = "default",
#'   project = NULL,
#'   rocrate = rocrateR::rocrate_5s(),
#'   asset_id_suffix = "#asset:",
#'   project_id_suffix = "#project:",
#'   path = NULL,
#'   resources = NULL,
#'   tables = NULL,
#'   user = NULL
#' )
safe_project <- function(x, ...) {
  UseMethod("safe_project")
}

# S3 methods ----
#' @method safe_project default
#' @export
safe_project.default <- function(x, ...) {
  stop(
    "Unknown class, please try either a file path or",
    " an object with `rocrate` class!"
  )
}

#' @method safe_project character
#' @rdname safe_project
#' @export
safe_project.character <- function(
  x,
  ...,
  profile = attr(x, "profile"),
  project = attr(x, "project"),
  asset_id_suffix = "#asset:",
  project_id_suffix = "#project:",
  connection = attr(x, "connection"),
  path = attr(x, "path"),
  resources = attr(x, "resources"),
  tables = attr(x, "tables"),
  user = attr(x, "user")
) {
  # attempt loading the RO-Crate
  rocrate <- rocrateR::load_rocrate(x)

  # call method with given `rocrate` object:
  safe_project(
    rocrate,
    connection = connection,
    profile = profile,
    project = project,
    asset_id_suffix = asset_id_suffix,
    project_id_suffix = project_id_suffix,
    path = path,
    resources = resources,
    tables = tables,
    user = user
  )
}

#' @method safe_project opal
#' @rdname safe_project
#' @export
safe_project.opal <- function(
  x,
  ...,
  profile = "default",
  project = NULL,
  rocrate = rocrateR::rocrate_5s(),
  asset_id_suffix = "#asset:",
  project_id_suffix = "#project:",
  path = NULL,
  resources = NULL,
  tables = NULL,
  user = NULL
) {
  # declare local bindings
  created <- lastUpdate <- NULL

  # x is a valid opal connection object
  validate_opal_con(x)

  # validate that connection user has administrative rights
  is_opal_admin_con(x)

  # enforce that `project` is a single value
  if (is.null(project)) {
    stop("A value for `project` is required!", call. = FALSE)
  } else if (length(project) != 1) {
    stop("`project` must be a single value!", call. = FALSE)
  }

  # check if the given `project` exists
  project_exists(x, project = project)

  # retrieve details associated to `project`
  project_details_tbl <- opalr::opal.project(x, project)

  # filter out asset entities associated with the project based on the
  # value for `asset_id_suffix`.
  project_asset_entities <- rocrate$`@graph` |>
    purrr::keep(\(x) grepl(paste0("^", asset_id_suffix), x$`@id`))

  # create project entity
  timestamps <- getElement(project_details_tbl, "timestamps")
  project_entity <- rocrateR::entity(
    id = id_hash(project_id_suffix, project),
    type = "Project",
    name = getElement(project_details_tbl, "name"),
    dateCreated = getElement(timestamps, "created"),
    dateModified = getElement(timestamps, "lastUpdate"),
    hasPart = purrr::map(project_asset_entities, ~ list("@id" = .x$`@id`))
  )

  # if no tables are associated to this project, then drop `hasPart`
  if (length(project_asset_entities) == 0) {
    project_entity$hasPart <- NULL
  }

  # add new project entity to the RO-Crate
  rocrate <- rocrate |>
    rocrateR::add_entity(project_entity, overwrite = TRUE)

  # attach input arguments as attributes
  attr(rocrate, "connection") <- x
  attr(rocrate, "path") <- path
  attr(rocrate, "profile") <- profile
  attr(rocrate, "project") <- project
  attr(rocrate, "resources") <- resources
  attr(rocrate, "tables") <- tables
  attr(rocrate, "user") <- user

  # return RO-Crate with the new entity
  return(rocrate)
}

#' @method safe_project rocrate
#' @rdname safe_project
#' @export
safe_project.rocrate <- function(
  x,
  ...,
  profile = attr(x, "profile"),
  project = attr(x, "project"),
  asset_id_suffix = "#asset:",
  project_id_suffix = "#project:",
  connection = attr(x, "connection"),
  path = attr(x, "path"),
  resources = attr(x, "resources"),
  tables = attr(x, "tables"),
  user = attr(x, "user")
) {
  # check if the connection was given
  if (is.null(connection)) {
    stop("A `connection` object is required!", call. = FALSE)
  }

  # call method with given `connection` object:
  safe_project(
    connection,
    rocrate = x,
    path = path,
    profile = profile,
    project = project,
    asset_id_suffix = asset_id_suffix,
    project_id_suffix = project_id_suffix,
    resources = resources,
    tables = tables,
    user = user
  )
}

# S4 methods ----
#' @aliases safe_project,armadillo-method
#' @export
setMethod(
  "safe_project",
  signature(x = "armadillo"),
  function(
    x,
    ...,
    profile = "default",
    project = NULL,
    rocrate = rocrateR::rocrate_5s(),
    asset_id_suffix = "#asset:",
    project_id_suffix = "#project:",
    path = NULL,
    resources = NULL,
    tables = NULL,
    user = NULL
  ) {
    # check if the given `project` exists
    project_exists(x, project = project)

    # retrieve details associated to `project`
    project_details_tbl <- MolgenisArmadillo::armadillo.get_projects_info() |>
      purrr::list_c() |>
      tibble::as_tibble()
  }
)
