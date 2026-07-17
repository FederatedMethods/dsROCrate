#' @export
as.data.frame.safe_symbol <- function(x, ...) {
  data.frame(
    id = x$id,
    symbol = x$symbol,
    kind = x$kind,
    asset = x$asset,
    expr = x$expr,
    # parents = x$parents,
    created_by = x$created_by,
    created_at = x$created_at,
    user = x$user,
    session = x$session,
    action = x$action,
    # metadata = x$metadata,
    stringsAsFactors = FALSE
  )
}

new_safe_symbol <- function(
  symbol,
  kind = "unknown",
  asset = NA_character_,
  expr = NA_character_,
  parents = list(),
  created_by = NA_character_,
  created_at = Sys.time(),
  user = NA_character_,
  session = NA_character_,
  action = NA_character_,
  metadata = list(),
  id = paste0("symbol-", uuid::UUIDgenerate())
) {
  stopifnot(is.character(symbol))
  stopifnot(length(symbol) == 1)

  structure(
    list(
      id = id,
      symbol = symbol,
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
