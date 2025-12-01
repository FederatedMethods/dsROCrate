#' Extract safe people entity(ies)
#'
#' @inheritParams safe_data
#' @param ... Other optional arguments. See the full documentation
#'
#' @returns List with safe people entity(ies).
#' @rdname extract_safe_people
#' @keywords internal
extract_safe_people <- function(x, ...) {
  UseMethod("extract_safe_people", x)
}

#' @rdname extract_safe_people
#' @export
extract_safe_people.opal <- function(x, ...) {}

#' @param id (Optional) Vector with `@id` strings for safe people entity(ies)
#'     to be extracted from the given RO-Crate, `x`.
#' @rdname extract_safe_people
#' @keywords internal
extract_safe_people.rocrate <- function(x, ..., id = NULL) {
  # if `id` wasn't provided, then extract from root (./) entity of the RO-Crate
  if (is.null(id)) {
    # extract author `@id`s from the root directory
    id <- rocrateR::get_entity(x, id = "./", type = "Dataset") |>
      lapply(\(x) getElement(x, "author")) |>
      sapply(\(x) getElement(x, "@id"))
  }

  # extract entities with type = 'Person'
  safe_people_ents <- rocrateR::get_entity(x, type = "Person")

  # filter out person-entities in the `id`
  idx <- safe_people_ents |>
    sapply(\(x) getElement(x, "@id") %in% id)
  safe_people_ents_v2 <- safe_people_ents[idx]

  # check if any entities were found
  if (length(safe_people_ents_v2) == 0) {
    stop(
      "No matching entities were found for the Author(s) in the root ",
      "entity (./):\n",
      paste0("  - ", id, collapse = "\n"),
      call. = FALSE
    )
  } else {
    message(
      length(safe_people_ents_v2),
      " 'Author' entit",
      ifelse(length(safe_people_ents_v2) == 1, "y was", "ies were"),
      " found!"
    )
  }

  # return safe people entities
  return(safe_people_ents_v2)
}
