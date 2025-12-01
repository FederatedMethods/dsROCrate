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

#' @param rocrate (Optional) RO-Crate object to update with safe people details.
#' @rdname extract_safe_people
#' @export
extract_safe_people.opal <- function(x, ..., rocrate = rocrateR::rocrate()) {
  # extract all users
  opal_users <- opalr::oadmin.users(x)

  # cycle through the data source (x) and extract project details
  for (i in seq_len(nrow(opal_users))) {
    username <- opal_users[i, "name"]
    if (!is.na(username) && !is.null(username)) {
      suppressWarnings({
        rocrate <- rocrate |>
          safe_people(user = username, connection = x, set_author = FALSE)
      })
    }
  }

  # return RO-Crate with safe project details
  return(rocrate)
}

#' @param id (Optional) Vector with `@id` strings for safe people entity(ies)
#'     to be extracted from the given RO-Crate, `x`.
#' @rdname extract_safe_people
#' @keywords internal
extract_safe_people.rocrate <- function(
  x,
  ...,
  id = NULL,
  rocrate = rocrateR::rocrate()
) {
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

  # add user to the RO-Crate
  rocrate <- rocrate |>
    rocrateR::add_entity(safe_people_ents_v2, overwrite = TRUE) |>
    # link new user entity @id to the root (./) author property
    rocrateR::add_entity_value(
      id = "./",
      key = "author",
      value = list(`@id` = getElement(safe_people_ents_v2, "@id"))
    )

  # return RO-Crate with the safe_people details
  return(rocrate)
}
