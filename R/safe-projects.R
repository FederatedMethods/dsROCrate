#' Safe projects details
#'
#' Safe projects details for the RO-Crate.
#'
#' Data must be used ethically, for research that delivers clear public benefit.
#'
#' As part of their application, researchers are asked to provide an overview
#' of their project, including how the data will be used and what outputs will
#' be achieved. This allows data providers to make an informed decision about
#' whether they are comfortable preparing data for the researcher to use for
#' ethical purposes serving a public good.
#'
#' @inheritParams safe_data
#' @param ... Other optional arguments. See the full documentation,
#'     [`?dsROCrate::safe_project`][safe_project()].
#' @param project_id_suffix String with ID suffix for the project entities
#'     in the RO-Crate (default: `"#project:"`).
#'
#' @returns Updated RO-Crate object with Safe Projects information.
#' @export
#'
#' @source
#' \itemize{
#'  \item Research Data Scotland, 2025. "What is the Five Safes framework?".
#'  <https://www.researchdata.scot/engage-and-learn/data-explainers/what-is-the-five-safes-framework/>
#' }
safe_project <- function(x, ...) {
  UseMethod("safe_project", x)
}

#' @export
safe_project.default <- function(x, ...) {
  stop(
    "Unknown class, please try either a file path or",
    " an object with `rocrate` class!"
  )
}

#' @export
safe_project.character <- function(x, ...) {}

#' @rdname safe_project
#' @export
safe_project.ArmadilloCredentials <- function(
  x,
  ...,
  rocrate = NULL,
  project = NULL,
  dataset_id_suffix = "#dataset:",
  project_id_suffix = "#project:"
) {
  # check if the given `project` exists
  project_exists(x, project)

  # retrieve details associated to `project`
  project_details_tbl <- MolgenisArmadillo::armadillo.get_projects_info(x)
}

#' @rdname safe_project
#' @export
safe_project.opal <- function(
  x,
  ...,
  rocrate = NULL,
  project = NULL,
  dataset_id_suffix = "#dataset:",
  project_id_suffix = "#project:"
) {
  # declare local bindings
  created <- lastUpdate <- NULL

  # x is a valid opal connection object
  validate_opal_con(x)

  # validate that connection user has administrative rights
  is_opal_admin_con(x)

  # check if the given `project` exists
  project_exists(x, project)

  # retrieve details associated to `project`
  project_details_tbl <- opalr::opal.project(x, project)

  # attempt to retrieve the dataset entities to link up the IDs to the project
  project_dataset_entities <- rocrate |>
    rocrateR::get_entity(type = "Dataset")

  # if any entity was found, then filter to keep those for which their @id
  # starts with `dataset_id_suffix` as set by `safe_data()` and that are
  # associated to the current project:
  if (length(project_dataset_entities) > 0) {
    # filter by @id suffix
    idx_id <- project_dataset_entities |>
      sapply("[[", "@id") |>
      sapply(grepl, pattern = paste0("^", dataset_id_suffix))
    # filter by name (if any are found)
    ## pull table names for the current project
    project_tables <- get_project_tables(x, project)
    idx_name <- FALSE
    if (length(project_tables) > 0) {
      idx_name <- project_dataset_entities |>
        sapply("[[", "name") |>
        sapply(\(x) x[[1]] %in% project_tables)
    }
    # drop out entries with @id not starting with `dataset_id_suffix`
    project_dataset_entities[!(idx_id & idx_name)] <- NULL
  }

  # create project entity
  timestamps <- getElement(project_details_tbl, "timestamps")
  project_entity <- rocrateR::entity(
    x = paste0(project_id_suffix, digest::digest(project)),
    type = "Project",
    name = getElement(project_details_tbl, "name"),
    dateCreated = getElement(timestamps, "created"),
    dateModified = getElement(timestamps, "lastUpdate"),
    hasPart = project_dataset_entities |>
      sapply("[[", "@id") |>
      lapply(function(id) {
        list(`@id` = id)
      })
  )

  # if no tables are associated to this project, then drop `hasPart`
  if (length(project_dataset_entities) == 0) {
    project_entity$hasPart <- NULL
  }

  # add new project entity to the RO-Crate
  rocrate <- rocrate |>
    rocrateR::add_entity(project_entity, overwrite = TRUE)

  # return RO-Crate with the new entity
  return(rocrate)
}

#' @rdname safe_project
#' @export
safe_project.rocrate <- function(
  x,
  ...,
  project = NULL,
  dataset_id_suffix = "#dataset:",
  project_id_suffix = "#project:",
  connection = NULL
) {
  # check if the connection was given
  if (is.null(connection)) {
    stop("A `connection` object is required!", call. = FALSE)
  }

  # call method with given `connection` object:
  safe_project(
    connection,
    rocrate = x,
    project = project,
    dataset_id_suffix = dataset_id_suffix,
    project_id_suffix = project_id_suffix
  )
}
