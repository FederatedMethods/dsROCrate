#' @export
as.data.frame.symbol_registry <- function(x, ...) {
  do.call(
    rbind,
    lapply(
      x$symbols,
      function(sym) {
        data.frame(
          symbol = sym$symbol,
          kind = sym$kind,
          asset = sym$asset,
          parent = sym$parent,
          column = sym$column,
          stringsAsFactors = FALSE
        )
      }
    )
  )
}

has_symbol <- function(registry, name) {
  UseMethod("has_symbol")
}

#' @export
has_symbol.symbol_registry <- function(registry, name) {
  name %in% names(registry$symbols)
}

new_symbol_registry <- function(symbols = list()) {
  structure(
    list(
      symbols = symbols
    ),
    class = "symbol_registry"
  )
}

lookup_symbol <- function(registry, name) {
  UseMethod("lookup_symbol")
}

#' @export
lookup_symbol.symbol_registry <- function(registry, name) {
  registry$symbols[[name]]
}

register_symbol <- function(registry, symbol) {
  UseMethod("register_symbol")
}

#' @export
register_symbol.symbol_registry <- function(registry, symbol) {
  registry$symbols[[symbol$symbol]] <- symbol
  registry
}

resolve_symbol.symbol_registry <- function(registry, symbol) {
  current <- lookup_symbol(registry, symbol)

  while (
    !is.null(current) && is.null(current$asset) && !is.null(current$parent)
  ) {
    current <- lookup_symbol(registry, current$parent)
  }

  current
}

symbol_registry <- function() {
  new_symbol_registry()
}

update_symbol <- function(registry, symbol, ...) {
  # TO BE REVIEWED!!!!
  registry$symbols[[symbol$symbol]] <- NULL
  registry
}
