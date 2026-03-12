#' Safe data details
#'
#' Safe data details for the RO-Crate.
#'
#' Researchers only use de-identified data that is relevant to their study.
#'
#' In compliance with the Digital Economy Act, data is effectively anonymised
#' within TREs (Trusted Research Environments).
#'
#' This means any sensitive information that might lead to an individual being
#' identified, such as names and addresses, is either removed or replaced with
#' a random code. Researchers are not processing personal data when using data
#' prepared in this way and when the other Safes are in place. Find out more
#' about de-identification:
#' <https://www.researchdata.scot/engage-and-learn/data-explainers/what-is-data-de-identification/>
#'
#' @param x This can be a connection to a 'DataSHIELD' server (e.g., object with
#'     the `opal` class, see [opalr::opal.login()]), an RO-Crate
#'     ([rocrate][rocrateR::rocrate()] class) or a string with the path to an
#'     RO-Crate.
#' @param ... Other optional arguments. See the full documentation,
#'     [`?dsROCrate::safe_data`][safe_data()].
#' @param include Vector of strings with types of assets to be included, either
#'     `"resources"`, `"tables"` or both.
#' @param asset_id_suffix String with ID suffix for the tables/datasets
#'     entities in the RO-Crate (default: `"#asset:"`).
#' @param project_id_suffix String with ID suffix for the project entities
#'     in the RO-Crate (default: `"#project:"`).
#' @inheritParams init
#'
#' @returns Updated RO-Crate object with Safe Data information.
#' @export
#'
#' @source
#' \itemize{
#'  \item Research Data Scotland, 2025. "What is the Five Safes framework?".
#'  <https://www.researchdata.scot/engage-and-learn/data-explainers/what-is-the-five-safes-framework/>
#' }
safe_data <- function(x, ...) {
  UseMethod("safe_data")
}

#' @export
safe_data.default <- function(x, ...) {
  stop(
    "Unknown class, please try either a file path or",
    " an object with `rocrate` class!"
  )
}

#' @rdname safe_data
#' @export
safe_data.character <- function(
  x,
  ...,
  project = attr(x, "project"),
  resources = attr(x, "resources"),
  tables = attr(x, "tables"),
  asset_id_suffix = "#asset:",
  project_id_suffix = "#project:",
  connection = attr(x, "connection"),
  path = attr(x, "path"),
  user = attr(x, "user")
) {
  # attempt loading the RO-Crate
  rocrate <- rocrateR::load_rocrate(x)

  # call method with given `rocrate` object:
  safe_data(
    rocrate,
    connection = connection,
    project = project,
    resources = resources,
    tables = tables,
    asset_id_suffix = asset_id_suffix,
    project_id_suffix = project_id_suffix,
    path = path,
    user = user
  )
}

#' @rdname safe_data
#' @export
safe_data.opal <- function(
  x,
  ...,
  rocrate = rocrateR::rocrate_5s(),
  project = NULL,
  resources = NULL,
  tables = NULL,
  include = c("tables", "resources"),
  asset_id_suffix = "#asset:",
  project_id_suffix = "#project:",
  path = NULL,
  user = NULL
) {
  # declare local bindings
  created <- lastUpdate <- name <- new_dataset_entity <- subject <- NULL

  # x is a valid opal connection object
  validate_opal_con(x)

  # match the assets to be included
  include <- match.arg(include, several.ok = TRUE)

  # enforce that `project` is a single value
  if (is.null(project)) {
    stop("A value for `project` is required!", call. = FALSE)
  } else if (length(project) != 1) {
    stop("`project` must be a single value!", call. = FALSE)
  }

  project_id <- id_hash(project_id_suffix, project)

  # extract assets for the given project
  all_assets <- list()

  # ---- tables ----
  if ("tables" %in% include) {
    tbl_assets <- get_project_assets(x, project, "tables")
    if (!is.null(tbl_assets)) {
      if (!is.null(tables)) {
        tbl_assets <- dplyr::filter(tbl_assets, name %in% tables)
      }
      all_assets$tables <- tbl_assets
    }
  }

  # ---- resources ----
  if ("resources" %in% include) {
    res_assets <- get_project_assets(x, project, "resources")
    if (!is.null(res_assets)) {
      if (!is.null(resources)) {
        res_assets <- dplyr::filter(res_assets, name %in% resources)
      }
      all_assets$resources <- res_assets
    }
  }

  # combine assets
  assets_tbl <- dplyr::bind_rows(all_assets)

  # check that project assets were found
  err_msg <- sprintf("No details were found for `project = '%s'!", project)
  if (is.null(assets_tbl) || nrow(assets_tbl) == 0) {
    stop(err_msg, call. = FALSE)
  }

  # build asset entities ----
  asset_entities <- build_asset_entities(
    assets_tbl,
    project_id = project_id,
    asset_id_suffix = asset_id_suffix
  )

  # link asset entities with project entity
  rocrate <- link_assets_to_project(
    rocrate,
    project_id,
    vapply(asset_entities, `[[`, "", "@id")
  )

  # build ID lookup ----
  id_lookup <- stats::setNames(
    vapply(asset_entities, `[[`, "", "@id"),
    assets_tbl$name
  )

  # lineage ----
  lineage_df <- infer_table_resource_lineage(assets_tbl)

  rocrate <- add_lineage_relations(
    rocrate,
    lineage_df,
    id_lookup
  )

  # permissions ----
  rocrate <- add_asset_permissions_to_crate(
    rocrate,
    x,
    project,
    assets_tbl,
    id_lookup
  )

  # add asset entities to the RO-Crate
  rocrate <- purrr::reduce(
    asset_entities,
    rocrateR::add_entity,
    .init = rocrate,
    overwrite = TRUE
  )

  # # check if the given `project` exists, every dataset should be associated
  # # with a project and retrieve details associated to `project`
  # prj_dets_tbl <- get_project_details(x, project)
  #
  # # check that project details were found
  # err_msg <- sprintf("No details were found for `project = '%s'!", project)
  # if (is.null(prj_dets_tbl) || nrow(prj_dets_tbl) == 0) {
  #   stop(err_msg, call. = FALSE)
  # }
  #
  # # verify if `tables` is NULL, if so, then add all data tables associated
  # # to the given `project`
  # if (is.null(tables)) {
  #   tables <- prj_dets_tbl$table
  # }
  #
  # # attach project @ids
  # prj_dets_tbl <- prj_dets_tbl |>
  #   dplyr::mutate(
  #     project_id = paste0(project_id_suffix, digest::digest(!!project))
  #   )
  #
  # # create entity objects for each dataset/table in the project
  # prj_ds_ents <- prj_dets_tbl |>
  #   dplyr::filter(table %in% tables) |> # filter specific tables, `tables`
  #   purrr::pmap(function(project, table, project_id) {
  #     table_details <- opalr::opal.table(x, project, table)
  #     timestamps <- getElement(table_details, "timestamps")
  #     # create entity object
  #     new_dataset_entity <- rocrateR::entity(
  #       id = paste0(
  #         dataset_id_suffix,
  #         digest::digest(paste0(project, "_", table))
  #       ),
  #       type = "Dataset",
  #       name = table,
  #       dateCreated = getElement(timestamps, "created"),
  #       dateModified = getElement(timestamps, "lastUpdate"),
  #       path = getElement(table_details, "link"),
  #       isPartOf = list(`@id` = project_id)
  #     )
  #     # return new entity object
  #     return(new_dataset_entity)
  #   })
  #
  # # initialise empty list with entities for user level permissions
  # user_perm_entity_lst <- NULL
  #
  # # extract user permissions, if `user` is not NULL
  # if (!is.null(user)) {
  #   ## get permissions for each table in the project
  #   ## get table permissions
  #   prj_data_perms_tbl <- seq_len(nrow(prj_dets_tbl)) |>
  #     lapply(\(i) get_table_permissions(x, project, prj_dets_tbl$table[i])) |>
  #     dplyr::bind_rows() |>
  #     dplyr::filter(subject == !!user)
  #
  #   ## create a safe data entities data frame
  #   safe_data_entities_tbl <- prj_dets_tbl |>
  #     dplyr::mutate(
  #       table_id = paste0(project, "_", table),
  #       table_id = paste0(dataset_id_suffix, sapply(table_id, digest::digest))
  #     ) |>
  #     dplyr::select(table_id, table)
  #
  #   # a warning regarding overwriting user entity is likely to trigger, which
  #   # can be safely ignored.
  #   suppressWarnings({
  #     safe_people_entities_tbl <- x |>
  #       safe_people(user = user, rocrate = rocrate) |>
  #       flatten_safe_people() |>
  #       dplyr::rename("user_id" = "id")
  #   })
  #
  #   ## combine the table permissions with Dataset & People entities' @ids
  #   prj_data_perms_tbl_v2 <- prj_data_perms_tbl |>
  #     dplyr::left_join(safe_data_entities_tbl, by = c("table" = "table")) |>
  #     dplyr::left_join(safe_people_entities_tbl, by = c("subject" = "name")) |>
  #     dplyr::rename(user = subject)
  #
  #   ## generate user permission entities and add to the RO-Crate
  #   user_perm_entity_lst <- prj_data_perms_tbl_v2 |>
  #     purrr::pmap(user_perm_entity) |>
  #     purrr::list_c()
  # }
  #
  # # update datasets linked to `project`
  # rocrate <- rocrate |>
  #   update_project_datasets(
  #     project = project,
  #     ds_ids = prj_ds_ents |>
  #       sapply("[[", "@id") |>
  #       unlist()
  #   )
  #
  # # add table entities to the `rocrate` object
  # for (i in seq_along(prj_ds_ents)) {
  #   rocrate <- rocrate |>
  #     rocrateR::add_entity(prj_ds_ents[[i]], overwrite = TRUE)
  #
  #   # add user permissions associated to the current table (if any)
  #   table_id <- getElement(prj_ds_ents[[i]], "@id")
  #   usr_pr_idx <- sapply(user_perm_entity_lst, getElement, "object") == table_id
  #
  #   # add entity (if any) to the RO-Crate
  #   if (any(usr_pr_idx)) {
  #     rocrate <- rocrate |>
  #       rocrateR::add_entity(
  #         user_perm_entity_lst[usr_pr_idx][[1]],
  #         overwrite = TRUE
  #       )
  #   }
  # }

  # attach input arguments as attributes
  attr(rocrate, "connection") <- x
  attr(rocrate, "path") <- path
  attr(rocrate, "project") <- project
  attr(rocrate, "resources") <- resources
  attr(rocrate, "tables") <- tables
  attr(rocrate, "user") <- user

  # return RO-Crate with the new entity
  return(rocrate)
}

#' @rdname safe_data
#' @export
safe_data.rocrate <- function(
  x,
  ...,
  project = attr(x, "project"),
  resources = attr(x, "resources"),
  tables = attr(x, "tables"),
  asset_id_suffix = "#asset:",
  project_id_suffix = "#project:",
  connection = attr(x, "connection"),
  path = attr(x, "path"),
  user = attr(x, "user")
) {
  # check if the connection was given
  if (is.null(connection)) {
    stop("A `connection` object is required!", call. = FALSE)
  }

  # call method with given `connection` object:
  safe_data(
    connection,
    rocrate = x,
    project = project,
    resources = resources,
    tables = tables,
    asset_id_suffix = asset_id_suffix,
    project_id_suffix = project_id_suffix,
    path = path,
    user = user
  )
}
