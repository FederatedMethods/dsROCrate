#' Convert log calls into tibble
#'
#' @param calls List with log calls.
#' @param registry Symbol registry.
#'
#' @returns Tibble with parsed log calls.
#' @keywords internal
#'
#' @noRd
calls_to_tbl <- function(calls, registry) {
  if (length(calls) == 0L) {
    return(
      tibble::tibble(
        id = character(),
        timestamp = character(),
        action = character(),
        user = character(),
        r_cmd = character(),
        fx = character(),
        args = list(),
        symbol = character(),
        table = character(),
        session = character(),
        profile = character()
      )
    )
  }

  purrr::map(calls, \(x) {
    tibble::tibble(
      id = x$id,
      timestamp = format_utc(x$created_at),
      action = "AGGREGATE",
      user = x$user,
      r_cmd = x$original,
      fx = paste0(x$package, x$namespace, x$fx),
      args = list(x$args),
      symbol = NA_character_,
      table = list(
        x$args |>
          purrr::keep(\(arg) inherits(arg, "safe_reference")) |>
          purrr::map_chr(\(arg) resolve_symbol_asset(arg$symbol_id, registry))
      ),
      session = x$session,
      profile = x$profile
    )
  }) |>
    purrr::list_rbind()
}

#' Extract Safe Output entity(ies)
#'
#' @inheritParams safe_data
#' @inheritParams safe_output
#' @param rocrate (Optional) RO-Crate object to update with Safe Output details.
#' @param id (Optional) Vector with `@id` strings for Safe Output entity(ies)
#'     to be extracted from the given RO-Crate, `x`.
#'
#' @returns RO-Crate with Safe Output entity(ies).
#' @keywords internal
#' @noRd
extract_safe_output <- function(x, ...) {
  UseMethod("extract_safe_output")
}

#' @export
extract_safe_output.rocrate <- function(
  x,
  ...,
  id = NULL,
  user = NULL,
  rocrate = rocrateR::rocrate_5s()
) {
  # validate RO-Crate
  rocrateR::is_rocrate(x)

  # extract File entities
  entities_lst <- .get_entity(x, type = "File")

  # if `id` was provided, then filter out only those entities
  if (!is.null(id)) {
    idx <- entities_lst |>
      sapply(\(x) getElement(x, "@id") %in% id)
    entities_lst <- entities_lst[idx]
  }

  # if `user` was provided, ensure that the entities' @id, contains this user
  if (!is.null(user)) {
    idx <- entities_lst |>
      sapply(\(x) grepl(user, getElement(x, "@id")))
    entities_lst <- entities_lst[idx]
  }

  # check if any entities were found
  if (length(entities_lst) == 0) {
    stop("No matching entities were found!", call. = FALSE)
  } else {
    message(
      length(entities_lst),
      " 'File' entit",
      ifelse(length(entities_lst) == 1, "y was", "ies were"),
      " found!"
    )
  }

  # add entities to the RO-Crate &
  # return RO-Crate with the Safe Output details
  suppressWarnings({
    rocrate |>
      rocrateR::add_entity(entities_lst, verbose = FALSE)
  })
}

#' Flatten object with Safe Output details
#'
#' @param x Object (e.g., RO-Crate) with Safe Output details. This can be
#'     generated with the `extract_safe_output()` function.
#' @param id Vector of strings with the `@id`s for the outputs to be extracted.
#'     If not provided, extract all entities with `@type = 'File'`.
#'
#' @returns Data frame with object mappings and functions from safe outputs.
#' @keywords internal
#' @noRd
flatten_safe_output <- function(x, ...) {
  UseMethod("flatten_safe_output")
}

#' @export
flatten_safe_output.default <- function(x, ...) {
  tibble::tibble()
}

#' @export
flatten_safe_output.rocrate <- function(x, ..., id = NULL) {
  tryCatch(
    {
      # extract entities
      entities_tbl <- .get_entity(x, type = "File") |>
        # extract @id, name, description, encodingFormat & content for each ent.
        lapply(function(ent) {
          tibble::tibble(
            id = getElement(ent, "@id"),
            name = getElement(ent, "name"),
            description = getElement(ent, "description"),
            encodingFormat = getElement(ent, "encodingFormat"),
            content = getElement(ent, "content")
          )
        }) |>
        # combine all rows
        purrr::list_flatten() |>
        purrr::map(tibble::as_tibble) |>
        purrr::list_rbind()

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
