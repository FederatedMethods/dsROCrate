#' Safe projects details
#'
#' Safe projects details for the RO-Crate.
#'
#' @param x PENDING
#' @param ... Other optional arguments.
#' @param rocrate RO-Crate object (see \link[rocrateR]{rocrate}).
#'
#' @returns Updated RO-Crate object with Safe Projects information.
#' @export
#'
# @examples
safe_project <- function(x, ..., rocrate = NULL) {
  UseMethod("safe_project", x)
}

#' @export
safe_project.default <- function(x, ...) {
  stop("Unknown class, please try either a file path or",
       " an object with `rocrate` class!")
}

#' @export
safe_project.character <- function(x, ..., rocrate = NULL) {

}

#' @export
safe_project.opal <- function(x, ..., rocrate = NULL, project = NULL, tables = NULL) {
  # x is a valid opal connection object
  # TODO validate connection

  # check if the given `project` exists
  if (opalr::opal.project_exists(o, project)) {
    stop("The given `project` was not found in the given Opal connection!",
         call. = FALSE)
  }

  # retrieve details associated to `project`
  project_details_tbl <- opalr::opal.project(o, project)

  # table names, update times etc.
  project_tables <- tryCatch({
    project_details_tbl |>
      purrr::pluck("datasource") |>
      purrr::pluck("table") |>
      purrr::list_c()
  }, error = function(e) {
    list()
  })

  # create entity objects for each dataset/table in the project
  project_details_entities <- tibble::tibble(
    datasource = project,
    table = project_tables
  ) |>
    # TODO: include filter for some tables, similar to the following line
    # dplyr::filter(table %in% TABLES) |> # filter specific tables, set by TABLES
    purrr::pmap(function(datasource, table) {
      table_details <- opalr::opal.table(o, datasource, table)
      timestamps <- getElement(table_details, "timestamps")
      # create entity object
      new_dataset_entity <- rocrateR::entity(
        x = digest::digest(paste0(datasource, "_", table)),
        type = "Dataset",
        dateCreated = getElement(timestamps, "created"),
        dateModified = getElement(timestamps, "lastUpdate"),
        path = getElement(table_details, "link")
      )
      # return new entity object
      return(new_dataset_entity)
    })

  # add table entities to the `rocrate` object
  for (i in seq_along(project_details_entities)) {
    rocrate <- rocrate |>
      rocrateR::add_entity(new_dataset_entity[[i]], overwrite = TRUE)
  }

  # create project entity
  project_entity <- rocrateR::entity(
    x = digest::digest(name),
    type = "Project",
    name = name,
    dateCreated = created,
    dateModified = lastUpdate,
    hasPart = project_details_entities |>
      sapply("[[", "@id") |>
      lapply(function(id) {
        list(`@id` = id)
      })
  )

  # if no tables are associated to this project, then drop `hasPart`
  if (length(project_details_entities) == 0) {
    project_entity$hasPart <- NULL
  }

  # add new project entity to the RO-Crate
  rocrate <- rocrate |>
    rocrateR::add_entity(project_entity, overwrite = TRUE)

  # return RO-Crate with the new entity
  return(rocrate)
}


#' @export
safe_projects.rocrate <- function(x, ...) {

}
