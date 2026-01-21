#' Login to a MOLGENIS' Armadillo server
#'
#' Login to a MOLGENIS' Armadillo server. Wrapper for the function
#' [DSMolgenisArmadillo::armadillo.get_credentials()].
#'
#' @inheritParams DSMolgenisArmadillo::armadillo.get_credentials
#'
#' @returns MOLGENIS' Armadillo connection object.
#' @export
armadillo_login <- function(server) {
  conn <- DSMolgenisArmadillo::armadillo.get_credentials(server)
  # attr(conn, which = "class") <- structure("armadillo", "ArmadilloCredentials"),
  #   package = "DSMolgenisArmadillo"
  # )
  # class(conn) <- c("armadillo")
  attr(conn, "server") <- server
  return(invisible(conn))
}
