#' @include ArmadilloCredentials-class.R
NULL

setMethod(
  "show",
  "ArmadilloCredentials",
  function(object) {
    expiration_timestamp <- object@expires_at
    is_expired <- Sys.time() > expiration_timestamp
    cat("<ArmadilloCredentials>\n")
    if (is_expired) {
      cat("  Connection expired!\n")
      cat("\nYou must login again:\n")
      cat("  `dsROCrate::armadillo_login(SERVER)`\n")
    } else {
      cat("  auth type: ", object@auth_type, "\n", sep = "")
      cat("  token type:", object@token_type, "\n")
      cat("  expires at:", format(object@expires_at, tz = "UTC"), "\n")
    }
  }
)
