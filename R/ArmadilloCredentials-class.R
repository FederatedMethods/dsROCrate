# define virtual S4 class `armadillo`
setClass("armadillo", contains = "VIRTUAL")

# declare inheritance from existing class
setIs("ArmadilloCredentials", "armadillo")
# setIs("DSMolgenisArmadillo::ArmadilloCredentials", "armadillo")

# # define S4 class `ArmadilloCredentials`
# setClass(
#   "ArmadilloCredentials",
#   contains = "armadillo",
#   slots = list(
#     access_token = "character",
#     id_token = "character",
#     refresh_token = "character",
#     token_type = "character",
#     auth_type = "character",
#     expires_in = "integer",
#     expires_at = "POSIXct"
#   )
# )
