exclude_args <- function(..., excluded) {
  # capture additional args
  args <- list(...)
  arg_names <- names(args)
  # exclude args that shouldn't be passed to the next function
  args[!(arg_names %in% excluded)]
}
