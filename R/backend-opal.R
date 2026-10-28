#' @export
backend_can_audit.opal <- function(x, ..., role = FALSE) {
  res <- .try_load(backend_profile_exists(x, "default"))
  out <- list(ok = !is.null(res$value), role = NA_character_, error = res$error)
  # the extra probe is only needed to report the role
  if (role && out$ok) {
    out$role <- if (
      is.null(.try_load(backend_user_exists(x, x$username))$error)
    ) {
      "administrator"
    } else {
      "auditor"
    }
  }
  out
}

#' @export
backend_logs.opal <- function(x, ...) {
  logs <- suppressMessages(opalr::dsadmin.log(x, ...))
  logs[["@timestamp"]] <- parse_utc(logs[["@timestamp"]])
  logs
}

#' @export
backend_name.opal <- function(x, ...) {
  "OBiBa's Opal"
}

#' @export
backend_options.opal <- function(x, ...) {
  opalr::dsadmin.get_options(x, ...)
}

#' @export
backend_packages.opal <- function(x, ..., profile = "default") {
  opalr::dsadmin.package_descriptions(x, profile = profile, ...)
}

#' @export
backend_profile_exists.opal <- function(x, ...) {
  opalr::dsadmin.profile_exists(x, ...)
}

#' @export
backend_project.opal <- function(x, ...) {
  opalr::opal.project(x, ...)
}

#' @export
backend_project_exists.opal <- function(x, ...) {
  opalr::opal.project_exists(x, ...)
}

#' @export
backend_project_perms.opal <- function(x, ...) {
  opalr::opal.project_perm(x, ...)
}

#' @export
backend_projects.opal <- function(x, ...) {
  opalr::opal.projects(x, ...)
}

#' @export
backend_resource_perms.opal <- function(x, ...) {
  opalr::opal.resource_perm(x, ...)
}

#' @export
backend_resources.opal <- function(x, ...) {
  opalr::opal.resources(x, ...)
}

#' @export
backend_sys_perms.opal <- function(x, ...) {
  opalr::oadmin.system_perm(x, ...)
}

#' @export
backend_table_perms.opal <- function(x, ...) {
  opalr::opal.table_perm(x, ...)
}

#' @export
backend_tables.opal <- function(x, ...) {
  opalr::opal.tables(x, ...)
}

#' @export
backend_user_exists.opal <- function(x, ...) {
  opalr::oadmin.user_exists(x, ...)
}

#' @export
backend_users.opal <- function(x, ...) {
  opalr::oadmin.user_profiles(x, ...)
}

#' @export
validate_backend_version.opal <- function(x, ..., minimum = "5.7.2") {
  if (suppressWarnings(utils::compareVersion(x$version, minimum)) < 0) {
    stop(
      sprintf(
        "Opal >= %s is required, but server version is %s.",
        minimum,
        x$version
      ),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

#' @export
validate_con.opal <- function(x, ...) {
  tryCatch(
    {
      status <- xptr::is_null_xptr(x$handle$handle)
      if (status) {
        stop("The given connection is not valid!", call. = FALSE)
      }
    },
    error = function(e) {
      stop("The given connection is not valid!", call. = FALSE)
    }
  )
}
