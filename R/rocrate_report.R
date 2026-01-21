#' Create an RO-Crate report
#'
#' @param x This can be an RO-Crate ([rocrate][rocrateR::rocrate()] class) or a
#'     string with the path to an RO-Crate.
#' @param ... Other optional arguments. See the full documentation,
#'     [`?dsROCrate::rocrate_report`][rocrate_report()].
#'
#' @returns RO-Crate report as markdown (.md) file and/or HTML.
#' @export
rocrate_report <- function(x, ...) {
  UseMethod("rocrate_report", x)
}

#' @rdname rocrate_report
#' @export
rocrate_report.character <- function(x, ...) {
  message("TODO: This generic method hasn't been implemented yet!")
}

#' @rdname rocrate_report
#' @export
rocrate_report.default <- function(x, ...) {
  stop(
    "Unknown class, please try either a file path or",
    " an object with `rocrate` class!"
  )
}

#' @param title String with title for the report (default: 'DataSHIELD Report').
#' @param filepath String with file path for Markdown report with the summary
#'     of the given object, `x`.
#' @param render Boolean flag to indicate whether to render the markdown report.
#' @param overwrite Boolean flag to indicate whether to overwrite a previous
#'     version of markdown report.
#' @param include_user_perm Boolean flag to indicate whether to include user
#'     permissions in the report overview's diagram.
#' @rdname rocrate_report
#' @export
rocrate_report.rocrate <- function(
  x,
  ...,
  title = "DataSHIELD Report\n",
  filepath = tempfile(fileext = ".md"),
  render = TRUE,
  overwrite = FALSE,
  include_user_perm = TRUE
) {
  # local bindings
  id <- name <- project <- table_id <- table_name <- username <- user_id <- NULL
  actionStatus <- description <- ds_function <- ds_table <- type <- NULL
  encodingFormat <- permission <- NULL

  # validate RO-Crate
  rocrateR::is_rocrate(x)

  # ensure the given file path exists
  if (!dir.exists(dirname(filepath))) {
    stop(
      "The given file path directory does not exist. Try running the following",
      "command first:\n\t`mkdir -r",
      dirname(filepath),
      "`",
      call. = FALSE
    )
  }

  # check if the filepath points to an existing file
  if (file.exists(filepath)) {
    if (!overwrite) {
      stop(
        "The given file path points to an existing file. Try setting ",
        "`overwrite = TRUE` or changing the file path!",
        call. = FALSE
      )
    }
  }

  # attempt to extract Safe People details
  safe_people_rocrate <- tryCatch(
    {
      extract_safe_people(x)
    },
    error = function(e) {
      NULL
    }
  )

  # attempt to extract Safe Data details
  safe_data_rocrate <- tryCatch(
    {
      extract_safe_data(x)
    },
    error = function(e) {
      NULL
    }
  )

  # attempt to extract user permission entities
  user_perm_entity_lst <- tryCatch(
    {
      # TODO: Update the following to single call, once this issue has been
      # resolved: https://github.com/ResearchObject/ro-crate-r/issues/5
      c("ReadAction", "WriteAction", "ControlAction") |>
        sapply(\(t) rocrateR::get_entity(x, type = t)) |>
        purrr::list_c()
    },
    error = function(e) {
      NULL
    }
  )

  # extract project IDs from the Safe People RO-Crate
  member_of <- safe_people_rocrate |>
    rocrateR::get_entity(type = "Person") |>
    sapply(\(x) getElement(x, "memberOf")) |>
    unlist()

  # attempt to extract Safe Project details
  safe_project_rocrate <- tryCatch(
    {
      extract_safe_project(x, id = member_of)
    },
    error = function(e) {
      NULL
    }
  )

  # attempt to extract Safe Setting details
  safe_setting_rocrate <- tryCatch(
    {
      extract_safe_setting(x)
    },
    error = function(e) {
      NULL
    }
  )

  # attempt to extract Safe Output details
  safe_outputs_rocrate <- tryCatch(
    {
      extract_safe_output(x)
    },
    error = function(e) {
      NULL
    }
  )

  # create Markdown report
  report_contents <- paste0(
    paste0("# ", title, "\n"),
    "##### Last Updated: ",
    format(Sys.time(), '%Y-%m-%d %H:%M:%S'),
    "\n"
  )

  ## create visualisation for the overview
  ### extract (if available) table with user permissions
  user_perm_tbl <- flatten_user_perm_entity(user_perm_entity_lst)
  ### extract table with Safe People details
  safe_people_tbl <- flatten_safe_people(safe_people_rocrate) |>
    dplyr::rename(user_id = id)
  ### extract table with Safe Project details
  safe_project_tbl <- flatten_safe_project(safe_project_rocrate)
  ### extract table with Safe Data details
  safe_data_tbl <- flatten_safe_data(safe_data_rocrate) |>
    dplyr::rename(table_id = id, table_name = name)
  if (!is.null(user_perm_tbl) && nrow(user_perm_tbl) > 0) {
    overview_tbl <- user_perm_tbl |>
      # combine with Safe People details
      dplyr::left_join(safe_people_tbl, by = "user_id") |>
      # drop unused columns
      dplyr::select(-id, -actionStatus, -description) |>
      # combine with Safe Data details
      dplyr::left_join(safe_data_tbl, by = c("table_id")) |>
      # combine with Safe Project details
      dplyr::left_join(safe_project_tbl, by = c("table_name" = "table")) |>
      # drop unused columns
      dplyr::select(-id, -user_id, -table_id, -type) |>
      dplyr::rename(table = table_name)
  } else {
    overview_tbl <- flatten_safe_people(safe_people_rocrate) |>
      dplyr::select(-id) |>
      dplyr::bind_cols(
        flatten_safe_project(safe_project_rocrate) |>
          dplyr::select(-id)
      )
  }

  # attempt extracting list of functions executed by the users from Safe Outputs
  safe_output_tbl <- flatten_safe_output(safe_outputs_rocrate) |>
    # extract only entities with mappings and functions, stored in CSV format
    dplyr::filter(encodingFormat == "text/csv") |>
    # extract content
    purrr::pluck("content", .default = list()) |>
    purrr::list_c()

  if (!is.null(safe_output_tbl) && nrow(safe_output_tbl) > 0) {
    # split `ds_table` into `project` and `table`
    safe_output_tbl_v2 <- safe_output_tbl |>
      dplyr::mutate(
        project = gsub("(?=\\.).*$", "", ds_table, perl = TRUE),
        table = gsub("^.*(?<=\\.)", "", ds_table, perl = TRUE)
      ) |>
      dplyr::distinct(project, table, username, ds_function, timestamp)

    # append the list of functions to the overview table
    overview_tbl <- overview_tbl |>
      dplyr::left_join(
        safe_output_tbl_v2,
        by = c("project" = "project", "table" = "table", "name" = "username")
      ) |>
      # replace 'NA' in ds_function & timestamp with empty string
      dplyr::mutate(
        timestamp = dplyr::case_when(is.na(timestamp) ~ "", T ~ timestamp),
        ds_function = dplyr::case_when(is.na(ds_function) ~ "", T ~ ds_function)
      )
  }

  ## initialise `vars` and `labelvar`
  vars <- labelvar <- NULL
  ## check if `overview_tbl` has `permission` field AND include_user_perm = TRUE
  if ("permission" %in% colnames(overview_tbl) && include_user_perm) {
    # check if `overview_tbl` has `ds_function` field
    if ("ds_function" %in% colnames(overview_tbl)) {
      overview_agg <- overview_tbl |>
        dplyr::group_by(project, table, name, ds_function) |>
        dplyr::reframe(
          permission = paste0(unique(permission), collapse = " & "),
        )
      vars <- c("project", "table", "permission", "name", "ds_function")
      labelvar <- c(
        name = "Safe People",
        project = "Safe Project",
        table = "Safe Data",
        ds_function = "DataSHIELD Function",
        permission = "Access Level"
      )
    } else {
      overview_agg <- overview_tbl |>
        dplyr::group_by(project, table, name) |>
        dplyr::reframe(
          permission = paste0(unique(permission), collapse = " & "),
        )
      vars <- c("project", "table", "permission", "name")
      labelvar <- c(
        name = "Safe People",
        project = "Safe Project",
        table = "Safe Data",
        permission = "Access Level"
      )
    }
  } else {
    overview_agg <- overview_tbl
    vars <- c("name", "project", "table")
    labelvar <- c(
      name = "Safe People",
      project = "Safe Project",
      table = "Safe Data"
    )
  }

  ## generate diagram
  diagram_lst <- overview_agg |>
    vtree::vtree(
      vars = vars,
      labelvar = labelvar,
      showpct = FALSE,
      showcount = FALSE,
      horiz = FALSE,
      varnamebold = TRUE,
      splitwidth = 1,
      vsplitwidth = 1,
      folder = dirname(filepath),
      # imageFileOnly = render,
      pngknit = render,
      # pxheight = min(80 * nrow(overview_tbl), 500),
      # pxwidth = 200 * nrow(overview_tbl),
      prune = list(ds_function = "")
    )

  ## if `render = TRUE`, then render diagram as PNG
  diagram_filepath <- NULL
  ### estimate number of nodes
  dot <- diagram_lst$x$diagram
  nodes <- dot |>
    gregexpr(pattern = "Node_[A-Za-z0-9_]+", perl = TRUE) |>
    (\(.) regmatches(dot, .))() |>
    unlist() |>
    unique()
  num_nodes <- length(nodes)
  ### scale width/height based on nodes
  scale_factor <- 0.5 # inches per node
  width <- max(12, num_nodes * scale_factor)
  height <- max(6, num_nodes * scale_factor)
  if (render) {
    diagram_filepath <- diagram_lst |>
      vtree::grVizToImageFile(
        folder = dirname(filepath),
        filename = gsub("md$", "png", basename(filepath))
      )
  }

  # # find path to latest PNG generated with `vtree`
  # diagram_filepath <- list.files(dirname(filepath), "^vtree")
  # diagram_filepath <- diagram_filepath[length(diagram_filepath)]

  ## append overview table
  ### create tidy version of the overview table
  #### check if `overview_tbl` has `permission` field
  if ("permission" %in% colnames(overview_tbl)) {
    if ("ds_function" %in% colnames(overview_tbl)) {
      tidy_overview_tbl <- overview_tbl |>
        dplyr::distinct(
          project,
          table,
          permission,
          name,
          ds_function,
          timestamp
        ) |>
        dplyr::group_by(project, table, name) |>
        dplyr::reframe(
          permission = paste0(unique(permission), collapse = " & "),
          ds_function = ds_function,
          timestamp = timestamp,
          .groups = "drop"
        ) |>
        # dplyr::group_by(project, table, name, permission, ds_function) |>
        # dplyr::reframe(
        #   timestamp = paste0(timestamp, collapse = "<br>"),
        #   .groups = "drop"
        # ) |>
        # tidy up duplicated values in `project` and `table`
        dplyr::mutate(
          project = unfill_vec(project),
          table = unfill_vec(table)
        ) |>
        dplyr::select(
          `Safe Project` = project,
          `Safe Data` = table,
          `Access Level` = permission,
          `Safe People` = name,
          `DataSHIELD Function` = ds_function,
          `Timestamp` = timestamp
        ) |>
        dplyr::distinct()
    } else {
      tidy_overview_tbl <- overview_tbl |>
        dplyr::select(project, table, name, permission) |>
        dplyr::group_by(project, table, name) |>
        dplyr::reframe(
          permission = paste0(unique(permission), collapse = " & ")
        ) |>
        # tidy up duplicated values in `project` and `table`
        dplyr::mutate(
          project = unfill_vec(project),
          table = unfill_vec(table)
        ) |>
        dplyr::select(
          `Safe Project` = project,
          `Safe Data` = table,
          `Access Level` = permission,
          `Safe People` = name
        )
    }
  } else {
    tidy_overview_tbl <- overview_tbl |>
      # tidy up duplicated values in `name` and `project`
      dplyr::mutate(
        name = unfill_vec(name),
        project = unfill_vec(project)
      ) |>
      dplyr::select(
        `Safe Project` = project,
        `Safe Data` = table,
        `Safe People` = name
      )
  }
  report_contents <- c(
    report_contents,
    paste0(
      "> This report contains details for ",
      length(unique(overview_tbl$name)),
      " user",
      ifelse(length(unique(overview_tbl$name)) > 1, "s", ""),
      " and ",
      length(unique(overview_tbl$project)),
      " project",
      ifelse(length(unique(overview_tbl$project)) > 1, "s", ""),
      ". In addition, the tables they have access to within",
      ifelse(length(unique(overview_tbl$project)) > 1, " a ", " the "),
      "project.\n\n"
    ),
    "## Overview\n\n",
    "<div style=\"margin:0;\">\n\n",
    paste0(
      "<img src='",
      diagram_filepath,
      "' style='display:block; margin:0;' />\n<br />\n"
    ),
    "</div>\n\n",
    tidy_overview_tbl |>
      dplyr::distinct() |>
      knitr::kable() |>
      paste0(collapse = "\n")
  )

  report_contents <- c(report_contents, "\n<hr />\n", "## Entities")

  ## append Safe People details
  report_contents <- c(
    report_contents,
    "\n### Safe People\n",
    flatten_safe_people(safe_people_rocrate) |>
      knitr::kable() |>
      paste0(collapse = "\n")
  )

  ## append Safe Project & Safe Data details
  report_contents <- c(
    report_contents,
    "### Safe Project\n",
    flatten_safe_project(safe_project_rocrate) |>
      knitr::kable() |>
      paste0(collapse = "\n")
  )

  ## append Safe Data details
  report_contents <- c(
    report_contents,
    "### Safe Data\n",
    flatten_safe_data(safe_data_rocrate) |>
      knitr::kable() |>
      paste0(collapse = "\n")
  )

  ## append Safe Data permissions
  #### check if `overview_tbl` has `permission` field
  if ("permission" %in% colnames(overview_tbl)) {
    report_contents <- c(
      report_contents,
      "#### Safe Data permissions\n",
      flatten_user_perm_entity(user_perm_entity_lst) |>
        dplyr::select(-actionStatus, -description) |>
        knitr::kable() |>
        paste0(collapse = "\n")
    )
  }

  ## append Safe Settings details
  report_contents <- c(
    report_contents,
    "### Safe Settings\n",
    flatten_safe_setting(safe_setting_rocrate) |>
      knitr::kable() |>
      paste0(collapse = "\n")
  )

  report_contents <- c(report_contents, "\n<hr />\n")

  ## append input RO-Crate
  # save the input into intermediate JSON file
  tmp_file <- tempfile(fileext = ".json")
  # delete temporary file
  on.exit(unlink(tmp_file, recursive = TRUE, force = TRUE))
  # store RO-Crate in JSON format
  jsonlite::write_json(x, path = tmp_file, pretty = TRUE, auto_unbox = TRUE)
  # load formatted RO-Crate as text
  rocrate_txt <- readLines(tmp_file)
  report_contents <- c(
    report_contents,
    "## RO-Crate \n<code><pre>",
    # display formatted RO-Crate
    rocrate_txt,
    "</pre></code>"
  )

  ## write contents inside file
  ### delete previous version
  if (overwrite) {
    unlink(filepath, recursive = TRUE, force = TRUE)
  }
  writeLines(report_contents, filepath)

  ## render document
  if (render) {
    suppressWarnings({
      rmarkdown::render(
        filepath,
        "html_document",
        sub(".md", ".html", filepath)
      )
      utils::browseURL(paste0("file://", sub(".md", ".html", filepath)))
    })
  } else {
    print(diagram_lst)
    return(invisible(
      list(
        overview_diagram = diagram_lst,
        overview_data = tidy_overview_tbl,
        safe_people = flatten_safe_people(safe_people_rocrate),
        safe_data = flatten_safe_data(safe_data_rocrate),
        safe_data_permissions = flatten_user_perm_entity(user_perm_entity_lst),
        safe_project = flatten_safe_project(safe_project_rocrate),
        safe_setting = flatten_safe_setting(safe_setting_rocrate)
      )
    ))
  }

  message("A report has been written to:\n ", filepath)

  # return list of data frames with Safe People, Data Projects
  invisible(
    list(
      safe_people = flatten_safe_people(safe_people_rocrate),
      safe_data = flatten_safe_data(safe_data_rocrate),
      safe_data_permissions = flatten_user_perm_entity(user_perm_entity_lst),
      safe_project = flatten_safe_project(safe_project_rocrate),
      safe_setting = flatten_safe_setting(safe_setting_rocrate)
    )
  )
}
