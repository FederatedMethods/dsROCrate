#' Extract Safe Data entity(ies)
#'
#' @inheritParams safe_data
#' @param ... Other optional arguments. See the full documentation
#'
#' @returns RO-Crate with Safe Data entity(ies).
#' @rdname extract_safe_data
#' @keywords internal
extract_safe_data <- function(x, ...) {
  UseMethod("extract_safe_data", x)
}

#' @param rocrate (Optional) RO-Crate object to update with Safe Data details.
#' @rdname extract_safe_data
#' @export
extract_safe_data.opal <- function(x, ..., rocrate = rocrateR::rocrate_5s()) {
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

  # return RO-Crate with Safe Data details
  return(rocrate)
}

#' @param id (Optional) Vector with `@id` strings for Safe Data entity(ies)
#'     to be extracted from the given RO-Crate, `x`.
#' @rdname extract_safe_data
#' @export
extract_safe_data.rocrate <- function(
  x,
  ...,
  id = NULL,
  rocrate = rocrateR::rocrate_5s()
) {
  # validate RO-Crate
  rocrateR::is_rocrate(x)

  # extract Dataset entities
  entities_lst <- rocrateR::get_entity(x, type = "Dataset")

  # if `id` was provided, then filter out only those entities
  if (!is.null(id)) {
    idx <- entities_lst |>
      sapply(\(x) getElement(x, "@id") %in% id)
    entities_lst <- entities_lst[idx]
  }

  # remove root entity, ./
  idx <- entities_lst |>
    sapply(\(x) getElement(x, "@id") == "./")
  entities_lst[idx] <- NULL

  # check if any entities were found
  if (length(entities_lst) == 0) {
    stop("No matching entities were found!", call. = FALSE)
  } else {
    message(
      length(entities_lst),
      " 'Dataset' entit",
      ifelse(length(entities_lst) == 1, "y was", "ies were"),
      " found!"
    )
  }

  # add Dataset entities to the RO-Crate
  suppressWarnings({
    rocrate <- rocrate |>
      rocrateR::add_entities(entities_lst, quiet = TRUE)
  })

  # return RO-Crate with the Safe Data details
  return(rocrate)
}

#' Flatten object with Safe Data details
#'
#' @param x Object (e.g., RO-Crate) with Safe Data details. This can be
#'     generated with the [extract_safe_data()] function.
#' @param id Vector of strings with the `@id`s for the datasets to be extracted.
#'     If not provided, extract all entities with `@type = 'Dataset'`.
#'
#' @returns Data frame with safe data details.
#' @rdname flatten_safe_data
#' @keywords internal
flatten_safe_data <- function(x, ...) {
  UseMethod("flatten_safe_data", x)
}

#' @rdname flatten_safe_data
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
