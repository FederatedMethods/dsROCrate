#' @export
print.cr8tor_bundle <- function(x, ...) {
  cat("<cr8tor_bundle>\n")

  is_valid_roc <- function(x) {
    inherits(x$rocrate, "rocrate") &&
      rocrateR::is_rocrate(x$rocrate, error = FALSE)
  }

  if (is_valid_roc(x)) {
    cat("\U2714 Valid RO-Crate\n")
  } else {
    cat("\U2716 Invalid RO-Crate\n")
  }

  # resources <- unique(basename(x$resources))
  # if (length(resources) > 0) {
  #   cat("Resources: ", paste0(resources, collapse = ", "), "\n")
  # }
  # if (length(x$errors)) {
  #   cat("\nErrors:\n")
  #   cat(paste0(" - ", x$errors, collapse = "\n"), "\n")
  # }
  #
  # if (length(x$warnings)) {
  #   cat("\nWarnings:\n")
  #   cat(paste0(" - ", x$warnings, collapse = "\n"), "\n")
  # }

  invisible(x)
}
