s3_method_not_available <- function(generic, class = NULL, hint = NULL) {
  msg <- sprintf("No `%s()` method exists", generic)
  if (!is.null(class)) {
    class <- paste(class, collapse = ", ")
    msg <- sprintf("%s for objects of class: %s", msg, class)
  }
  msg <- paste0(msg, "!")
  if (!is.null(hint)) {
    msg <- paste(msg, hint, sep = "\n")
  }
  stop(msg, call. = FALSE)
}

s3_method_not_implemented <- function(generic, backend = NULL, class = NULL) {
  msg <- sprintf("`%s()` for the", generic)
  if (!is.null(backend)) {
    msg <- sprintf("%s %s backend", msg, backend)
  } else if (!is.null(class)) {
    msg <- sprintf("%s %s class", msg, class)
  }
  stop(paste(msg, "is not currently implemented!"), call. = FALSE)
}
