#' Safe data details
#'
#' Safe data details for the RO-Crate.
#'
#' Researchers only use de-identified data that is relevant to their study.
#'
#' In compliance with the Digital Economy Act, data is effectively anonymised
#' within TREs (Trusted Research Environments).
#'
#' This means any sensitive information that might lead to an individual being
#' identified, such as names and addresses, is either removed or replaced with
#' a random code. Researchers are not processing personal data when using data
#' prepared in this way and when the other Safes are in place. Find out more
#' about de-identification:
#' <https://www.researchdata.scot/engage-and-learn/data-explainers/what-is-data-de-identification/>
#'
#' @param x This can be a connection to a 'DataSHIELD' server (e.g., object with
#'     the `opal` class, see [opalr::opal.login()]), an RO-Crate
#'     ([rocrate][rocrateR::rocrate()] class) or a string with the path to an
#'     RO-Crate.
#' @param ... Other optional arguments. See the full documentation,
#'     [`?dsROCrate::safe_data`][safe_data()].
#' @param rocrate RO-Crate object. Optional, if `x` is either an RO-Crate
#'     object or a path to a valid RO-Crate. If so, then `connection` is
#'     required.
#' @param project String with the name of the [Safe Project][safe_project()].
#' @param tables Vector of strings with the names of the tables/datasets, part
#'     of `project`. Optional, if not provided, all the tables/datasets
#'     associated to `project` will be included in the RO-Crate.
#' @param dataset_id_suffix String with ID suffix for the tables/datasets
#'     entities in the RO-Crate (default: `"#dataset:"`).
#' @param connection Connection object for the 'DataSHIELD' server where the
#'     values will be extracted from (e.g., OBiBa's Opal). Optional, if `x` is
#'     set to a connection object. If so, then `rocrate` is required.
#'
#' @returns Updated RO-Crate object with Safe Data information.
#' @export
#'
#' @source
#' \itemize{
#'  \item Research Data Scotland, 2025. "What is the Five Safes framework?".
#'  <https://www.researchdata.scot/engage-and-learn/data-explainers/what-is-the-five-safes-framework/>
#' }
safe_data <- function(x, ...) {
  UseMethod("safe_data", x)
}

#' @export
safe_data.default <- function(x, ...) {
  stop(
    "Unknown class, please try either a file path or",
    " an object with `rocrate` class!"
  )
}

#' @export
safe_data.character <- function(x, ..., rocrate = rocrateR::rocrate_5s()) {}

#' @rdname safe_data
#' @export
safe_data.opal <- function(
  x,
  ...,
  rocrate = rocrateR::rocrate_5s(),
  project = NULL,
  tables = NULL,
  dataset_id_suffix = "#dataset:"
) {
  # declare local bindings
  created <- lastUpdate <- name <- new_dataset_entity <- NULL

  # x is a valid opal connection object
  validate_opal_con(x)

  # check if the given `project` exists, every dataset should be associated
  # with a project.
  project_exists(x, project = project)

  # retrieve details associated to `project`
  project_details_tbl <- opalr::opal.project(x, project)

  # table names, update times etc.
  project_tables <- tryCatch(
    {
      project_details_tbl |>
        purrr::pluck("datasource") |>
        purrr::pluck("table") |>
        purrr::list_c()
    },
    error = function(e) {
      list()
    }
  )

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
        x = paste0(
          dataset_id_suffix,
          digest::digest(paste0(datasource, "_", table))
        ),
        type = "Dataset",
        name = table,
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
safe_data.rocrate <- function(
  x,
  ...,
  project = NULL,
  tables = NULL,
  dataset_id_suffix = "#dataset:",
  connection = NULL
) {
  # check if the connection was given
  if (is.null(connection)) {
    stop("A `connection` object is required!", call. = FALSE)
  }

  # call method with given `connection` object:
  safe_data(
    connection,
    rocrate = x,
    project = project,
    tables = tables,
    dataset_id_suffix = dataset_id_suffix
  )
}
