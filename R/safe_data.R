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
#' @param dataset_id_suffix String with ID suffix for the tables/datasets
#'     entities in the RO-Crate (default: `"#dataset:"`).
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
  UseMethod("safe_data", x)
}

#' @export
safe_data.default <- function(x, ...) {
  stop(
    "Unknown class, please try either a file path or",
    " an object with `rocrate` class!"
  )
}

#' @export
safe_data.character <- function(x, ..., rocrate = rocrateR::rocrate_5s()) {}

#' @rdname safe_data
#' @export
safe_data.opal <- function(
  x,
  ...,
  rocrate = rocrateR::rocrate_5s(),
  project = NULL,
  tables = NULL,
  dataset_id_suffix = "#dataset:",
  project_id_suffix = "#project:",
  path = NULL,
  user = NULL
) {
  # declare local bindings
  created <- lastUpdate <- name <- new_dataset_entity <- subject <- NULL

  # x is a valid opal connection object
  validate_opal_con(x)

  # enforce that `project` is a single value
  if (is.null(project)) {
    stop("A value for `project` is required!", call. = FALSE)
  } else if (length(project) != 1) {
    stop("`project` must be a single value!", call. = FALSE)
  }

  # check if the given `project` exists, every dataset should be associated
  # with a project and retrieve details associated to `project`
  prj_dets_tbl <- get_project_details(x, project)

  # check that project details were found
  err_msg <- sprintf("No details were found for `project = '%s'!", project)
  if (is.null(prj_dets_tbl) || nrow(prj_dets_tbl) == 0) {
    stop(err_msg, call. = FALSE)
  }

  # verify if `tables` is NULL, if so, then add all data tables associated
  # to the given `project`
  if (is.null(tables)) {
    tables <- prj_dets_tbl$table
  }

  # create entity objects for each dataset/table in the project
  prj_ds_ents <- prj_dets_tbl |>
    dplyr::filter(table %in% tables) |> # filter specific tables, `tables`
    purrr::pmap(function(project, table) {
      table_details <- opalr::opal.table(x, project, table)
      timestamps <- getElement(table_details, "timestamps")
      # create entity object
      new_dataset_entity <- rocrateR::entity(
        x = paste0(
          dataset_id_suffix,
          digest::digest(paste0(project, "_", table))
        ),
        type = "Dataset",
        name = table,
        dateCreated = getElement(timestamps, "created"),
        dateModified = getElement(timestamps, "lastUpdate"),
        path = getElement(table_details, "link")
      )
      # return new entity object
      return(new_dataset_entity)
    })

  # initialise empty list with entities for user level permissions
  user_perm_entity_lst <- NULL

  # extract user permissions, if `user` is not NULL
  if (!is.null(user)) {
    ## get permissions for each table in the project
    ## get table permissions
    prj_data_perms_tbl <- seq_len(nrow(prj_dets_tbl)) |>
      lapply(\(i) get_table_permissions(x, project, prj_dets_tbl$table[i])) |>
      dplyr::bind_rows() |>
      dplyr::filter(subject == !!user)

    ## create a safe data entities data frame
    safe_data_entities_tbl <- prj_dets_tbl |>
      dplyr::mutate(
        table_id = paste0(project, "_", table),
        table_id = paste0(dataset_id_suffix, sapply(table_id, digest::digest))
      ) |>
      dplyr::select(table_id, table)

    # a warning regarding overwriting user entity is likely to trigger, which
    # can be safely ignored.
    suppressWarnings({
      safe_people_entities_tbl <- x |>
        safe_people(user = user, rocrate = rocrate) |>
        flatten_safe_people() |>
        dplyr::rename("user_id" = "id")
    })

    ## combine the table permissions with Dataset & People entities' @ids
    prj_data_perms_tbl_v2 <- prj_data_perms_tbl |>
      dplyr::left_join(safe_data_entities_tbl, by = c("table" = "table")) |>
      dplyr::left_join(safe_people_entities_tbl, by = c("subject" = "name")) |>
      dplyr::rename(user = subject)

    ## generate user permission entities and add to the RO-Crate
    user_perm_entity_lst <- prj_data_perms_tbl_v2 |>
      purrr::pmap(user_perm_entity) |>
      purrr::list_c()
  }

  # update datasets linked to `project`
  rocrate <- rocrate |>
    update_project_datasets(
      project = project,
      ds_ids = prj_ds_ents |>
        sapply("[[", "@id") |>
        unlist()
    )

  # add table entities to the `rocrate` object
  for (i in seq_along(prj_ds_ents)) {
    rocrate <- rocrate |>
      rocrateR::add_entity(prj_ds_ents[[i]], overwrite = TRUE)

    # add user permissions associated to the current table (if any)
    table_id <- getElement(prj_ds_ents[[i]], "@id")
    usr_pr_idx <- sapply(user_perm_entity_lst, getElement, "object") == table_id

    # add entity (if any) to the RO-Crate
    if (any(usr_pr_idx)) {
      rocrate <- rocrate |>
        rocrateR::add_entity(
          user_perm_entity_lst[usr_pr_idx][[1]],
          overwrite = TRUE
        )
    }
  }

  # attach input arguments as attributes
  attr(rocrate, "connection") <- x
  attr(rocrate, "path") <- path
  attr(rocrate, "project") <- project
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
  tables = attr(x, "tables"),
  dataset_id_suffix = "#dataset:",
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
    tables = tables,
    dataset_id_suffix = dataset_id_suffix,
    path = path,
    user = user
  )
}
