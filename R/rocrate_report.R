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

#' @param filepath String with file path for Markdown report with the summary
#'     of the given object, `x`.
#' @param render Boolean flag to indicate whether to render the markdown report.
#' @param overwrite Boolean flag to indicate whether to overwrite a previous
#'     version of markdown report.
#' @rdname rocrate_report
#' @export
rocrate_report.rocrate <- function(
  x,
  ...,
  filepath = tempfile(fileext = ".md"),
  render = TRUE,
  overwrite = FALSE
) {
  # local bindings
  id <- name <- project <- NULL

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

  # attempt to extract safe people details
  safe_people_rocrate <- tryCatch(
    {
      extract_safe_people(x)
    },
    error = function(e) {
      NULL
    }
  )

  # attempt to extract safe data details
  safe_data_rocrate <- tryCatch(
    {
      extract_safe_data(x)
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

  # attempt to extract safe project details
  safe_project_rocrate <- tryCatch(
    {
      extract_safe_project(x, id = member_of)
    },
    error = function(e) {
      NULL
    }
  )

  # create Markdown report
  report_contents <- paste0(
    "# DataSHIELD Report\n",
    "##### Last Updated: ",
    Sys.time(),
    "\n"
  )

  ## create visualisation for the overview
  overview_tbl <- flatten_safe_people(safe_people_rocrate) |>
    dplyr::select(-id) |>
    dplyr::bind_cols(
      flatten_safe_project(safe_project_rocrate) |>
        dplyr::select(-id)
    )
  diagram_lst <- overview_tbl |>
    vtree::vtree(
      vars = c("name", "project", "table"),
      labelvar = c(
        name = "Safe People",
        project = "Safe Project",
        table = "Safe Data"
      ),
      showpct = FALSE,
      showcount = FALSE,
      horiz = FALSE,
      varnamebold = TRUE,
      splitwidth = 1,
      vsplitwidth = 1,
      folder = dirname(filepath),
      imageFileOnly = render,
      pngknit = render,
      pxheight = min(80 * nrow(overview_tbl), 500),
      pxwidth = 200 * nrow(overview_tbl) # 200px * numbers of safe data entities
    )
  # find path to latest PNG generated with `vtree`
  diagram_filepath <- list.files(dirname(filepath), "^vtree")
  diagram_filepath <- diagram_filepath[length(diagram_filepath)]

  ## append overview table
  ### create tidy version of the overview table
  tidy_overview_tbl <- overview_tbl |>
    # tidy up duplicated values in `name` and `project`
    dplyr::mutate(
      name = unfill_vec(name),
      project = unfill_vec(project)
    ) |>
    dplyr::rename(
      `Safe People` = name,
      `Safe Project` = project,
      `Safe Data` = table
    )
  report_contents <- c(
    report_contents,
    "## Overview\n\n",
    paste0("![](", diagram_filepath, ")\n<br />\n"),
    tidy_overview_tbl |>
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
        safe_project = flatten_safe_project(safe_project_rocrate)
      )
    ))
  }

  message("A report has been written to:\n ", filepath)

  # return list of data frames with Safe People, Data Projects
  invisible(
    list(
      safe_people = flatten_safe_people(safe_people_rocrate),
      safe_data = flatten_safe_data(safe_data_rocrate),
      safe_project = flatten_safe_project(safe_project_rocrate)
    )
  )
}
