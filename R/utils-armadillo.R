.require_armadillo <- function(package) {
  if (!requireNamespace(package, quietly = TRUE)) {
    stop(
      sprintf("Package '%s' is required for the Armadillo backend. ", package),
      "Please install it first.",
      call. = FALSE
    )
  }

  invisible(TRUE)
}

#' Login to a MOLGENIS' Armadillo server
#'
#' Login to a MOLGENIS' Armadillo server. Wrapper for the function
#' [DSMolgenisArmadillo::armadillo.get_credentials()].
#'
#' @inheritParams DSMolgenisArmadillo::armadillo.get_credentials
#'
#' @returns MOLGENIS' Armadillo connection object.
#' @export
#'
#' @examples
#' \dontrun{
#' armadillo_login("https://armadillo-playground.molgenis.net/")
#' }
armadillo_login <- function(server) {
  .require_armadillo("DSMolgenisArmadillo")
  .require_armadillo("MolgenisArmadillo")

  conn <- DSMolgenisArmadillo::armadillo.get_credentials(server)

  ns <- loadNamespace("MolgenisArmadillo")
  pkgenv <- get(".pkgglobalenv", envir = ns)

  assign("armadillo_url", server, envir = pkgenv)
  assign("auth_token", getElement(conn, "access_token"), envir = pkgenv)

  invisible(conn)
}
