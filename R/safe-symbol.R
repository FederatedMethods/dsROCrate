new_safe_symbol <- function(
  symbol,
  kind = "unknown",
  asset = NULL,
  column = NULL,
  parent = NULL,
  created_by = NULL,
  created_at = NULL,
  metadata = list()
) {
  stopifnot(is.character(symbol))
  stopifnot(length(symbol) == 1)

  structure(
    list(
      symbol = symbol,
      kind = kind,
      asset = asset,
      column = column,
      parent = parent,
      created_by = created_by,
      created_at = created_at,
      metadata = metadata
    ),
    class = "safe_symbol"
  )
}

safe_symbol <- function(symbol, ...) {
  new_safe_symbol(symbol = symbol, ...)
}

symbol <- function(x, ...) {
  UseMethod("symbol")
}

#' @export
symbol.safe_symbol <- function(x, ...) {
  x$symbol
}


symbol_asset <- function(x, ...) {
  UseMethod("symbol_asset")
}

#' @export
symbol_asset.safe_symbol <- function(x, ...) {
  x$asset
}

symbol_column <- function(x, ...) {
  UseMethod("symbol_column")
}

#' @export
symbol_column.safe_symbol <- function(x, ...) {
  x$column
}

symbol_kind <- function(x, ...) {
  UseMethod("symbol_kind")
}

#' @export
symbol_kind.safe_symbol <- function(x, ...) {
  x$kind
}

symbol_metadata <- function(x, ...) {
  UseMethod("symbol_metadata")
}

#' @export
symbol_metadata.safe_symbol <- function(x, ...) {
  x$metadata
}

symbol_parent <- function(x, ...) {
  UseMethod("symbol_parent")
}

#' @export
symbol_parent.safe_symbol <- function(x, ...) {
  x$parent
}
