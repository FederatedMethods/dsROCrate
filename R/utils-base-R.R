#' Wrapper for binary operator OR
#'
#' Wrapper for binary operator OR (only introduced in R v4.4)
#'
#' @param x Left hand side object
#' @param y Right hand side object (default if `x` missing)
#'
#' @returns `x` if not missing, `y` otherwise.
#' @keywords internal
#'
#' @noRd
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}
