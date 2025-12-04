#' Unfill vector
#'
#' @param x Input vector.
#' @param val Default value.
#'
#' @returns Unfilled vector.
#' @keywords internal
#' @source https://github.com/tidyverse/tidyr/issues/250#issuecomment-344984802
unfill_vec <- function(x, val = "") {
  same <- x == dplyr::lag(x)
  ifelse(!is.na(same) & same, val, x)
}
