#' Safe people details
#'
#' Safe people details for the RO-Crate.
#'
#' @param x PENDING
#' @param ... Other optional arguments.
# @param rocrate RO-Crate object (see \link[rocrateR]{rocrate}).
#'
#' @returns Updated RO-Crate object with Safe People information.
#' @export
#'
# @examples
audit_safe_people <- function(x, ...) {
  UseMethod("audit_safe_people", x)
}

#' @rdname audit_safe_people
#' @export
audit_safe_people.default <- function(x, ...) {
  stop(
    "Unknown class, please try either a file path or",
    " an object with `rocrate` class!"
  )
}

#' @rdname audit_safe_people
#' @export
audit_safe_people.opal <- function(x, ..., project = NULL) {
  stop(
    "Unknown class, please try either a file path or",
    " an object with `rocrate` class!"
  )
}

#' @rdname audit_safe_people
#' @export
audit_safe_people.rocrate <- function(x, ...) {
  # TODO: validate RO-Crate object

  # extract author `@id`s from the root directory
  author_ids <- rocrateR::get_entity(x, id = "./", type = "Dataset") |>
    lapply(\(x) getElement(x, "author")) |>
    sapply(\(x) getElement(x, "@id"))

  # extract entities with type = 'Person'
  person_entities <- rocrateR::get_entity(x, type = "Person")

  # filter out person-entities in the `author_ids`
  idx <- person_entities |>
    sapply(\(x) getElement(x, "@id") %in% author_ids)
  person_entities_v2 <- person_entities[idx]

  # check if any entities were found
  if (length(person_entities_v2) == 0) {
    stop(
      "No matching entities were found for the Author(s) in the root ",
      "entity (./):\n",
      paste0("  - ", author_ids, collapse = "\n"),
      call. = FALSE
    )
  } else {
    message(
      length(person_entities_v2),
      " 'Author' entit",
      ifelse(length(person_entities_v2) == 1, "y was", "ies were"),
      " found!"
    )
  }

  # return invisibly
  return(invisible(person_entities_v2))
}
