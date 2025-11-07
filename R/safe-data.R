#' Safe data details
#'
#' Safe data details for the RO-Crate.
#'
#' @param x PENDING
#' @param ... Other optional arguments.
#' @param rocrate RO-Crate object (see \link[rocrateR]{rocrate}).
#' @param project PENDING
#' @param tables PENDING
#' @param dataset_id_suffix PENDING
#' @param connection Connection object for the DataSHIELD server where the
#'     values will be extracted from (e.g., OBiBa's Opal).
#'
#' @returns Updated RO-Crate object with Safe Data information.
#' @export
#'
# @examples
safe_data <- function(x, ...) {
  UseMethod("safe_data", x)
}

#' @export
safe_data.default <- function(x, ...) {
  stop("Unknown class, please try either a file path or",
       " an object with `rocrate` class!")
}

#' @export
safe_data.character <- function(x, ..., rocrate = NULL) {

}

#' @rdname safe_data
#' @export
safe_data.opal <- function(x, ..., rocrate = NULL, project = NULL, tables = NULL, dataset_id_suffix = "#dataset:") {
  # declare local bindings
  created <- lastUpdate <- name <- new_dataset_entity <- NULL

  # x is a valid opal connection object
  # TODO validate connection

  # check if the given `project` exists, every dataset should be associated
  # with a project.
  project_exists <- opalr::opal.project_exists(x, project)
  if (!project_exists) {
    stop("The given `project` was not found in the given Opal connection!",
         call. = FALSE)
  }

  # retrieve details associated to `project`
  project_details_tbl <- opalr::opal.project(x, project)

  # table names, update times etc.
  project_tables <- tryCatch({
    project_details_tbl |>
      purrr::pluck("datasource") |>
      purrr::pluck("table") |>
      purrr::list_c()
  }, error = function(e) {
    list()
  })

  # verify if `tables` is NULL, if so, then add all data tables associated
  # to the given `project`
  if (is.null(tables)) {
    tables <- unlist(project_tables)
  }

  # create entity objects for each dataset/table in the project
  project_dataset_entities <- tibble::tibble(
    datasource = project,
    table = project_tables
  ) |>
    dplyr::filter(table %in% tables) |> # filter specific tables, `tables`
    purrr::pmap(function(datasource, table) {
      table_details <- opalr::opal.table(x, datasource, table)
      timestamps <- getElement(table_details, "timestamps")
      # create entity object
      new_dataset_entity <- rocrateR::entity(
        x = paste0(dataset_id_suffix,
                   digest::digest(paste0(datasource, "_", table))),
        type = "Dataset",
        dateCreated = getElement(timestamps, "created"),
        dateModified = getElement(timestamps, "lastUpdate"),
        path = getElement(table_details, "link")
      )
      # return new entity object
      return(new_dataset_entity)
    })

  # add table entities to the `rocrate` object
  for (i in seq_along(project_dataset_entities)) {
    rocrate <- rocrate |>
      rocrateR::add_entity(project_dataset_entities[[i]], overwrite = TRUE)
  }

  # return RO-Crate with the new entity
  return(rocrate)
}

#' @rdname safe_data
#' @export
safe_data.rocrate <- function(x, ..., project = NULL, tables = NULL, dataset_id_suffix = "#dataset:", connection = NULL) {
  # check if the connection was given
  if (is.null(connection)) {
    stop("A `connection` object is required!", call. = FALSE)
  }

  # TODO: Validate `connection` object

  # call method with given `connection` object:
  safe_data(connection, rocrate = x, project = project, tables = tables, dataset_id_suffix = dataset_id_suffix)
}
