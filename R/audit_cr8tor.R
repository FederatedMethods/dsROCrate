#' Audit cr8tor project archive
#'
#' This audit loads a cr8tor project archive and generates an RO-Crate object
#' with pre-deployment governance details. This then can be rendered with
#' [rocrate_report()].
#'
#' @param x Path to cr8tor archive / governance bundle.
#' @param ... Additional arguments for [rocrateR::load_rocrate].
#'
#' @returns Audit RO-Crate with 5 Safes Components.
#'
#' @references https://karectl-crates.github.io/cr8tor-metamodel/
#' @export
audit_cr8tor <- function(x, ...) {
  UseMethod("audit_cr8tor")
}

#' @rdname audit_cr8tor
#' @export
audit_cr8tor.character <- function(x, ...) {
  bundle <- load_cr8tor_bundle(x, ...)

  # call next method
  audit_cr8tor(bundle)
}

#' @rdname audit_cr8tor
#' @export
audit_cr8tor.cr8tor <- function(x, ...) {
  audit <- list(
    metadata = extract_cr8tor_metadata(x),
    integrity = extract_integrity_cr8tor(x),
    safe_people = extract_safe_people_cr8tor(x),
    safe_projects = extract_safe_projects_cr8tor(x),
    safe_data = extract_safe_data_cr8tor(x),
    safe_settings = extract_safe_settings_cr8tor(x),
    safe_outputs = extract_safe_outputs_cr8tor(x),
    user_projects = extract_user_projects_cr8tor(x),
    user_groups = extract_user_groups_cr8tor(x),
    groups = extract_groups_cr8tor(x),
    permissions = extract_permissions_cr8tor(x) #,
    # lineage = extract_lineage_cr8tor(x),
  )

  as_rocrate_audit(audit)
}

#' Convert audit result into RO-Crate
#'
#' @param audit list returned by audit_cr8tor()
#' @return rocrate object
#' @noRd
as_rocrate_audit <- function(audit) {
  rc <- rocrateR::rocrate_5s()

  # Root dataset describing the audit
  rc <- rc |>
    rocrateR::add_entity_value(
      "./",
      "name",
      "cr8tor 5 Safes Audit",
      overwrite = TRUE
    ) |>
    rocrateR::add_entity_value(
      "./",
      "description",
      "Audit report generated from cr8tor archive",
      overwrite = TRUE
    )

  # ---- Safe People ----
  rc <- rc |>
    add_group_entities_cr8tor(audit$groups) |>
    add_safe_people_entities_cr8tor(
      audit$safe_people$users,
      audit$user_projects
    ) |>
    link_people_to_root(audit$safe_people$users$username)

  # ---- Safe Projects ----
  rc <- rc |>
    add_safe_project_entities_cr8tor(
      audit$safe_projects,
      audit$safe_data$assets
    )

  # ---- Safe Data ----
  rc <- rc |>
    add_safe_data_entities_cr8tor(audit$safe_data$assets)

  # ---- Permissions ----
  rc <- rc |>
    add_permission_entities_cr8tor(
      expand_group_permissions_to_users(
        perm_tbl = audit$permissions |>
          dplyr::left_join(
            audit$safe_projects,
            by = c("project" = "project_id")
          ),
        membership_tbl = audit$user_groups,
        data_tbl = audit$safe_data$assets
      ) |>
        dedupe_effective_permissions()
    )

  # ---- Safe Settings ----
  rc <- rc |>
    add_safe_setting_entities_cr8tor(audit$safe_settings)

  # ---- Safe Outputs ----
  rc <- rc |>
    add_safe_output_entities_cr8tor(audit$safe_outputs)

  rc
}
