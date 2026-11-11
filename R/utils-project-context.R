#' Project context
#'
#' A project context keeps the requests made to the backend about a project, so
#' they are made once and shared across the `safe_*()` functions (e.g., if the
#' project exists, its tables and its resources).
#'
#' The context is stored in the RO-Crate (see `set_project_context()`) and it is
#' only reused for the same project and the same connection. It lives as long as
#' the RO-Crate: run `init()` again to refresh it. Functions that are called
#' without a context (e.g., with a new RO-Crate) create their own.
#'
#' @param connection Connection to DataSHIELD server (e.g., OBiBa's Opal
#'     server).
#' @param project String with project name.
#'
#' @returns Project context object.
#' @keywords internal
#' @noRd
new_project_context <- function(connection, project) {
  context <- new.env(parent = emptyenv())
  context$connection <- connection
  context$project <- project
  # requests already made, e.g., `exists`, `tables` and `resources`
  context$cache <- new.env(parent = emptyenv())
  class(context) <- "project_context"
  context
}

#' @param x Object to be tested.
#' @noRd
is_project_context <- function(x) {
  inherits(x, "project_context")
}

#' Get project context
#'
#' @param x Connection to DataSHIELD server (e.g., OBiBa's Opal server).
#' @param project String with project name (a single value).
#' @param rocrate RO-Crate object, that may contain the context for `project`.
#'
#' @returns The project context stored in `rocrate`, if it was created for the
#'     same `project` and connection. Otherwise, a new project context.
#' @keywords internal
#' @noRd
get_project_context <- function(x, project, rocrate = NULL) {
  context <- attr(rocrate, "project_context", exact = TRUE)[[project]]

  if (is_project_context(context) && identical(context$connection, x)) {
    return(context)
  }

  new_project_context(x, project)
}

#' Store project context in an RO-Crate
#'
#' @param rocrate RO-Crate object.
#' @param context Project context object.
#'
#' @returns Updated `rocrate` object. The contexts of other projects are kept.
#' @keywords internal
#' @noRd
set_project_context <- function(rocrate, context) {
  contexts <- attr(rocrate, "project_context", exact = TRUE)
  if (is.null(contexts)) {
    contexts <- list()
  }
  contexts[[context$project]] <- context
  attr(rocrate, "project_context") <- contexts
  rocrate
}

#' Remove the project contexts from an RO-Crate
#'
#' @param rocrate RO-Crate object.
#'
#' @returns Updated `rocrate` object.
#' @keywords internal
#' @noRd
reset_project_context <- function(rocrate) {
  attr(rocrate, "project_context") <- NULL
  rocrate
}

#' Verify that the project exists (once)
#'
#' Only successful checks are remembered, so a missing project is reported every
#' time.
#'
#' @param context Project context object.
#'
#' @returns `TRUE`, invisibly. If the project does not exist, an error is
#'     thrown.
#' @keywords internal
#' @noRd
project_context_exists <- function(context) {
  if (!isTRUE(context$cache$exists)) {
    project_exists(context$connection, project = context$project)
    assign("exists", TRUE, envir = context$cache)
  }
  invisible(TRUE)
}

#' Get the project assets (once)
#'
#' @inheritParams project_context_exists
#' @param type Type of assets to extract, either `tables` or `resources`.
#'
#' @returns Tibble with project assets details, or `NULL` if there are none.
#' @keywords internal
#' @noRd
project_context_assets <- function(context, type = c("tables", "resources")) {
  type <- match.arg(type)

  if (!exists(type, envir = context$cache, inherits = FALSE)) {
    project_context_exists(context)
    assets <- get_project_assets(
      context$connection,
      context$project,
      type,
      check = FALSE
    )
    # NOTE: `NULL` (no assets) is also remembered
    assign(type, assets, envir = context$cache)
  }

  get(type, envir = context$cache, inherits = FALSE)
}
