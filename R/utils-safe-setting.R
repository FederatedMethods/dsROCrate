#' Extract Safe Setting entity(ies)
#'
#' @inheritParams safe_data
#' @param ... Other optional arguments. See the full documentation
#'
#' @returns RO-Crate with Safe Setting entity(ies).
#' @rdname extract_safe_setting
#' @keywords internal
extract_safe_setting <- function(x, ...) {
  UseMethod("extract_safe_setting", x)
}

#' @param rocrate (Optional) RO-Crate object to update with Safe Setting details.
#' @rdname extract_safe_setting
#' @export
extract_safe_setting.opal <- function(x, ..., rocrate = rocrateR::rocrate()) {
  # extract all the safe settings for the current Opal connection
  rocrate <- safe_setting(x, rocrate = rocrate)

  # return RO-Crate with Safe Setting details
  return(rocrate)
}

#' @param id (Optional) Vector with `@id` strings for Safe Setting entity(ies)
#'     to be extracted from the given RO-Crate, `x`.
#' @rdname extract_safe_setting
#' @export
extract_safe_setting.rocrate <- function(
  x,
  ...,
  id = NULL,
  rocrate = rocrateR::rocrate()
) {
  # validate RO-Crate
  rocrateR::is_rocrate(x)

  # extract PropertyValue & SoftwareApplication entities
  entities_lst <- c(
    rocrateR::get_entity(x, type = "PropertyValue"),
    rocrateR::get_entity(x, type = "SoftwareApplication")
  )

  # if `id` was provided, then filter out only those Dataset entities
  if (!is.null(id)) {
    idx <- entities_lst |>
      sapply(\(x) getElement(x, "@id") %in% id)
    entities_lst <- entities_lst[idx]
  }

  # check if any entities were found
  if (length(entities_lst) == 0) {
    stop("No matching entities were found!", call. = FALSE)
  } else {
    message(
      length(entities_lst),
      " 'PropertyValue' OR 'SoftwareApplication' entit",
      ifelse(length(entities_lst) == 1, "y was", "ies were"),
      " found!"
    )
  }

  # add Dataset entities to the RO-Crate
  suppressWarnings({
    rocrate <- rocrate |>
      rocrateR::add_entities(entities_lst, quiet = TRUE)
  })

  # return RO-Crate with the Safe Setting details
  return(rocrate)
}

#' Flatten object with Safe Setting details
#'
#' @param x Object (e.g., RO-Crate) with Safe Setting details. This can be
#'     generated with the [extract_safe_setting()] function.
#' @param id Vector of strings with the `@id`s for the settings to be extracted.
#'     If not provided, extract all entities with `@type = 'PropertyValue'` or
#'     `@type = 'SoftwareApplication'`.
#'
#' @returns Data frame with fields for @`id`, `table` name in the given object.
#' @rdname flatten_safe_setting
#' @keywords internal
flatten_safe_setting <- function(x, ...) {
  UseMethod("flatten_safe_setting", x)
}

#' @rdname flatten_safe_setting
#' @export
flatten_safe_setting.rocrate <- function(x, ..., id = NULL) {
  tryCatch(
    {
      # extract Dataset entities
      entities_tbl <- c(
        rocrateR::get_entity(x, type = "PropertyValue"),
        rocrateR::get_entity(x, type = "SoftwareApplication")
      ) |>
        # extract @id, name, value and version for each entity
        lapply(function(ent) {
          tibble::tibble(
            id = getElement(ent, "@id"),
            name = getElement(ent, "name"),
            value = getElement(ent, "value"),
            version = getElement(ent, "version")
          )
        }) |>
        # combine all rows
        dplyr::bind_rows()

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
