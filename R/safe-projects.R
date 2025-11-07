#' Safe projects details
#'
#' Safe projects details for the RO-Crate.
#'
#' @param x PENDING
#' @param ... Other optional arguments.
#' @param rocrate RO-Crate object (see \link[rocrateR]{rocrate}).
#' @param project description
#' @param dataset_id_suffix description
#' @param project_id_suffix description
#' @param connection Connection object for the DataSHIELD server where the
#'     values will be extracted from (e.g., OBiBa's Opal).
#'
#' @returns Updated RO-Crate object with Safe Projects information.
#' @export
#'
# @examples
safe_project <- function(x, ...) {
  UseMethod("safe_project", x)
}

#' @export
safe_project.default <- function(x, ...) {
  stop("Unknown class, please try either a file path or",
       " an object with `rocrate` class!")
}

#' @export
safe_project.character <- function(x, ...) {

}

#' @rdname safe_project
#' @export
safe_project.opal <- function(x, ..., rocrate = NULL, project = NULL, dataset_id_suffix = "#dataset:", project_id_suffix = "#project:") {
  # declare local bindings
  created <- lastUpdate <- name <- new_dataset_entity <- NULL

  # x is a valid opal connection object
  # TODO validate connection

  # check if the given `project` exists
  project_exists <- opalr::opal.project_exists(x, project)
  if (!project_exists) {
    stop("The given `project` was not found in the given Opal connection!",
         call. = FALSE)
  }

  # retrieve details associated to `project`
  project_details_tbl <- opalr::opal.project(x, project)

  # attempt to retrieve the dataset entities to link up the IDs to the project
  project_dataset_entities <- rocrate |>
    rocrateR::get_entity(type = "Dataset")
  # if any entity was found, then filter to keep those for which their @id
  # starts with `dataset_id_suffix` as set by `safe_data()`
  if (length(project_dataset_entities) > 0) {
    idx <- project_dataset_entities |>
      sapply("[[", "@id") |>
      sapply(grepl, pattern = paste0("^", dataset_id_suffix))
    # drop out entries with @id not starting with `dataset_id_suffix`
    project_dataset_entities[!idx] <- NULL
  }

  # create project entity
  timestamps <- getElement(project_details_tbl, "timestamps")
  project_entity <- rocrateR::entity(
    x = paste0(project_id_suffix, digest::digest(name)),
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
safe_project.rocrate <- function(x, ..., project = NULL, dataset_id_suffix = "#dataset:", project_id_suffix = "#project:", connection = NULL) {
  # check if the connection was given
  if (is.null(connection)) {
    stop("A `connection` object is required!", call. = FALSE)
  }

  # TODO: Validate `connection` object

  # call method with given `connection` object:
  safe_project(connection, rocrate = x, project = project, dataset_id_suffix = dataset_id_suffix, project_id_suffix = project_id_suffix)
}
