new_safe_symbol <- function(
  symbol,
  id = paste0("symbol-", uuid::UUIDgenerate()),
  kind = "unknown",
  asset = NULL,
  expr = expr,
  parents = NULL,
  created_by = NULL,
  created_at = NULL,
  user = NULL,
  session = NULL,
  action = NULL,
  metadata = list()
) {
  stopifnot(is.character(symbol))
  stopifnot(length(symbol) == 1)

  structure(
    list(
      symbol = symbol,
      id = id,
      kind = kind,
      asset = asset,
      expr = expr,
      parents = parents,
      created_by = created_by,
      created_at = created_at,
      user = user,
      session = session,
      action = action,
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

symbol_parents <- function(x, ...) {
  UseMethod("symbol_parents")
}

#' @export
symbol_parents.safe_symbol <- function(x, ...) {
  x$parents
}


symbol_session <- function(x, ...) {
  UseMethod("symbol_session")
}

#' @export
symbol_session.safe_symbol <- function(x, ...) {
  x$session
}
