## Opal server access
USERNAME <- "administrator"
USERPASS <- "password"
SERVER <- "https://opal-demo.obiba.org"
## Credentials for `dsuser`
### NOTE: this is only used to simulate an analysis and generate logs
DSUSERPASS <- "P@ssw0rd"

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
