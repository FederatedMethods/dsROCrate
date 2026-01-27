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

#' @param study_name String with the study name.
#' @rdname rocrate_report
#' @export
rocrate_report.list <- function(
  x,
  ...,
  study_name,
  title = "DataSHIELD Report",
  filepath = tempfile(fileext = ".md"),
  render = TRUE,
  doc_format = "html",
  overwrite = FALSE,
  include_user_perm = TRUE,
  diag_width = NULL,
  diag_height = NULL
) {
  # validate that all the objects in the list, `x`, are valid RO-Crates
  sapply(x, rocrateR::is_rocrate)

  # generate individual reports for each RO-Crate
  report_outputs <- lapply(
    x,
    rocrate_report,
    title = title,
    filepath = filepath,
    render = FALSE,
    doc_format = doc_format,
    overwrite = TRUE,
    include_user_perm = include_user_perm,
    diag_width = diag_width,
    diag_height = diag_height
  )

  # Combine reports ----
  ## Safe People -----
  safe_people_all <- tryCatch(
    {
      report_outputs |>
        # extract each component per server
        lapply(getElement, name = "safe_people") |>
        # attach the server name as a new column
        purrr::imap(~ dplyr::mutate(.x, server = .y)) |>
        # combine rows
        dplyr::bind_rows()
    },
    error = function(e) {
      NULL
    }
  )
  ## Safe Data ----
  safe_data_all <- tryCatch(
    {
      report_outputs |>
        # extract each component per server
        lapply(getElement, name = "safe_data") |>
        # attach the server name as a new column
        purrr::imap(~ dplyr::mutate(.x, server = .y)) |>
        # combine rows
        dplyr::bind_rows()
    },
    error = function(e) {
      NULL
    }
  )
  ## Safe Projects ----
  safe_project_all <- tryCatch(
    {
      report_outputs |>
        # extract each component per server
        lapply(getElement, name = "safe_project") |>
        # attach the server name as a new column
        purrr::imap(~ dplyr::mutate(.x, server = .y)) |>
        # combine rows
        dplyr::bind_rows()
    },
    error = function(e) {
      NULL
    }
  )
  ## Safe Settings ----
  safe_setting_all <- tryCatch(
    {
      report_outputs |>
        # extract each component per server
        lapply(getElement, name = "safe_setting") |>
        # attach the server name as a new column
        purrr::imap(~ dplyr::mutate(.x, server = .y)) |>
        # combine rows
        dplyr::bind_rows()
    },
    error = function(e) {
      NULL
    }
  )
  ## Safe Data permissions (optional) ----
  safe_data_permissions_all <- tryCatch(
    {
      report_outputs |>
        # extract each component per server
        lapply(getElement, name = "safe_data_permissions") |>
        # attach the server name as a new column
        purrr::imap(~ dplyr::mutate(.x, server = .y)) |>
        # combine rows
        dplyr::bind_rows()
    },
    error = function(e) {
      NULL
    }
  )
  ## combine aggregated data to generate new overview table
  safe_project_data_all <- safe_project_all |>
    dplyr::rename(project_id = id) |>
    dplyr::left_join(
      safe_data_all |>
        dplyr::rename(table_id = id),
      by = c("table" = "name", "server" = "server")
    )
  # if data permissions were found, then combine with project-data details and
  # generate new overview table
  if (!is.null(safe_data_permissions_all)) {
    overview_data_all <- safe_data_permissions_all |>
      dplyr::left_join(
        safe_people_all |>
          dplyr::rename(user_id = id),
        by = c("user_id", "server")
      ) |>
      dplyr::left_join(safe_project_data_all, by = c("table_id", "server")) |>
      dplyr::select(
        server,
        project,
        table,
        permission,
        user = name
      )
  } else {
    # extract previous overview table
    overview_data_all <- tryCatch(
      {
        report_outputs |>
          # extract each component per server
          lapply(getElement, name = "overview_data") |>
          # attach the server name as a new column
          purrr::imap(~ dplyr::mutate(.x, server = .y)) |>
          # combine rows
          dplyr::bind_rows()
      },
      error = function(e) {
        NULL
      }
    )
  }

  # return combined outputs
  # TODO

  # PLACEHOLDER OUTPUT
  return(report_outputs)
}

#' @param title String with title for the report (default: 'DataSHIELD Report').
#' @param filepath String with file path for Markdown report with the summary
#'     of the given object, `x`.
#' @param render Boolean flag to indicate whether to render the markdown report.
#' @param doc_format String with file format for the markdown report.
#' @param overwrite Boolean flag to indicate whether to overwrite a previous
#'     version of markdown report.
#' @param include_user_perm Boolean flag to indicate whether to include user
#'     permissions in the report overview's diagram.
#' @param diag_title String with title for the 'root' of the diagram (default:
#'     'DataSHIELD server').
#' @param diag_width Numeric value with width (in inches) for the report
#'     overview's diagram (default: `NULL`, estimated based on number of nodes).
#' @param diag_height Numeric value with height (in inches) for the report
#'     overview's diagram (default: `NULL`, estimated based on number of nodes).
#' @rdname rocrate_report
#' @export
rocrate_report.rocrate <- function(
  x,
  ...,
  title = "DataSHIELD Report",
  filepath = tempfile(fileext = ".md"),
  render = TRUE,
  doc_format = "html",
  overwrite = FALSE,
  include_user_perm = TRUE,
  diag_title = "DataSHIELD server",
  diag_width = NULL,
  diag_height = NULL
) {
  # local bindings
  id <- name <- project <- table_id <- table_name <- username <- user_id <- NULL
  actionStatus <- description <- ds_function <- ds_table <- type <- NULL
  encodingFormat <- permission <- timestamp <- NULL

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
  ## initialise markdown header (see https://rmarkdown.rstudio.com/lesson-9.html)
  report_contents <- paste0(
    "---\n",
    paste0("title: ", title),
    "\noutput:\n",
    "  pdf_document:\n",
    "    df_print: kable\n",
    "    highlight: tango\n",
    "  html_document: default\n",
    "fontsize: 11pt\n",
    "geometry:\n",
    "  - margin=.5in\n",
    "  - landscape\n",
    "header-includes: \n",
    "  - \\usepackage{array}\n",
    "  - \\usepackage{longtable}\n",
    "  - \\usepackage{xurl}\n",
    "  - \\usepackage{hyphenat}\n",
    "  - \\usepackage{microtype}\n",
    "  - \\sloppy\n",
    "  - \\setlength{\\emergencystretch}{3em}\n",
    "  - \\usepackage{float}\n",
    "  - \\usepackage{titling}\n",
    "  - \\setlength{\\droptitle}{-1.5cm}\n",
    paste0("date: ", format(Sys.time(), '%Y-%m-%d %H:%M:%S')),
    "\n---\n"
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
        name = "People",
        project = "Project",
        table = "Data",
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
        name = "People",
        project = "Project",
        table = "Data",
        permission = "Access Level"
      )
    }
  } else {
    overview_agg <- overview_tbl
    vars <- c("name", "project", "table")
    labelvar <- c(
      name = "People",
      project = "Project",
      table = "Data"
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
      title = diag_title,
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
  if (is.null(diag_width)) {
    width <- max(12, num_nodes * scale_factor)
  } else {
    width <- diag_width
  }
  if (is.null(diag_height)) {
    height <- max(6, num_nodes * scale_factor)
  } else {
    height <- diag_height
  }
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
        # tidy up duplicated values in `project` and `table`
        dplyr::mutate(
          project = unfill_vec(project),
          table = unfill_vec(table)
        ) |>
        dplyr::select(
          `Project` = project,
          `Data` = table,
          `Access Level` = permission,
          `People` = name,
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
          `Project` = project,
          `Data` = table,
          `Access Level` = permission,
          `People` = name
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
        `Project` = project,
        `Data` = table,
        `People` = name
      )
  }
  report_contents <- c(
    report_contents,
    paste0(
      "This report contains details for ",
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
    "<div style=\"margin:0;\">\n",
    # "::: {style=\"text-align: center;\"}\n",
    "<!-- PDF-only -->\n",
    "```{=latex}\n",
    paste0(
      "\\begin{figure}[H]\n",
      "\\centering\n",
      "\\includegraphics[height=0.75\\textheight, keepaspectratio, width=0.9\\textwidth]{",
      diagram_filepath,
      "}",
      "\\caption{RO-Crate Overview}\n",
      "\\end{figure}\n```\n"
    ),
    "<!-- HTML-only -->",
    "```{=html}\n",
    paste0(
      "<img src=\"",
      diagram_filepath,
      "\" alt=\"RO-Crate Overview\" ",
      "style=\"display:block; margin-left:auto; margin-right:auto;\" />\n"
    ),
    "```\n</div>\n\n\\newpage",
    tidy_overview_tbl |>
      dplyr::distinct() |>
      knitr::kable() |>
      paste0(collapse = "\n")
  )

  report_contents <- c(report_contents, "\n<hr />\n", "## Entities")

  ## append Safe People details
  report_contents <- c(
    report_contents,
    "\n### People\n",
    flatten_safe_people(safe_people_rocrate) |>
      knitr::kable() |>
      paste0(collapse = "\n")
  )

  ## append Safe Project & Safe Data details
  report_contents <- c(
    report_contents,
    "### Project(s)\n",
    flatten_safe_project(safe_project_rocrate) |>
      knitr::kable() |>
      paste0(collapse = "\n")
  )

  ## append Safe Data details
  report_contents <- c(
    report_contents,
    "### Data\n",
    flatten_safe_data(safe_data_rocrate) |>
      knitr::kable() |>
      paste0(collapse = "\n")
  )

  ## append Safe Data permissions
  #### check if `overview_tbl` has `permission` field
  if ("permission" %in% colnames(overview_tbl)) {
    report_contents <- c(
      report_contents,
      "#### Data permissions\n",
      flatten_user_perm_entity(user_perm_entity_lst) |>
        dplyr::select(-actionStatus, -description, -permission) |>
        knitr::kable() |>
        paste0(collapse = "\n")
    )
  }

  ## append Safe Settings details
  report_contents <- c(
    report_contents,
    "### Settings\n",
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
    "\n\\newpage\n",
    "## RO-Crate \n```json",
    # display formatted RO-Crate
    rocrate_txt,
    "\n```"
  )

  ## write contents inside file
  ### delete previous version
  if (overwrite) {
    unlink(filepath, recursive = TRUE, force = TRUE)
  }
  writeLines(report_contents, filepath)

  ## render document
  if (render) {
    if (tolower(doc_format) %in% c("html", "html_document")) {
      suppressWarnings({
        rmarkdown::render(
          filepath,
          "html_document",
          sub(".md", ".html", filepath)
        )
        utils::browseURL(paste0("file://", sub(".md", ".html", filepath)))
      })
    } else if (tolower(doc_format) %in% c("pdf", "pdf_document")) {
      suppressWarnings({
        rmarkdown::render(
          filepath,
          "pdf_document",
          sub(".md", ".pdf", filepath)
        )
        utils::browseURL(paste0("file://", sub(".md", ".pdf", filepath)))
      })
    } else {
      stop("The format `", doc_format, "` is not valid! Try 'html' or 'pdf'.")
    }
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
