#' @export
as.data.frame.safe_call <- function(x, ...) {
  data.frame(
    package = x$package,
    fx = x$fx,
    argument = names(x$args),
    value = vapply(x$args, toString, character(1)),
    stringsAsFactors = FALSE
  )
}

call_args <- function(x, ...) {
  UseMethod("call_args")
}

#' @export
call_args.safe_call <- function(x, ...) {
  x$args
}

call_fx <- function(x, ...) {
  UseMethod("call_fx")
}

#' @export
call_fx.safe_call <- function(x, ...) {
  x$fx
}

call_original <- function(x, ...) {
  UseMethod("call_original")
}

#' @export
call_original.safe_call <- function(x, ...) {
  x$original
}

call_package <- function(x, ...) {
  UseMethod("call_package")
}

#' @export
call_package.safe_call <- function(x, ...) {
  x$package
}

enrich_argument <- function(arg, registry, timestamp, session) {
  if (!is.character(arg) || length(arg) != 1) {
    return(arg)
  }

  symbol <- resolve_symbol(
    registry,
    symbol = arg,
    timestamp = timestamp,
    session = session
  )

  if (is.null(symbol)) {
    return(arg)
  }

  safe_reference(
    symbol = symbol$symbol,
    symbol_id = symbol$id
  )
}

enrich_call <- function(call, registry) {
  # call$args <- lapply(call$args, resolve_argument, registry = registry)
  call$args <- purrr::map(
    call$args,
    enrich_argument,
    registry = registry,
    timestamp = call$created_at,
    session = call$session
  )

  call
}

get_function <- function(info) {
  if (is.null(info$package)) {
    return(get(info$fx, mode = "function"))
  }

  get(info$fx, envir = asNamespace(info$package), mode = "function")
}

parse_arguments <- function(fx_call, info, expand.dots = FALSE) {
  supplied <- as.list(fx_call[-1])
  supplied_names <- names(supplied)

  # Recover function object
  fun_obj <- get_function(info)

  # Expand names
  matched <- match.call(
    definition = fun_obj,
    call = fx_call,
    expand.dots = expand.dots
  )

  matched <- as.list(matched[-1])

  # Evaluate constants only
  matched <- lapply(matched, simplify_argument)

  matched
}

parse_call <- function(fx_call) {
  fx <- fx_call[[1]]

  # package + function
  info <- parse_function(fx)

  # arguments
  args <- parse_arguments(fx_call, info)

  list(
    original = paste(deparse(fx_call), collapse = ""),
    package = info$package,
    namespace = info$namespace,
    fx = info$fx,
    args = args
  )
}

parse_function <- function(fx) {
  if (is.call(fx) && identical(fx[[1]], as.name("::"))) {
    return(
      list(
        package = as.character(fx[[2]]),
        namespace = "::",
        fx = as.character(fx[[3]])
      )
    )
  }

  list(
    package = NULL,
    namespace = NULL,
    fx = as.character(fx)
  )
}

resolve_argument <- function(registry, x) {
  if (!is.character(x) || length(x) != 1) {
    return(x)
  }

  # exact symbol
  if (has_symbol(registry, x)) {
    return(lookup_symbol(registry, x))
  }

  # symbol$column
  if (grepl("\\$", x)) {
    pieces <- strsplit(x, "\\$", fixed = FALSE)[[1]]

    if (has_symbol(registry, pieces[1])) {
      sym <- lookup_symbol(registry, pieces[1])
      sym$column <- pieces[2]
      return(sym)
    }
  }
  x
}

simplify_argument <- function(x) {
  if (is.atomic(x) || is.character(x)) {
    return(x)
  }

  if (is.name(x)) {
    return(as.character(x))
  }

  if (is.call(x)) {
    return(paste(deparse(x), collapse = ""))
  }

  x
}
