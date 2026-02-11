skip_on_cran()
skip_if_offline()

opal_demo_con <- function() {
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

  attr(opal_con, "USERNAME") <- USERNAME
  attr(opal_con, "USERPASS") <- USERPASS
  attr(opal_con, "SERVER") <- SERVER
  attr(opal_con, "DSUSERPASS") <- DSUSERPASS
  attr(opal_con, "PEOPLE") <- PEOPLE
  attr(opal_con, "PROJECT") <- PROJECT
  attr(opal_con, "TABLES") <- TABLES

  return(opal_con)
}
