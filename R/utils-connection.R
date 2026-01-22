#' Verify if project exists
#'
#' Wrapper for the [opalr::opal.project_exists()] function.
#'
#' @param x Connection object to backend for DataSHIELD server (e.g., Opal).
#' @param project String with project name to be verified.
#'
#' @returns Nothing, call for its side effect. Stop execution of script if
#' `project` does not exist in the given server.
#'
#' @keywords internal
project_exists <- function(x, ...) {
  UseMethod("project_exists", x)
}

# S3 methods ----
#' @rdname project_exists
#' @family Opal
project_exists.opal <- function(x, ..., project) {
  if (!opalr::opal.project_exists(x, project)) {
    stop(
      paste0(
        "The given `project = '",
        project,
        "'` was not found in the given Opal connection!"
      ),
      call. = FALSE
    )
  }
}

# S4 methods ----
#' @rdname project_exists
#' @family Armadillo
setMethod(
  "safe_project",
  signature(x = "armadillo"),
  function(
    x,
    ...,
    project
  ) {
    if (!(project %in% MolgenisArmadillo::armadillo.list_projects())) {
      stop(
        paste0(
          "The given `project = '",
          project,
          "'` was not found in the given Armadillo connection!"
        ),
        call. = FALSE
      )
    }
  }
)
