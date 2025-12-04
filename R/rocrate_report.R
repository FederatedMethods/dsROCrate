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
    "# DataSHIELD Report\n\n",
    "##### Created: ",
    Sys.Date(),
    "\n\n"
  )

  ## append overview table
  report_contents <- c(
    report_contents,
    "## Overview\n\n",
    flatten_safe_people(safe_people_rocrate) |>
      dplyr::select(-id) |>
      dplyr::bind_cols(
        flatten_safe_project(safe_project_rocrate) |>
          dplyr::select(-id)
      ) |>
      # dplyr::group_by(name) |>
      # dplyr::mutate(name = rep(unique(name), times = dplyr::n())) |>
      # dplyr::group_by(project) |>
      # dplyr::mutate(
      #   project = rep(unique(project), times = dplyr::n())
      # ) |>
      dplyr::rename(
        `Safe People` = name,
        `Safe Project` = project,
        `Safe Data` = table
      ) |>
      knitr::kable() |>
      paste0(collapse = "\n")
  )

  report_contents <- c(report_contents, "\n<br />\n---\n<br />\n")

  ## append Safe People details
  report_contents <- c(
    report_contents,
    "## Safe People\n\n",
    flatten_safe_people(safe_people_rocrate) |>
      knitr::kable() |>
      paste0(collapse = "\n"),
    "\n\n"
  )

  ## append Safe Project & Safe Data details
  report_contents <- c(
    report_contents,
    "## Safe Project\n\n",
    flatten_safe_project(safe_project_rocrate) |>
      knitr::kable() |>
      paste0(collapse = "\n"),
    "\n\n"
  )

  ## append Safe Data details
  report_contents <- c(
    report_contents,
    "## Safe Data\n\n",
    flatten_safe_data(safe_data_rocrate) |>
      knitr::kable() |>
      paste0(collapse = "\n"),
    "\n\n"
  )

  report_contents <- c(report_contents, "\n<br />\n---\n<br />\n")

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
    "## RO-Crate \n\n",
    # display formatted RO-Crate
    rocrate_txt |>
      paste0(collapse = "\n")
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
      browseURL(paste0("file://", sub(".md", ".html", filepath)))
    })
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
