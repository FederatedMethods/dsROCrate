#' Create an audit RO-Crate
#'
#' Create an audit RO-Crate following the 5 Safes Principles.
#'
#' This function handles various audit types, which will be dispatched based on
#' the input object. If the input object is
#'
#' \itemize{
#'     \item a _connection_ to a DataSHIELD server (e.g., OBiBa's Opal):
#'.    generates an RO-Crate object with deployment details, including outputs.
#'     \item a _path_ pointing to
#'     \itemize{
#'         \item **a `cr8tor` archive / governance bundle**: generates an
#'         RO-Crate object with pre-deployment governance details.
#'         \item **an RO-Crate object**: generates an RO-Crate object with
#'         clearly defined 5 Safes elements.
#'     }
#'     \item an _RO-Crate_ object: generates an RO-Crate object with clearly
#'     defined 5 Safes elements.
#' }
#' @param x Object to be audited. This can be
#'     \itemize{
#'         \item a _connection_ to a DataSHIELD server (e.g., OBiBa's Opal).
#'         \item a _path_ pointing to an RO-Crate OR a `cr8tor` archive /
#'.        governance bundle.
#'         \item an _RO-Crate_ object.
#'     }
#'     Alternatively, a list of any of the above.
#' @param ... Additional arguments.
#' @param intent Additional object with governance bundle/specification of the
#'     intent of a project. It takes the same types as `x`.
#' @inheritParams audit_engine
#'
#' @returns RO-Crate with audit details.
#' @export
audit <- function(x, ...) {
  UseMethod("audit")
}

#' @rdname audit
#' @export
audit.armadillo <- function(x, ..., intent = NULL) {
  # <PLACEHOLDER>
}

#' @rdname audit
#' @export
audit.character <- function(x, ..., intent = NULL) {
  # verify if the given path exists, if not, return an error message
  if (!file.exists(x)) {
    stop("The given file does not exist!", call. = FALSE)
  }

  # attempt loading a `cr8tor` bundle
  x_obj <- tryCatch(
    load_cr8tor_bundle(x, ...),
    error = function(e) NULL
  )
  # alternatively, attempt loading an RO-Crate
  if (is.null(x_obj)) {
    x_obj <- tryCatch(
      rocrateR::load_rocrate(x, ...),
      error = function(e) NULL
    )
  }

  if (is.null(x_obj)) {
    stop(
      "The given path does not point to a valid `cr8tor` archive nor an `rocrate",
      call. = FALSE
    )
  }

  # if `intent` is NOT NULL, audit this object
  intent_audit <- if (!is.null(intent)) {
    audit(intent, ...)
  } else {
    NULL
  }

  # list of additional args
  main_audit_args <- list(...)

  # check if `intent_audit` is not NULL
  if (!is.null(intent_audit)) {
    # extract Project(s) and People from the `intent` audit crate
    safe_project_tbl <- intent_audit |>
      flatten_safe_project()
    safe_people_tbl <- intent_audit |>
      flatten_safe_people()

    main_audit_args <- exclude_args(..., c("project", "user"))

    main_audit_args <- c(
      main_audit_args,
      project = safe_project_tbl$project,
      user = safe_people_tbl$name
    )
  }

  # call next method
  main_audit <- audit(x_obj, main_audit_args)

  # return list
  list(intent = intent_audit, deployment = main_audit)
}

#' @rdname audit
#' @export
audit.cr8tor <- function(x, ..., intent = NULL) {
  audit_engine(x, exclude_args(..., "path"), intent = intent)
}

#' @rdname audit
#' @export
audit.list <- function(x, ..., intent = NULL) {
  purrr::map(x, audit, ..., intent = intent)
}

#' @rdname audit
#' @export
audit.opal <- function(
  x,
  ...,
  intent = NULL,
  project = NULL,
  user = NULL,
  logs_from = -Inf,
  logs_to = Inf,
  path = NULL
) {
  audit_engine(
    x,
    project = project,
    user = user,
    logs_from = logs_from,
    logs_to = logs_to,
    path = path
  )
}

#' @rdname audit
#' @export
audit.rocrate <- function(x, ..., intent = NULL) {
  # <PLACEHOLDER>
}
