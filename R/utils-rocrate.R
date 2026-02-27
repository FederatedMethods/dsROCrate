#' Load `content` from external files
#'
#' @param rocrate Object with the [rocrate][rocrateR::rocrate()] class.
#' @param roc_path String with path to the root of the RO-Crate.
#'
#' @returns Update `rocrate` object.
#' @keywords internal
load_content <- function(rocrate, roc_path) {
  # get 'File' entities with missing `content` (if any)
  file_ents <- rocrate |>
    rocrateR::get_entity(type = "File") |>
    Filter(f = function(x) is.null(getElement(x, "content")))
  ## attempt loading contents, if any entities were found
  for (ent in file_ents) {
    # attempt loading the contents from the filenames given by `@id`
    content <- tryCatch(
      {
        if (getElement(ent, "encodingFormat") == "text/csv") {
          utils::read.csv(file.path(roc_path, getElement(ent, "@id")))
        } else {
          readLines(file.path(roc_path, getElement(ent, "@id")))
        }
      },
      error = function(e) {
        NULL
      },
      warning = function(e) {
        NULL
      }
    )

    # update entity within the RO-Crate
    if (!is.null(content)) {
      rocrate <- rocrate |>
        rocrateR::add_entity_value(
          id = getElement(ent, "@id"),
          key = "content",
          value = list(content)
        )
    }
  }

  return(rocrate)
}

#' Load RO-Crate from file
#'
#' @param x String with path to RO-Crate
#'
#' @returns RO-Crate object.
#' @keywords internal
load_rocrate <- function(x) {
  # check if the given file, `x`, exists
  if (!file.exists(x)) {
    stop("The given file:\n  `", x, "`\nis not a valid path!", call. = FALSE)
  }

  # initialise local variables
  roc_path <- rocrate <- NULL

  # check if the given path points to an RO-Crate bag (zip file)
  if (grepl("zip$", tolower(x))) {
    # create temp directory to extract contents of RO-Crate
    tempdir_name <- file.path(tempdir(), digest::digest(Sys.time()))
    dir.create(tempdir_name, recursive = TRUE)
    on.exit(unlink(tempdir_name, force = TRUE, recursive = TRUE))

    # unbag RO-Crate
    roc_path <- tryCatch(
      {
        rocrateR::unbag_rocrate(x, output = tempdir_name, quiet = TRUE)
      },
      error = function(e) {
        x
      }
    )
  } else {
    roc_path <- x
  }

  # load RO-Crate
  rocrate <- tryCatch(
    {
      # list JSON files, if roc_path points to a directory
      if (dir.exists(roc_path)) {
        roc_path_files <- list.files(
          roc_path,
          pattern = "[json|JSON]$",
          recursive = TRUE,
          full.names = TRUE
        )
        roc_path_files <- roc_path_files[1]
        roc_path <- dirname(roc_path_files)
      } else {
        roc_path_files <- roc_path
        roc_path <- dirname(roc_path)
      }
      rocrateR::read_rocrate(roc_path_files)
    },
    error = function(e) {
      NULL
    }
  )

  # check if the RO-Crate was loaded correctly
  if (is.null(rocrate)) {
    stop("Unable to load an RO-Crate from the given file:\n  `", x, "`")
  }

  # check if any of the entities with `@type = 'File'` have empty `content`
  rocrate <- rocrate |>
    load_content(roc_path = roc_path)
}
