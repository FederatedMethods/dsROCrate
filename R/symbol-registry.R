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
  stopifnot(inherits(symbol, "safe_symbol"))

  # append dependent symbols
  symbol$depends_on <-
    resolve_dependencies(symbol$expr, registry)

  registry$symbols <- dplyr::bind_rows(
    registry$symbols,
    tibble::as_tibble(symbol)
  )

  # existing <- registry$symbols[[symbol$symbol]]
  #
  # registry$symbols[[symbol$symbol]] <- existing

  registry
}

# resolve_symbol.symbol_registry <- function(
resolve_symbol <- function(
  registry,
  symbol,
  timestamp,
  session = NULL,
  user = NULL
) {
  # current <- lookup_symbol(registry, symbol)
  #
  # while (
  #   !is.null(current) && is.null(current$asset) && !is.null(current$parent)
  # ) {
  #   current <- lookup_symbol(registry, current$parent)
  # }
  #
  # current
  x <- registry$symbols |>
    dplyr::filter(symbol == !!symbol, created_at <= !!timestamp)

  if (!is.null(session)) {
    x <- dplyr::filter(x, session == !!session)
  }

  if (!is.null(user)) {
    x <- dplyr::filter(x, user == !!user)
  }

  if (nrow(x) == 0) {
    return(NULL)
  }

  x |>
    dplyr::slice_max(created_at, n = 1)
}

symbol_registry <- function() {
  new_symbol_registry()
}
