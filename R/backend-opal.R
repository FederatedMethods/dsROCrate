#' @export
backend_logs.opal <- function(x, ...) {
  opalr::dsadmin.log(x, ...)
}

#' @export
backend_options.opal <- function(x, ...) {
  opalr::dsadmin.get_options(x, ...)
}

#' @export
backend_packages.opal <- function(x, ...) {
  opalr::dsadmin.package_descriptions(x, ...)
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
