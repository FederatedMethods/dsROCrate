#' Audit Governance
#'
#' Audit Governance for a project. This function takes:
#'
#' - a `cr8tor` archive / governance bundle (intent)
#' - a `server` object to a DataSHIELD server (deployment)
#'
#' @param x List with two named elements (`cr8tor` and `server`).
#' @param ... Arguments passed on to [rocrateR::load_rocrate()] (excluding
#'     `path`) and [audit_safe_project()] (excluding `project` and `user`).
#'
#' @returns Audit RO-Crates with 5 Safes Components.
#' @export
audit_governance <- function(x, ...) {
  UseMethod("audit_governance")
}

#' @rdname audit_governance
#' @export
audit_governance.list <- function(x, ...) {
  # check that both `cr8tor` and `server` values are provided
  idx <- c("cr8tor", "server") %in% names(x)
  if (!all(idx)) {
    stop(
      "Both a `cr8tor` and `server` are required! Missing: \n",
      paste0(" - ", c("cr8tor", "server")[!idx], collapse = "\n"),
      call. = FALSE
    )
  }

  # capture additional args
  args <- list(...)
  arg_names <- names(args)
  # exclude args that should not be passed to either function
  args_cr8tor <- args[!(arg_names %in% "path")]
  args_server <- args[!(arg_names %in% c("project", "user"))]

  # generate audits for each component
  ## cr8tor
  # utils::capture.output(
  suppressMessages(suppressWarnings({
    cr8tor_audit_roc <- do.call(
      audit_cr8tor,
      c(x = getElement(x, "cr8tor"), args_cr8tor)
    )
  })) #,
  #   file = nullfile()
  # )

  ## extract Project(s) and People from the cr8tor audit crate
  safe_project_tbl <- cr8tor_audit_roc |>
    flatten_safe_project()
  safe_people_tbl <- cr8tor_audit_roc |>
    flatten_safe_people()

  ## server
  # utils::capture.output(
  suppressMessages(suppressWarnings({
    server_audit_roc <- do.call(
      audit_safe_project,
      c(
        x = getElement(x, "server"),
        project = safe_project_tbl$project,
        user = safe_people_tbl$name,
        args_server
      )
    )
  })) #,
  #   file = nullfile()
  # )

  # combine audit RO-Crate
  gov_audit <- list(
    intent = cr8tor_audit_roc,
    deployment = server_audit_roc
  )

  # attach input args as attributes to the RO-Crate
  attr(gov_audit, "audit_type") <- "Governance audit"

  # return list with new RO-Crates
  return(gov_audit)
}
