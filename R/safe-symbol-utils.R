find_symbols <- function(expr) {
  if (is.character(expr)) {
    expr <- parse(text = expr)[[1]]
  }

  recurse <- function(x) {
    if (is.symbol(x)) {
      return(list(list(
        symbol = as.character(x),
        column = NA_character_
      )))
    }

    if (!is.call(x)) {
      return(list())
    }

    if (identical(x[[1]], quote(`$`))) {
      lhs <- x[[2]]
      out <- list(list(
        symbol = as.character(lhs),
        column = as.character(x[[3]])
      ))

      return(out)
    }

    unlist(
      lapply(as.list(x)[-1], recurse),
      recursive = FALSE
    )
  }

  refs <- recurse(expr)
  refs <- Filter(\(x) !(x$symbol %in% c("base", "stats", "utils")), refs)
  if (!length(refs)) {
    return(NULL)
  }
  refs
}

find_symbol_asset <- function(symbol_id, registry) {
  sym <- registry$symbols |>
    dplyr::filter(id == symbol_id)

  if (!nrow(sym)) {
    return(NA_character_)
  }

  if (sym$kind == "table") {
    return(sym$asset)
  }

  deps <- resolve_dependencies(sym$expr, registry)

  if (!nrow(deps)) {
    return(NA_character_)
  }

  assets <- purrr::map_chr(
    deps$symbol_id,
    find_symbol_asset,
    registry = registry
  )

  unique(stats::na.omit(assets))
}

resolve_dependencies <- function(expr, registry, visited = character()) {
  if (is.null(expr) || is.na(expr)) {
    return(tibble::tibble())
  }

  refs <- find_symbols(expr)

  if (is.null(refs)) {
    return(tibble::tibble())
  }

  deps <- purrr::map_dfr(refs, tibble::as_tibble) |>
    dplyr::left_join(
      registry$symbols |>
        dplyr::select(symbol_id = id, symbol, kind, asset, expr),
      by = "symbol"
    )

  deps <- deps |>
    dplyr::mutate(
      parents = purrr::map(
        symbol_id,
        function(symbol_id) {
          if (is.na(symbol_id) || symbol_id %in% visited) {
            return(tibble::tibble())
          }

          sym <- registry$symbols |>
            dplyr::filter(id == symbol_id)

          if (!nrow(sym) || sym$kind != "expression") {
            return(tibble::tibble())
          }

          resolve_dependencies(
            expr = sym$expr,
            registry = registry,
            visited = c(visited, symbol_id)
          )
        }
      )
    )

  deps
}
