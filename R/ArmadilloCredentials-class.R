# define S4 class `ArmadilloCredentials`
setClass(
  "ArmadilloCredentials",
  slots = list(
    access_token = "character",
    id_token = "character",
    refresh_token = "character",
    token_type = "character",
    auth_type = "character",
    expires_in = "integer",
    expires_at = "POSIXct"
  )
)
