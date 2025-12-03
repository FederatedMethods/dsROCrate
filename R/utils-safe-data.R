#' Extract safe data entity(ies)
#'
#' @inheritParams safe_data
#' @param ... Other optional arguments. See the full documentation
#'
#' @returns List with safe data entity(ies).
#' @rdname extract_safe_data
#' @keywords internal
extract_safe_data <- function(x, ...) {
  UseMethod("extract_safe_data", x)
}

#' @param rocrate (Optional) RO-Crate object to update with safe data details.
#' @rdname extract_safe_data
#' @export
extract_safe_data.opal <- function(x, ..., rocrate = rocrateR::rocrate()) {
  # extract all data sources
  ds <- opalr::opal.datasources(x)

  # cycle through the data source (x) and data project details
  for (i in seq_len(nrow(ds))) {
    project_name <- ds[i, "name"]
    project_tables <- get_project_tables(x, project_name)
    if (
      !is.na(project_name) &&
        !is.null(project_name) &&
        length(project_tables) > 0
    ) {
      rocrate <- rocrate |>
        safe_data(
          project = project_name,
          tables = project_tables,
          connection = x
        )
    }
  }

  # return RO-Crate with safe data details
  return(rocrate)
}

#' @rdname extract_safe_data
#' @export
extract_safe_data.rocrate <- function(x, ...) {
  # validate RO-Crate
  rocrateR::is_rocrate(x)
}

#' Flatten object with Safe Data details
#'
#' @param x Object (e.g., RO-Crate) with Safe Data details. This can be
#'     generated with the [extract_safe_data()] function.
#' @param id Vector of strings with the `@id`s for the datasets to be extracted.
#'     If not provided, extract all entities with `@type = 'Dataset'`.
#'
#' @returns Data frame with fields for `table` name(s) in the given object.
#' @keywords internal
flatten_safe_data <- function(x, ...) {
  UseMethod("flatten_safe_data", x)
}

#' @export
flatten_safe_data.rocrate <- function(x, ..., id = NULL) {
  tryCatch(
    {
      # extract Dataset entities
      entities_tbl <- x |>
        rocrateR::get_entity(type = "Dataset") |>
        # extract @id and name for each entity
        lapply(function(ent) {
          tibble::tibble(
            id = getElement(ent, "@id"),
            name = getElement(ent, "name")
          )
        }) |>
        # combine all rows
        dplyr::bind_rows() |>
        # filter out root (./) entity
        dplyr::filter(id != "./")

      # if `id` is provided, then only keep those entities
      if (!is.null(id)) {
        entities_tbl <- entities_tbl |>
          dplyr::filter(id %in% !!id)
      }

      # return dataset entities
      return(entities_tbl)
    },
    error = function(e) {
      tibble::tibble()
    }
  )
}
