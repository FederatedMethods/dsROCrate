#' Construct a safe_call
#'
#' @keywords internal
new_safe_call <- function(
  original,
  package,
  namespace,
  fx,
  args,
  expr = NULL
) {
  stopifnot(is.character(original))
  stopifnot(is.character(fx))
  stopifnot(is.list(args))

  structure(
    list(
      original = original,
      package = package,
      namespace = namespace,
      fx = fx,
      args = args,
      expr = expr
    ),
    class = "safe_call"
  )
}

safe_call <- function(call) {
  UseMethod("safe_call")
}

#' @export
safe_call.character <- function(call) {
  expr <- str2lang(call)
  safe_call(expr)
}

#' @export
safe_call.call <- function(call) {
  parsed <- parse_call(call)

  do.call(new_safe_call, parsed)
}
