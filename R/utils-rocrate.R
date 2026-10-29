#' Load `content` from external files
#'
#' @param rocrate Object with the [rocrate][rocrateR::rocrate()] class.
#' @param roc_path String with path to the root of the RO-Crate.
#'
#' @returns Updated `rocrate` object.
#' @keywords internal
#' @noRd
load_content <- function(rocrate, roc_path) {
  # get 'File' entities with missing `content` (if any)
  file_ents <- rocrate |>
    .get_entity(type = "File") |>
    Filter(f = function(x) is.null(getElement(x, "content")))
  ## attempt loading contents, if any entities were found
  for (ent in file_ents) {
    # attempt loading the contents from the filenames given by `@id`
    content <- tryCatch(
      {
        if (getElement(ent, "encodingFormat") == "text/csv") {
          utils::read.csv(file.path(roc_path, getElement(ent, "@id")))
        } else {
          readLines(file.path(roc_path, getElement(ent, "@id")))
        }
      },
      error = function(e) {
        NULL
      },
      warning = function(e) {
        NULL
      }
    )

    # update entity within the RO-Crate
    if (!is.null(content)) {
      rocrate <- rocrate |>
        rocrateR::add_entity_value(
          id = getElement(ent, "@id"),
          key = "content",
          value = list(content)
        )
    }
  }

  return(rocrate)
}

#' Get RO-Crate context/attributes
#'
#' Reads the context stored in an RO-Crate by `set_crate_context()`, e.g., the
#' connection and the Five Safes details given to [init()].
#'
#' @param rocrate RO-Crate object.
#' @param which String with the name of a single context value to extract (one
#'     of `attrs`). If `NULL` (default), all the values are
#'     returned.
#'
#' @returns The requested value (`NULL` if it was not set) or, if `which` is
#'     `NULL`, a named list with all the context values.
#' @keywords internal
#' @noRd
get_crate_context <- function(rocrate, which = NULL) {
  attrs <- c(
    "connection",
    "path",
    "profile",
    "project",
    "resources",
    "tables",
    "user"
  )
  if (is.null(which)) {
    ctx <- attrs |>
      lapply(\(field) attr(rocrate, field, exact = TRUE))
    return(stats::setNames(ctx, attrs))
  }

  if (!is.character(which) || length(which) != 1 || !which %in% attrs) {
    stop(
      sprintf(
        "`which` must be one of: %s.",
        paste0("`", attrs, "`", collapse = ", ")
      ),
      call. = FALSE
    )
  }

  # NOTE: no partial matching, e.g., `path` must not match `pathway`
  attr(rocrate, which, exact = TRUE)
}

#' Set RO-Crate context/attributes
#'
#' Stores the connection and the Five Safes details in the attributes of an
#' RO-Crate, so that the `safe_*()` functions need no further arguments.
#' Values that are `NULL` remove the corresponding attribute.
#'
#' @param rocrate RO-Crate object.
#' @param connection,path,profile,project,resources,tables,user Context values
#'     (see `attrs`).
#' @param validated Boolean flag to indicate that the backend `connection` has
#'     been validated (see `validate_backend()`). It must only be `TRUE` when
#'     the caller has validated the connection (default: `FALSE`, so the
#'     connection is validated again by the next function).
#'
#' @returns Updated `rocrate` object.
#' @keywords internal
#' @noRd
set_crate_context <- function(
  rocrate,
  connection = NULL,
  path = NULL,
  profile = NULL,
  project = NULL,
  resources = NULL,
  tables = NULL,
  user = NULL,
  validated = FALSE
) {
  # attach input arguments as attributes
  attr(rocrate, "connection") <- connection
  attr(rocrate, "path") <- path
  attr(rocrate, "profile") <- profile
  attr(rocrate, "project") <- project
  attr(rocrate, "resources") <- resources
  attr(rocrate, "tables") <- tables
  attr(rocrate, "user") <- user
  # only trusted when the caller validated the backend connection
  attr(rocrate, "backend_validated") <- isTRUE(validated)
  return(rocrate)
}
