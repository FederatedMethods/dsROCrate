find_symbols <- function(expr) {
  if (is.character(expr)) {
    expr <- parse(text = expr)[[1]]
  }

  refs <- list()
  recurse <- function(x) {
    if (is.call(x)) {
      ## A$B
      if (identical(x[[1]], quote(`$`))) {
        refs[[length(refs) + 1]] <<- list(
          symbol = as.character(x[[2]]),
          column = as.character(x[[3]])
        )
      }
      lapply(as.list(x)[-1], recurse)
    }
  }
  recurse(expr)

  if (length(refs) == 0) {
    return(NULL)
  }
  refs
}
