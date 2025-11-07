## Opal server access
USERNAME <- "administrator"
USERPASS <- "password"
SERVER <- "https://opal-demo.obiba.org"

## Five safes variables
PEOPLE <- "dsuser"
PROJECT <- "CNSIM"
TABLES <- c("CNSIM1")

# login to local server with `USERNAME` and `USERPASS`.
opal_con <- opalr::opal.login(
  username = USERNAME,
  password = USERPASS,
  url = SERVER
)
