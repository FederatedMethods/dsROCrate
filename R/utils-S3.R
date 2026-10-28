s3_method_not_available <- function(generic, backend = NULL, class = NULL) {
  msg <- sprintf("No `%s()` method exists", generic)
  if (!is.null(backend)) {
    msg <- sprintf("%s for the %s backend", msg, backend)
  } else if (!is.null(class)) {
    class <- paste(class(x), collapse = ", ")
    msg <- sprintf("%s for objects of class: %s", msg, class)
  }
  stop(paste0(msg, "!"), call. = FALSE)
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
