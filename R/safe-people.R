#' Safe people details
#'
#' Safe people details for the RO-Crate.
#'
#' Researchers must be accredited and trained before accessing the data that
#' has been prepared for them.
#'
#' The access service provider may require the researcher to sign a statement
#' that they know and understand the regulations of the TRE.
#'
#' @inheritParams safe_data
#' @param ... Other optional arguments. See the full documentation,
#'     [`?dsROCrate::safe_people`][safe_people()].
#' @param user List (or [entity][rocrateR::entity()] object) with details for
#'     the safe people, it must include `@id` and `name` entries. Alternatively,
#'     this can be a string with the `name` of the current user.
#' @param user_id_suffix String with ID suffix for the tables/datasets
#'     entities in the RO-Crate (default: `"#dataset:"`).
#' @param set_author Boolean flag to indicate if the current user should be
#'     set as the author of the RO-Crate.
#'
#' @returns Updated RO-Crate object with Safe People information.
#' @export
#'
#' @source
#' \itemize{
#'  \item Research Data Scotland, 2025. "What is the Five Safes framework?".
#'  <https://www.researchdata.scot/engage-and-learn/data-explainers/what-is-the-five-safes-framework/>
#' }
safe_people <- function(x, ...) {
  UseMethod("safe_people", x)
}

#' @export
safe_people.default <- function(x, ...) {
  stop(
    "Unknown class, please try either a file path or",
    " an object with `rocrate` class!"
  )
}

#' @export
safe_people.character <- function(x, ..., rocrate = NULL) {}

#' @rdname safe_people
#' @export
safe_people.opal <- function(
  x,
  ...,
  rocrate = NULL,
  user = NULL,
  user_id_suffix = "#person:",
  set_author = TRUE
) {
  # x is a valid opal connection object
  # TODO validate connection

  # attempt to retrieve project entity
  safe_project_entity <- rocrate |>
    rocrateR::get_entity(type = "Project")

  # initialise empty user entity
  user_entity <- NULL

  # check if `user` was given
  if (!is.null(user)) {
    # check if user is a list, if so, then use all the elements as part of
    # the user_entity
    if ("list" %in% class(user)) {
      user_entity <- rocrateR::entity(
        x = c(getElement(user, "@id"), getElement(user, "id")),
        type = "Person",
        name = c(getElement(user, "name"), getElement(user, "username")),
        affiliation = list(`@id` = c(getElement(user, "affiliation")))
      )
    } else {
      user_entity <- rocrateR::entity(
        x = paste0(user_id_suffix, digest::digest(user)),
        type = "Person",
        name = user
      )
    }
  } else {
    # extract user information from the connection object
    user_entity <- rocrateR::entity(
      x = paste0(user_id_suffix, digest::digest(x$username)),
      type = "Person",
      name = x$username
    )
  }

  # add membership information, if Safe Project was found
  if (length(safe_project_entity)) {
    user_entity$memberOf <- safe_project_entity |>
      lapply(\(x) list(`@id` = x[["@id"]]))
  }

  # add user to the RO-Crate
  rocrate <- rocrate |>
    rocrateR::add_entity(user_entity, overwrite = TRUE)

  # link new user entity @id to the root (./) author property
  if (set_author) {
    rocrate <- rocrate |>
      rocrateR::add_entity_value(
        id = "./",
        key = "author",
        value = list(`@id` = getElement(user_entity, "@id"))
      )
  }

  # return RO-Crate with the new entity
  return(rocrate)
}

#' @rdname safe_people
#' @export
safe_people.rocrate <- function(
  x,
  ...,
  user = NULL,
  user_id_suffix = "#person:",
  connection = NULL
) {
  # check if the connection was given
  if (is.null(connection)) {
    stop("A `connection` object is required!", call. = FALSE)
  }

  # TODO: Validate `connection` object

  # call method with given `connection` object:
  safe_people(
    connection,
    rocrate = x,
    user = user,
    user_id_suffix = user_id_suffix
  )
}
