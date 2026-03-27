
<!-- README.md is generated from README.Rmd. Please edit that file -->

# dsROCrate: ‘DataSHIELD’ RO-Crate Governance Functions <img src="man/figures/logo.png" alt="logo" align="right" height="200" style="float:right; height:200px;"/>

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/dsROCrate)](https://CRAN.R-project.org/package=dsROCrate)
[![Codecov test
coverage](https://codecov.io/gh/FederatedMethods/dsROCrate/graph/badge.svg)](https://app.codecov.io/gh/FederatedMethods/dsROCrate)
<!-- badges: end -->

The goal of dsROCrate is to provide functions to wrap elements from a
‘DataSHIELD’ analysis into an RO-Crate.

## 1. Installation

You can install the development version of dsROCrate from
[GitHub](https://github.com/FederatedMethods/dsROCrate/) with:

``` r
# install.packages("pak")
pak::pak("FederatedMethods/dsROCrate")
```

## 2. Creating your first RO-Crate

In this example, we will be using OBiBa’s
[Opal](https://opaldoc.obiba.org/en/latest/index.html) as the *back-end*
for DataSHIELD. Another option would be MOLGENIS’
[Armadillo](https://github.com/molgenis/molgenis-service-armadillo/).

### 2.1. Connect to an Opal Server

#### Setup

For instructions on how to set up a local server for DataSHIELD, see the
following vignette:

``` r
vignette("deploy-local-datashield-server-with-opal")
```

Here we will use OBiBa’s Opal demo server:
<https://opal-demo.obiba.org/> which can be accessed with the following
login credentials:

``` r
# define global variables
## Opal server access
USERNAME <- "administrator"
USERPASS <- "password"
SERVER <- "https://opal-demo.obiba.org"
## Credentials for `dsuser`
### NOTE: this is only used to simulate an analysis and generate logs
DSUSERPASS <- "P@ssw0rd"
```

Next, define global variables used in generating the RO-Crate, such as
project name, table references (within the project) and user
identifiers.

``` r
## Five safes variables
PEOPLE <- "dsuser"
PROJECT <- "CNSIM"
TABLES <- c("CNSIM1")
```

#### Open connection

Once the credentials and Five Safes variables are configured,we can
start a new session on the opal server with the following command:

``` r
# login to local server with `USERNAME` and `USERPASS`.
o <- opalr::opal.login(
  username = USERNAME,
  password = USERPASS,
  url = SERVER
)

print(o)
#> url: https://opal-demo.obiba.org 
#> name: opal-demo.obiba.org 
#> version: 5.6.1 
#> username: administrator
```

### 2.2. Create a basic RO-Crate

To create a basic RO-Crate, we will use the
[`{rocrateR}`](https://github.com/ResearchObject/ro-crate-r) package.
This package can be installed with the following command:

``` r
# install.packages("pak")
pak::pak("rocrateR")
```

Then, a basic RO-Crate can be created with the following command:

``` r
basic_rocrate <- rocrateR::rocrate_5s()
```

Note that this RO-Crate uses the
[5s-crate](https://trefx.uk/5s-crate/0.4/) profile.

``` r
print(basic_rocrate)
#> {
#>   "@context": "https://w3id.org/ro/crate/1.2/context",
#>   "@graph": [
#>     {
#>       "@id": "ro-crate-metadata.json",
#>       "@type": "CreativeWork",
#>       "about": {
#>         "@id": "./"
#>       },
#>       "conformsTo": {
#>         "@id": "https://w3id.org/ro/crate/1.2"
#>       }
#>     },
#>     {
#>       "@id": "./",
#>       "@type": "Dataset",
#>       "name": "",
#>       "description": "",
#>       "datePublished": "2026-03-27",
#>       "license": {
#>         "@id": "http://spdx.org/licenses/CC-BY-4.0"
#>       },
#>       "conformsTo": {
#>         "@id": "https://w3id.org/5s-crate/0.4"
#>       }
#>     },
#>     {
#>       "@id": "https://w3id.org/5s-crate/0.4",
#>       "@type": ["CreativeWork", "Profile"],
#>       "name": "Five Safes RO-Crate profile"
#>     }
#>   ]
#> }
```

### 2.3. Add the *Five Safes* Elements

#### Safe Data

To add details for Safe Data, use the function `dsROCrate::safe_data()`.

``` r
basic_rocrate <- o |>
  dsROCrate::safe_data(rocrate = basic_rocrate,
                       project = PROJECT,
                       tables = TABLES)

print(basic_rocrate) # note that the output will be truncated
...
#>     {
#>       "@id": "#perm:9bf7f75b6c5b07d02830b95652cd39a0-dict-summary-read",
#>       "@type": "ReadAction",
#>       "agent": {
#>         "@id": "#person:a0af2a94926db1b49ad7a812eef509d2"
#>       },
#>       "object": {
#>         "@id": "#asset:fad6faf661584d53e58f9730b14c5aae"
#>       },
#>       "actionStatus": "PotentialActionStatus",
#>       "description": "User may view table dictionary and summary statistics only; access to individual values is restricted."
#>     },
#>     {
#>       "@id": "#perm:1f09051d217d17c3e9b5ed92819ded26-admin-table",
#>       "@type": "ControlAction",
#>       "agent": {
#>         "@id": "#person:a3bc19cc9c1269320cf2847c63a66a92"
#>       },
#>       "object": {
#>         "@id": "#asset:fad6faf661584d53e58f9730b14c5aae"
#>       },
#>       "actionStatus": "PotentialActionStatus",
#>       "description": "User has full administrative rights: view/edit dictionary and view/edit individual values."
#>     },
#>     {
#>       "@id": "#perm:4d2673da68a58c3bce23a61d97b6df51-dict-summary-read",
#>       "@type": "ReadAction",
#>       "agent": {
#>         "@id": "#person:cb809df1c2fb30b154f60b843e62b3d0"
#>       },
#>       "object": {
#>         "@id": "#asset:fad6faf661584d53e58f9730b14c5aae"
#>       },
#>       "actionStatus": "PotentialActionStatus",
#>       "description": "User may view table dictionary and summary statistics only; access to individual values is restricted."
#>     },
#>     {
#>       "@id": "#asset:fad6faf661584d53e58f9730b14c5aae",
#>       "@type": "Dataset",
#>       "name": "CNSIM1",
#>       "description": "",
#>       "url": "/datasource/CNSIM/table/CNSIM1",
#>       "dateCreated": "2026-03-27T00:00:00Z",
#>       "dateModified": "2026-03-27T00:00:00Z",
#>       "isPartOf": {
#>         "@id": "#project:7ba189863f9f641196596cb28e04aa14"
#>       }
#>     }
#>   ]
#> }
```

#### Safe Project

To add details for Safe Project, use the function
`dsROCrate::safe_project()`.

``` r
basic_rocrate <- o |>
  dsROCrate::safe_project(rocrate = basic_rocrate,
                          project = PROJECT)

print(basic_rocrate) # note that the output will be truncated
...
#>       ]
#>     },
#>     {
#>       "@id": "#project:7ba189863f9f641196596cb28e04aa14",
#>       "@type": "Project",
#>       "name": "CNSIM",
#>       "dateCreated": "2026-03-27T06:29:56.149Z",
#>       "dateModified": "2026-03-27T06:30:01.340Z",
#>       "hasPart": [
#>         {
#>           "@id": "#asset:fad6faf661584d53e58f9730b14c5aae"
#>         }
#>       ]
#>     }
#>   ]
#> }
```

#### Safe People

To add details for Safe People, use the function
`dsROCrate::safe_people()`.

``` r
basic_rocrate <- o |>
  dsROCrate::safe_people(rocrate = basic_rocrate, user = PEOPLE)

print(basic_rocrate) # note that the output will be truncated
...
#>     {
#>       "@id": "#person:a0af2a94926db1b49ad7a812eef509d2",
#>       "@type": "Person",
#>       "name": "dsuser"
#>     }
#>   ]
#> }
```

#### Safe Setting

To add details for Safe Setting, use the function
`dsROCrate::safe_setting()`.

**⚠️NOTE:** The `dsROCrate::safe_setting` function requires
administrator privileges, so here, we will have to log in with
administrator credentials (if you used a non-administrator account
previously).

``` r
# close previous connection
opalr::opal.logout(o)

# open new connection as administrator
o <- opalr::opal.login(
  username = "administrator",
  password = "password",
  url = SERVER
)
```

Then, we can proceed as per usual:

``` r
basic_rocrate <- o |>
  dsROCrate::safe_setting(rocrate = basic_rocrate)

print(basic_rocrate) # note that the output will be truncated
...
#>     {
#>       "@id": "#disc:27d8c1d2233ecb654a24b635fd4dbd78",
#>       "@type": "PropertyValue",
#>       "name": "datashield.privacyLevel",
#>       "value": "5"
#>     },
#>     {
#>       "@id": "#disc:46b65707a6b998f3b1364bc10e6d9b4b",
#>       "@type": "PropertyValue",
#>       "name": "default.datashield.privacyControlLevel",
#>       "value": "banana"
#>     },
#>     {
#>       "@id": "#disc:7769282e7b0a1cb8887f60886c7b56ae",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.glm",
#>       "value": "0.33"
#>     },
#>     {
#>       "@id": "#disc:49d822f52075aafbec1d1b2545aa46b7",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.kNN",
#>       "value": "3"
#>     },
#>     {
#>       "@id": "#disc:9a59210a743557bbd61cb21c3f1e0a79",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.levels.density",
#>       "value": "0.33"
#>     },
#>     {
#>       "@id": "#disc:a00b1e31a448142ee66bbb013f990e1f",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.levels.max",
#>       "value": "40"
#>     },
#>     {
#>       "@id": "#disc:29dd5e27a9f1c66d81a7037c236e7dd5",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.noise",
#>       "value": "0.25"
#>     },
#>     {
#>       "@id": "#disc:1c12e549b91e2cc0856f56657988ce54",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.string",
#>       "value": "80"
#>     },
#>     {
#>       "@id": "#disc:786bc0ffcdd3054925e431240caecea5",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.stringShort",
#>       "value": "20"
#>     },
#>     {
#>       "@id": "#disc:fd9bea5ef311d5f14b28d237ecb6e985",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.subset",
#>       "value": "3"
#>     },
#>     {
#>       "@id": "#disc:4e93a50cbd8cfea8f0a6adc50ee7aac0",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.tab",
#>       "value": "3"
#>     },
#>     {
#>       "@id": "#env:disclosure_settings:7d746edc2fb36ee671241a333742b3a8",
#>       "@type": "CreativeWork",
#>       "name": "Disclosure Control Environment",
#>       "description": "Disclosure control settings extract from the OBiBa Opal server connection provided, using the profile: 'default'.",
#>       "hasPart": [
#>         {
#>           "@id": "#disc:27d8c1d2233ecb654a24b635fd4dbd78"
#>         },
#>         {
#>           "@id": "#disc:46b65707a6b998f3b1364bc10e6d9b4b"
#>         },
#>         {
#>           "@id": "#disc:7769282e7b0a1cb8887f60886c7b56ae"
#>         },
#>         {
#>           "@id": "#disc:49d822f52075aafbec1d1b2545aa46b7"
#>         },
#>         {
#>           "@id": "#disc:9a59210a743557bbd61cb21c3f1e0a79"
#>         },
#>         {
#>           "@id": "#disc:a00b1e31a448142ee66bbb013f990e1f"
#>         },
#>         {
#>           "@id": "#disc:29dd5e27a9f1c66d81a7037c236e7dd5"
#>         },
#>         {
#>           "@id": "#disc:1c12e549b91e2cc0856f56657988ce54"
#>         },
#>         {
#>           "@id": "#disc:786bc0ffcdd3054925e431240caecea5"
#>         },
#>         {
#>           "@id": "#disc:fd9bea5ef311d5f14b28d237ecb6e985"
#>         },
#>         {
#>           "@id": "#disc:4e93a50cbd8cfea8f0a6adc50ee7aac0"
#>         }
#>       ]
#>     },
#>     {
#>       "@id": "#software:f8784d80bad08f840fba23fa9c41ec27",
#>       "@type": "SoftwareApplication",
#>       "name": "dsBase",
#>       "version": "6.3.5",
#>       "description": "Base 'DataSHIELD' functions for the server side. 'DataSHIELD' is a software package which allows you to do non-disclosive federated analysis on sensitive data. 'DataSHIELD' analytic functions have been designed to only share non disclosive summary statistics, with built in automated output checking based on statistical disclosure control. With data sites setting the threshold values for the automated output checks. For more details, see 'citation(\"dsBase\")'."
#>     },
#>     {
#>       "@id": "#software:afa897ee58de14b27570462c97a9dd44",
#>       "@type": "SoftwareApplication",
#>       "name": "dsTidyverse",
#>       "version": "1.1.0",
#>       "description": "Implementation of selected 'Tidyverse' functions within 'DataSHIELD', an open-source federated analysis solution in R. Currently, DataSHIELD contains very limited tools for data manipulation, so the aim of this package is to improve the researcher experience by implementing essential functions for data manipulation, including subsetting, filtering, grouping, and renaming variables. This is the serverside package which should be installed on the server holding the data, and is used in conjuncture with the clientside package 'dsTidyverseClient' which is installed in the local R environment of the analyst. For more information, see <https://tidyverse.org/> and <https://datashield.org/>."
#>     },
#>     {
#>       "@id": "#software:d2133fef4ca6df6312f205e51aee541b",
#>       "@type": "SoftwareApplication",
#>       "name": "resourcer",
#>       "version": "1.5.0",
#>       "description": "A resource represents some data or a computation unit. It is described by a URL and credentials. This package proposes a Resource model with \"resolver\" and \"client\" classes to facilitate the access and the usage of the resources."
#>     },
#>     {
#>       "@id": "#software:77514b155cfdb0c8c535fbe54daf67fc",
#>       "@type": "SoftwareApplication",
#>       "name": "Opal",
#>       "version": "5.6.1",
#>       "description": "Opal is OBiBa's (https://www.obiba.org/) core database application for epidemiological studies. Participant data, collected by questionnaires, medical instruments, sensors, administrative databases etc. can be integrated and stored in a central data repository under a uniform model."
#>     },
#>     {
#>       "@id": "#env:software_stack:239d65ed3c0c0c3932e23cebb34be7e1",
#>       "@type": "CreativeWork",
#>       "name": "Approved Analytical Software Environment",
#>       "description": "Software packages installed in the controlled Opal/DataSHIELD environment used for federated analysis.",
#>       "hasPart": [
#>         {
#>           "@id": "#software:f8784d80bad08f840fba23fa9c41ec27"
#>         },
#>         {
#>           "@id": "#software:afa897ee58de14b27570462c97a9dd44"
#>         },
#>         {
#>           "@id": "#software:d2133fef4ca6df6312f205e51aee541b"
#>         },
#>         {
#>           "@id": "#software:77514b155cfdb0c8c535fbe54daf67fc"
#>         }
#>       ]
#>     },
#>     {
#>       "@id": "#control:output-checking",
#>       "@type": "CreativeWork",
#>       "name": "Statistical Disclosure Output Checking",
#>       "description": "Automated disclosure control prevents release of small-cell counts and disclosive statistics."
#>     },
#>     {
#>       "@id": "#control:server-side-analysis",
#>       "@type": "CreativeWork",
#>       "name": "Server-Side Analysis Enforcement",
#>       "description": "Raw data never leaves the secure server; analysis occurs via vetted aggregate functions."
#>     },
#>     {
#>       "@id": "#control:session-logging",
#>       "@type": "CreativeWork",
#>       "name": "Comprehensive Session Logging",
#>       "description": "All analytical actions are logged and auditable."
#>     },
#>     {
#>       "@id": "#control:secure-facility",
#>       "@type": "CreativeWork",
#>       "name": "Secure Data Facility",
#>       "description": "Access restricted to approved secure premises."
#>     },
#>     {
#>       "@id": "#control:access-governance",
#>       "@type": "CreativeWork",
#>       "name": "Access Governance Process",
#>       "description": "Data access committee review and approval required."
#>     },
#>     {
#>       "@id": "#safesetting:8489860e7540c5dfb95b5d8ddab232c5",
#>       "@type": "CreativeWork",
#>       "name": "Safe Setting Controls (Opal)",
#>       "description": "Technical, physical and organisational safeguards applied to minimise disclosure risk.",
#>       "hasPart": [
#>         {
#>           "@id": "#env:disclosure_settings:7d746edc2fb36ee671241a333742b3a8"
#>         },
#>         {
#>           "@id": "#env:software_stack:239d65ed3c0c0c3932e23cebb34be7e1"
#>         },
#>         {
#>           "@id": "#control:output-checking"
#>         },
#>         {
#>           "@id": "#control:server-side-analysis"
#>         },
#>         {
#>           "@id": "#control:session-logging"
#>         },
#>         {
#>           "@id": "#control:secure-facility"
#>         },
#>         {
#>           "@id": "#control:access-governance"
#>         }
#>       ]
#>     },
#>     {
#>       "@id": "#link:b16fbdedcc33e826878020dcd5fad3d3",
#>       "@type": "CreativeWork",
#>       "name": "Safe Settings x Safe Project Link",
#>       "about": {
#>         "@id": "#safesetting:8489860e7540c5dfb95b5d8ddab232c5"
#>       },
#>       "isPartOf": {
#>         "@id": "#project:7ba189863f9f641196596cb28e04aa14"
#>       }
#>     }
#>   ]
#> }
```

#### Safe Outputs

To add details for Safe Outputs, use the function
`dsROCrate::safe_output()`. Currently, only log files from the
operations executed by the user within a specific period. Set the period
using `logs_from` and `logs_to`. Additionally, a list of functions
executed by the user are extracted in a separate file/entity.

**⚠️NOTE:** Similar to `dsROCrate::safe_setting`, the
`dsROCrate::safe_output` function requires of administrator rights, so
here, we will have to log in with administrator credentials:

``` r
# close previous connection
opalr::opal.logout(o)

# open new connection as administrator
o <- opalr::opal.login(
  username = "administrator",
  password = "password",
  url = SERVER
)
```

------------------------------------------------------------------------

##### DataSHIELD operations

**⚠️NOTE:** Before extracting logs, ensure there is recent activity on
the server for testing purposes. This can be done using the following
commands:

###### Setup

You will need the following packages:

``` r
pak::pak("DSI")
pak::pak("DSOpal")
pak::pak("dsBaseClient")
```

###### Open connection

``` r
# run some test commands with dsBaseClient
## needed to defined the OpalDriver class in the current environment
DSOpal::Opal()
#> An object of class "OpalDriver"
#> <S4 Type Object>
## create new login object, note that here we use the `dsuser`
builder <- DSI::newDSLoginBuilder()
builder$append(server = "study1",
               url = SERVER,
               user = "dsuser",
               password = DSUSERPASS,
               driver = "OpalDriver")
logindata <- builder$build()
conns <- DSI::datashield.login(logins = logindata)
#> 
#> Logging into the collaborating servers
```

###### Simulate some operations

``` r
## assign data
DSI::datashield.assign.table(conns["study1"], 
                             symbol = "dsROCrate_test",
                             table = paste0(PROJECT, ".", TABLES[1]),
                             errors.print = TRUE)

dsBaseClient::ds.ls(datasources = conns["study1"])
#> $study1
#> $study1$environment.searched
#> [1] "R_GlobalEnv"
#> 
#> $study1$objects.found
#> [1] "dsROCrate_test"
dsBaseClient::ds.summary("dsROCrate_test")
#> $study1
#> $study1$class
#> [1] "data.frame"
#> 
#> $study1$`number of rows`
#> [1] 2163
#> 
#> $study1$`number of columns`
#> [1] 11
#> 
#> $study1$`variables held`
#>  [1] "LAB_TSC"            "LAB_TRIG"           "LAB_HDL"           
#>  [4] "LAB_GLUC_ADJUSTED"  "PM_BMI_CONTINUOUS"  "DIS_CVA"           
#>  [7] "MEDI_LPD"           "DIS_DIAB"           "DIS_AMI"           
#> [10] "GENDER"             "PM_BMI_CATEGORICAL"
```

------------------------------------------------------------------------

Then, we can proceed as per usual:

``` r
basic_rocrate <- o |>
  dsROCrate::safe_output(rocrate = basic_rocrate,
                         logs_from = Sys.time() - 60, # capture the last minute
                         logs_to = Sys.time())
#> opening file input connection.
#>  Found 55 records... Imported 55 records. Simplifying...
#> closing file input connection.
#> Warning: A `path` wasn't provided! The logs will be included in the RO-Crate
#> object, under the `content` tag!
```

``` r
print(basic_rocrate) # note that the output will be truncated
...
#>       },
#>       "isPartOf": {
#>         "@id": "#project:7ba189863f9f641196596cb28e04aa14"
#>       }
#>     },
#>     {
#>       "@id": "20260327T120002-dslogs-dsuser.log",
#>       "@type": "File",
#>       "dateModified": "2026-03-27 12:00:02",
#>       "name": "20260327T120002-dslogs-dsuser.log",
#>       "description": "This file contains the raw logs for the user: `dsuser` , between: 2026-03-27 11:59:01 and 2026-03-27 12:00:01",
#>       "encodingFormat": "text/plain",
#>       "content": [
#>         ["[INFO][2026-03-27T11:59:57][OPEN]      created a datashield session 84b50a64-e51e-4d54-a155-bd3ebbdbcdf8", "[INFO][2026-03-27T11:59:59][ASSIGN]    created symbol 'dsROCrate_test' from: 'dsROCrate_test <- opal[CNSIM.CNSIM1]'", "[INFO][2026-03-27T12:00:00][PARSE]     parsed 'dsBase::lsDS(search.filter = NULL, 1L)'", "[INFO][2026-03-27T12:00:01][AGGREGATE] evaluated 'dsBase::lsDS(search.filter = NULL, 1L)'", "[INFO][2026-03-27T12:00:01][PARSE]     parsed 'base::exists(\"dsROCrate_test\")'", "[INFO][2026-03-27T12:00:01][AGGREGATE] evaluated 'base::exists(\"dsROCrate_test\")'", "[INFO][2026-03-27T12:00:01][PARSE]     parsed 'dsBase::classDS(\"dsROCrate_test\")'", "[INFO][2026-03-27T12:00:01][AGGREGATE] evaluated 'dsBase::classDS(\"dsROCrate_test\")'", "[INFO][2026-03-27T12:00:01][PARSE]     parsed 'dsBase::isValidDS(dsROCrate_test)'", "[INFO][2026-03-27T12:00:01][AGGREGATE] evaluated 'dsBase::isValidDS(dsROCrate_test)'", "[INFO][2026-03-27T12:00:01][PARSE]     parsed 'dsBase::dimDS(\"dsROCrate_test\")'", "[INFO][2026-03-27T12:00:01][AGGREGATE] evaluated 'dsBase::dimDS(\"dsROCrate_test\")'", "[INFO][2026-03-27T12:00:01][PARSE]     parsed 'dsBase::colnamesDS(\"dsROCrate_test\")'", "[INFO][2026-03-27T12:00:01][AGGREGATE] evaluated 'dsBase::colnamesDS(\"dsROCrate_test\")'"]
#>       ]
#>     },
#>     {
#>       "@id": "20260327T120002-dslogs-dsuser_mappings.csv",
#>       "@type": "File",
#>       "dateModified": "2026-03-27 12:00:02",
#>       "name": "20260327T120002-dslogs-dsuser_mappings.csv",
#>       "description": "This file contains mappings and evaluated functions",
#>       "encodingFormat": "text/csv",
#>       "content": [
#>         [
#>           {
#>             "timestamp": "2026-03-27T11:59:57",
#>             "action": "OPEN",
#>             "user": "dsuser",
#>             "r_cmd": "Open session: 84b50a64-e51e-4d54-a155-bd3ebbdbcdf8",
#>             "fx": "DSI::datashield.login",
#>             "session": "84b50a64-e51e-4d54-a155-bd3ebbdbcdf8",
#>             "backend": "OBiBa's Opal"
#>           },
#>           {
#>             "timestamp": "2026-03-27T11:59:59",
#>             "action": "ASSIGN",
#>             "user": "dsuser",
#>             "r_cmd": "dsROCrate_test <- opal[CNSIM.CNSIM1]",
#>             "fx": "base::assign",
#>             "table": "CNSIM.CNSIM1",
#>             "session": "84b50a64-e51e-4d54-a155-bd3ebbdbcdf8",
#>             "backend": "OBiBa's Opal"
#>           },
#>           {
#>             "timestamp": "2026-03-27T12:00:01",
#>             "action": "AGGREGATE",
#>             "user": "dsuser",
#>             "r_cmd": "dsBase::lsDS(search.filter = NULL, 1L)",
#>             "fx": "dsBase::lsDS",
#>             "symbol": "search.filter = NULL, 1L",
#>             "table": "CNSIM.CNSIM1",
#>             "session": "84b50a64-e51e-4d54-a155-bd3ebbdbcdf8",
#>             "backend": "OBiBa's Opal"
#>           },
#>           {
#>             "timestamp": "2026-03-27T12:00:01",
#>             "action": "AGGREGATE",
#>             "user": "dsuser",
#>             "r_cmd": "base::exists(\"dsROCrate_test\")",
#>             "fx": "base::exists",
#>             "symbol": "dsROCrate_test",
#>             "table": "CNSIM.CNSIM1",
#>             "session": "84b50a64-e51e-4d54-a155-bd3ebbdbcdf8",
#>             "backend": "OBiBa's Opal"
#>           },
#>           {
#>             "timestamp": "2026-03-27T12:00:01",
#>             "action": "AGGREGATE",
#>             "user": "dsuser",
#>             "r_cmd": "dsBase::classDS(\"dsROCrate_test\")",
#>             "fx": "dsBase::classDS",
#>             "symbol": "dsROCrate_test",
#>             "table": "CNSIM.CNSIM1",
#>             "session": "84b50a64-e51e-4d54-a155-bd3ebbdbcdf8",
#>             "backend": "OBiBa's Opal"
#>           },
#>           {
#>             "timestamp": "2026-03-27T12:00:01",
#>             "action": "AGGREGATE",
#>             "user": "dsuser",
#>             "r_cmd": "dsBase::isValidDS(dsROCrate_test)",
#>             "fx": "dsBase::isValidDS",
#>             "symbol": "dsROCrate_test",
#>             "table": "CNSIM.CNSIM1",
#>             "session": "84b50a64-e51e-4d54-a155-bd3ebbdbcdf8",
#>             "backend": "OBiBa's Opal"
#>           },
#>           {
#>             "timestamp": "2026-03-27T12:00:01",
#>             "action": "AGGREGATE",
#>             "user": "dsuser",
#>             "r_cmd": "dsBase::dimDS(\"dsROCrate_test\")",
#>             "fx": "dsBase::dimDS",
#>             "symbol": "dsROCrate_test",
#>             "table": "CNSIM.CNSIM1",
#>             "session": "84b50a64-e51e-4d54-a155-bd3ebbdbcdf8",
#>             "backend": "OBiBa's Opal"
#>           },
#>           {
#>             "timestamp": "2026-03-27T12:00:01",
#>             "action": "AGGREGATE",
#>             "user": "dsuser",
#>             "r_cmd": "dsBase::colnamesDS(\"dsROCrate_test\")",
#>             "fx": "dsBase::colnamesDS",
#>             "symbol": "dsROCrate_test",
#>             "table": "CNSIM.CNSIM1",
#>             "session": "84b50a64-e51e-4d54-a155-bd3ebbdbcdf8",
#>             "backend": "OBiBa's Opal"
#>           }
#>         ]
#>       ]
#>     }
#>   ]
#> }
```

### 2.4. Close connection

``` r
opalr::opal.logout(o)
```

### 2.5. Bag/Save RO-Crate

The resulting RO-Crate can be stored into an RO-Crate bag/archive with
the function `rocrateR::bag_rocrate`:

``` r
# create temp directory
dir.create("./rocrates", showWarnings = FALSE)
```

NOTE: In the above example, a `path` to store the logs wasn’t provided
when calling `dsROCrate::safe_output`, before creating an RO-Crate bag,
we should save the contents of this file first. In addition, the
contents for the entity with the list of functions executed:

``` r
logs_entity <- basic_rocrate |>
  rocrateR::get_entity(type = "File")
# write file using the path given by `@id`
## write raw logs
writeLines(
  logs_entity[[1]]$content[[1]], 
  file.path("./rocrates", logs_entity[[1]]$`@id`)
)
## write CSV with mappings and executed functions
write.csv(
  logs_entity[[2]]$content[[1]], 
  file.path("./rocrates", logs_entity[[2]]$`@id`),
  row.names = FALSE
)

# remove the section `content`
logs_entity[[1]]$content <- NULL
logs_entity[[2]]$content <- NULL
# update the RO-Crate
basic_rocrate <- basic_rocrate |>
  rocrateR::add_entity(logs_entity[[1]], overwrite = TRUE) |>
  rocrateR::add_entity(logs_entity[[2]], overwrite = TRUE)
```

``` r
# create RO-Crate bag
path_to_rocrate_bag <- basic_rocrate |>
  rocrateR::bag_rocrate(path = "./rocrates", overwrite = TRUE)
#> RO-Crate successfully 'bagged'!
#> For details, see: ./rocrates/rocrate-168d1073270b8b5ddb29de5fb1e8f745.zip
```

We can explore the contents with the following commands:

``` r
# extract files in temporary directory
path_to_rocrate_bag |>
  # extract contents inside ./rocrates/ROC
  rocrateR::unbag_rocrate(output = "./rocrates/ROC", quiet = TRUE) |>
  # create tree with the files
  fs::dir_tree()
#> /Users/robertovillegas-diaz/Documents/dsROCrate/rocrates/ROC
#> ├── bag-info.txt
#> ├── bagit.txt
#> ├── data
#> │   ├── 20260327T120002-dslogs-dsuser.log
#> │   ├── 20260327T120002-dslogs-dsuser_mappings.csv
#> │   └── ro-crate-metadata.json
#> ├── manifest-sha512.txt
#> └── tagmanifest-sha512.txt
```

### 2.6. Clean working directory

``` r
unlink("./rocrates", recursive = TRUE, force = TRUE)
```

<br />

## 3. Auditing RO-Crates and servers

### 3.1. Audit People

##### List accessible tables within a project for an user

``` r
safe_people_crate_v1 <- opalr::opal.login(
  username = USERNAME,
  password = USERPASS,
  url = SERVER
) |>
  dsROCrate::audit(user = "dsuser", project = "CNSIM")
#> opening file input connection.
#>  Found 55 records... Imported 55 records. Simplifying...
#> closing file input connection.

print(safe_people_crate_v1)
#> {
#>   "@context": "https://w3id.org/ro/crate/1.2/context",
#>   "@graph": [
#>     {
#>       "@id": "ro-crate-metadata.json",
#>       "@type": "CreativeWork",
#>       "about": {
#>         "@id": "./"
#>       },
#>       "conformsTo": {
#>         "@id": "https://w3id.org/ro/crate/1.2"
#>       }
#>     },
#>     {
#>       "@id": "./",
#>       "@type": "Dataset",
#>       "name": "",
#>       "description": "",
#>       "datePublished": "2026-03-27",
#>       "license": {
#>         "@id": "http://spdx.org/licenses/CC-BY-4.0"
#>       },
#>       "conformsTo": {
#>         "@id": "https://w3id.org/5s-crate/0.4"
#>       },
#>       "hasPart": [
#>         {
#>           "@id": "20260327T120003-dslogs-dsuser.log"
#>         },
#>         {
#>           "@id": "20260327T120003-dslogs-dsuser_mappings.csv"
#>         }
#>       ]
#>     },
#>     {
#>       "@id": "https://w3id.org/5s-crate/0.4",
#>       "@type": ["CreativeWork", "Profile"],
#>       "name": "Five Safes RO-Crate profile"
#>     },
#>     {
#>       "@id": "#person:a0af2a94926db1b49ad7a812eef509d2",
#>       "@type": "Person",
#>       "name": "dsuser"
#>     },
#>     {
#>       "@id": "#project:7ba189863f9f641196596cb28e04aa14",
#>       "@type": "Project",
#>       "name": "CNSIM",
#>       "dateCreated": "2026-03-27T06:29:56.149Z",
#>       "dateModified": "2026-03-27T06:30:01.340Z",
#>       "hasPart": [
#>         {
#>           "@id": "#asset:fad6faf661584d53e58f9730b14c5aae"
#>         },
#>         {
#>           "@id": "#asset:b6721026564c746f604df7ba785931fa"
#>         },
#>         {
#>           "@id": "#asset:14fbb8de0021e6d237a2ed7779f9625d"
#>         }
#>       ]
#>     },
#>     {
#>       "@id": "#perm:9bf7f75b6c5b07d02830b95652cd39a0-dict-summary-read",
#>       "@type": "ReadAction",
#>       "agent": {
#>         "@id": "#person:a0af2a94926db1b49ad7a812eef509d2"
#>       },
#>       "object": {
#>         "@id": "#asset:fad6faf661584d53e58f9730b14c5aae"
#>       },
#>       "actionStatus": "PotentialActionStatus",
#>       "description": "User may view table dictionary and summary statistics only; access to individual values is restricted."
#>     },
#>     {
#>       "@id": "#perm:363eb627d1e49c08933f2e26142e6d56-dict-summary-read",
#>       "@type": "ReadAction",
#>       "agent": {
#>         "@id": "#person:a0af2a94926db1b49ad7a812eef509d2"
#>       },
#>       "object": {
#>         "@id": "#asset:b6721026564c746f604df7ba785931fa"
#>       },
#>       "actionStatus": "PotentialActionStatus",
#>       "description": "User may view table dictionary and summary statistics only; access to individual values is restricted."
#>     },
#>     {
#>       "@id": "#perm:63b8097908f682bff1760e48d28c5855-dict-summary-read",
#>       "@type": "ReadAction",
#>       "agent": {
#>         "@id": "#person:a0af2a94926db1b49ad7a812eef509d2"
#>       },
#>       "object": {
#>         "@id": "#asset:14fbb8de0021e6d237a2ed7779f9625d"
#>       },
#>       "actionStatus": "PotentialActionStatus",
#>       "description": "User may view table dictionary and summary statistics only; access to individual values is restricted."
#>     },
#>     {
#>       "@id": "#asset:fad6faf661584d53e58f9730b14c5aae",
#>       "@type": "Dataset",
#>       "name": "CNSIM1",
#>       "description": "",
#>       "url": "/datasource/CNSIM/table/CNSIM1",
#>       "dateCreated": "2026-03-27T00:00:00Z",
#>       "dateModified": "2026-03-27T00:00:00Z",
#>       "isPartOf": {
#>         "@id": "#project:7ba189863f9f641196596cb28e04aa14"
#>       }
#>     },
#>     {
#>       "@id": "#asset:b6721026564c746f604df7ba785931fa",
#>       "@type": "Dataset",
#>       "name": "CNSIM2",
#>       "description": "",
#>       "url": "/datasource/CNSIM/table/CNSIM2",
#>       "dateCreated": "2026-03-27T00:00:00Z",
#>       "dateModified": "2026-03-27T00:00:00Z",
#>       "isPartOf": {
#>         "@id": "#project:7ba189863f9f641196596cb28e04aa14"
#>       }
#>     },
#>     {
#>       "@id": "#asset:14fbb8de0021e6d237a2ed7779f9625d",
#>       "@type": "Dataset",
#>       "name": "CNSIM3",
#>       "description": "",
#>       "url": "/datasource/CNSIM/table/CNSIM3",
#>       "dateCreated": "2026-03-27T00:00:00Z",
#>       "dateModified": "2026-03-27T00:00:00Z",
#>       "isPartOf": {
#>         "@id": "#project:7ba189863f9f641196596cb28e04aa14"
#>       }
#>     },
#>     {
#>       "@id": "#disc:27d8c1d2233ecb654a24b635fd4dbd78",
#>       "@type": "PropertyValue",
#>       "name": "datashield.privacyLevel",
#>       "value": "5"
#>     },
#>     {
#>       "@id": "#disc:46b65707a6b998f3b1364bc10e6d9b4b",
#>       "@type": "PropertyValue",
#>       "name": "default.datashield.privacyControlLevel",
#>       "value": "banana"
#>     },
#>     {
#>       "@id": "#disc:7769282e7b0a1cb8887f60886c7b56ae",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.glm",
#>       "value": "0.33"
#>     },
#>     {
#>       "@id": "#disc:49d822f52075aafbec1d1b2545aa46b7",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.kNN",
#>       "value": "3"
#>     },
#>     {
#>       "@id": "#disc:9a59210a743557bbd61cb21c3f1e0a79",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.levels.density",
#>       "value": "0.33"
#>     },
#>     {
#>       "@id": "#disc:a00b1e31a448142ee66bbb013f990e1f",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.levels.max",
#>       "value": "40"
#>     },
#>     {
#>       "@id": "#disc:29dd5e27a9f1c66d81a7037c236e7dd5",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.noise",
#>       "value": "0.25"
#>     },
#>     {
#>       "@id": "#disc:1c12e549b91e2cc0856f56657988ce54",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.string",
#>       "value": "80"
#>     },
#>     {
#>       "@id": "#disc:786bc0ffcdd3054925e431240caecea5",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.stringShort",
#>       "value": "20"
#>     },
#>     {
#>       "@id": "#disc:fd9bea5ef311d5f14b28d237ecb6e985",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.subset",
#>       "value": "3"
#>     },
#>     {
#>       "@id": "#disc:4e93a50cbd8cfea8f0a6adc50ee7aac0",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.tab",
#>       "value": "3"
#>     },
#>     {
#>       "@id": "#env:disclosure_settings:7d746edc2fb36ee671241a333742b3a8",
#>       "@type": "CreativeWork",
#>       "name": "Disclosure Control Environment",
#>       "description": "Disclosure control settings extract from the OBiBa Opal server connection provided, using the profile: 'default'.",
#>       "hasPart": [
#>         {
#>           "@id": "#disc:27d8c1d2233ecb654a24b635fd4dbd78"
#>         },
#>         {
#>           "@id": "#disc:46b65707a6b998f3b1364bc10e6d9b4b"
#>         },
#>         {
#>           "@id": "#disc:7769282e7b0a1cb8887f60886c7b56ae"
#>         },
#>         {
#>           "@id": "#disc:49d822f52075aafbec1d1b2545aa46b7"
#>         },
#>         {
#>           "@id": "#disc:9a59210a743557bbd61cb21c3f1e0a79"
#>         },
#>         {
#>           "@id": "#disc:a00b1e31a448142ee66bbb013f990e1f"
#>         },
#>         {
#>           "@id": "#disc:29dd5e27a9f1c66d81a7037c236e7dd5"
#>         },
#>         {
#>           "@id": "#disc:1c12e549b91e2cc0856f56657988ce54"
#>         },
#>         {
#>           "@id": "#disc:786bc0ffcdd3054925e431240caecea5"
#>         },
#>         {
#>           "@id": "#disc:fd9bea5ef311d5f14b28d237ecb6e985"
#>         },
#>         {
#>           "@id": "#disc:4e93a50cbd8cfea8f0a6adc50ee7aac0"
#>         }
#>       ]
#>     },
#>     {
#>       "@id": "#software:f8784d80bad08f840fba23fa9c41ec27",
#>       "@type": "SoftwareApplication",
#>       "name": "dsBase",
#>       "version": "6.3.5",
#>       "description": "Base 'DataSHIELD' functions for the server side. 'DataSHIELD' is a software package which allows you to do non-disclosive federated analysis on sensitive data. 'DataSHIELD' analytic functions have been designed to only share non disclosive summary statistics, with built in automated output checking based on statistical disclosure control. With data sites setting the threshold values for the automated output checks. For more details, see 'citation(\"dsBase\")'."
#>     },
#>     {
#>       "@id": "#software:afa897ee58de14b27570462c97a9dd44",
#>       "@type": "SoftwareApplication",
#>       "name": "dsTidyverse",
#>       "version": "1.1.0",
#>       "description": "Implementation of selected 'Tidyverse' functions within 'DataSHIELD', an open-source federated analysis solution in R. Currently, DataSHIELD contains very limited tools for data manipulation, so the aim of this package is to improve the researcher experience by implementing essential functions for data manipulation, including subsetting, filtering, grouping, and renaming variables. This is the serverside package which should be installed on the server holding the data, and is used in conjuncture with the clientside package 'dsTidyverseClient' which is installed in the local R environment of the analyst. For more information, see <https://tidyverse.org/> and <https://datashield.org/>."
#>     },
#>     {
#>       "@id": "#software:d2133fef4ca6df6312f205e51aee541b",
#>       "@type": "SoftwareApplication",
#>       "name": "resourcer",
#>       "version": "1.5.0",
#>       "description": "A resource represents some data or a computation unit. It is described by a URL and credentials. This package proposes a Resource model with \"resolver\" and \"client\" classes to facilitate the access and the usage of the resources."
#>     },
#>     {
#>       "@id": "#software:77514b155cfdb0c8c535fbe54daf67fc",
#>       "@type": "SoftwareApplication",
#>       "name": "Opal",
#>       "version": "5.6.1",
#>       "description": "Opal is OBiBa's (https://www.obiba.org/) core database application for epidemiological studies. Participant data, collected by questionnaires, medical instruments, sensors, administrative databases etc. can be integrated and stored in a central data repository under a uniform model."
#>     },
#>     {
#>       "@id": "#env:software_stack:239d65ed3c0c0c3932e23cebb34be7e1",
#>       "@type": "CreativeWork",
#>       "name": "Approved Analytical Software Environment",
#>       "description": "Software packages installed in the controlled Opal/DataSHIELD environment used for federated analysis.",
#>       "hasPart": [
#>         {
#>           "@id": "#software:f8784d80bad08f840fba23fa9c41ec27"
#>         },
#>         {
#>           "@id": "#software:afa897ee58de14b27570462c97a9dd44"
#>         },
#>         {
#>           "@id": "#software:d2133fef4ca6df6312f205e51aee541b"
#>         },
#>         {
#>           "@id": "#software:77514b155cfdb0c8c535fbe54daf67fc"
#>         }
#>       ]
#>     },
#>     {
#>       "@id": "#control:output-checking",
#>       "@type": "CreativeWork",
#>       "name": "Statistical Disclosure Output Checking",
#>       "description": "Automated disclosure control prevents release of small-cell counts and disclosive statistics."
#>     },
#>     {
#>       "@id": "#control:server-side-analysis",
#>       "@type": "CreativeWork",
#>       "name": "Server-Side Analysis Enforcement",
#>       "description": "Raw data never leaves the secure server; analysis occurs via vetted aggregate functions."
#>     },
#>     {
#>       "@id": "#control:session-logging",
#>       "@type": "CreativeWork",
#>       "name": "Comprehensive Session Logging",
#>       "description": "All analytical actions are logged and auditable."
#>     },
#>     {
#>       "@id": "#control:secure-facility",
#>       "@type": "CreativeWork",
#>       "name": "Secure Data Facility",
#>       "description": "Access restricted to approved secure premises."
#>     },
#>     {
#>       "@id": "#control:access-governance",
#>       "@type": "CreativeWork",
#>       "name": "Access Governance Process",
#>       "description": "Data access committee review and approval required."
#>     },
#>     {
#>       "@id": "#safesetting:8489860e7540c5dfb95b5d8ddab232c5",
#>       "@type": "CreativeWork",
#>       "name": "Safe Setting Controls (Opal)",
#>       "description": "Technical, physical and organisational safeguards applied to minimise disclosure risk.",
#>       "hasPart": [
#>         {
#>           "@id": "#env:disclosure_settings:7d746edc2fb36ee671241a333742b3a8"
#>         },
#>         {
#>           "@id": "#env:software_stack:239d65ed3c0c0c3932e23cebb34be7e1"
#>         },
#>         {
#>           "@id": "#control:output-checking"
#>         },
#>         {
#>           "@id": "#control:server-side-analysis"
#>         },
#>         {
#>           "@id": "#control:session-logging"
#>         },
#>         {
#>           "@id": "#control:secure-facility"
#>         },
#>         {
#>           "@id": "#control:access-governance"
#>         }
#>       ]
#>     },
#>     {
#>       "@id": "#link:b16fbdedcc33e826878020dcd5fad3d3",
#>       "@type": "CreativeWork",
#>       "name": "Safe Settings x Safe Project Link",
#>       "about": {
#>         "@id": "#safesetting:8489860e7540c5dfb95b5d8ddab232c5"
#>       },
#>       "isPartOf": {
#>         "@id": "#project:7ba189863f9f641196596cb28e04aa14"
#>       }
#>     },
#>     {
#>       "@id": "20260327T120003-dslogs-dsuser.log",
#>       "@type": "File",
#>       "dateModified": "2026-03-27 12:00:03",
#>       "name": "20260327T120003-dslogs-dsuser.log",
#>       "description": "This file contains the raw logs for the user: `dsuser` , between: ALL and ALL",
#>       "encodingFormat": "text/plain",
#>       "content": [
#>         ["[INFO][2026-03-27T11:59:57][OPEN]      created a datashield session 84b50a64-e51e-4d54-a155-bd3ebbdbcdf8", "[INFO][2026-03-27T11:59:59][ASSIGN]    created symbol 'dsROCrate_test' from: 'dsROCrate_test <- opal[CNSIM.CNSIM1]'", "[INFO][2026-03-27T12:00:00][PARSE]     parsed 'dsBase::lsDS(search.filter = NULL, 1L)'", "[INFO][2026-03-27T12:00:01][AGGREGATE] evaluated 'dsBase::lsDS(search.filter = NULL, 1L)'", "[INFO][2026-03-27T12:00:01][PARSE]     parsed 'base::exists(\"dsROCrate_test\")'", "[INFO][2026-03-27T12:00:01][AGGREGATE] evaluated 'base::exists(\"dsROCrate_test\")'", "[INFO][2026-03-27T12:00:01][PARSE]     parsed 'dsBase::classDS(\"dsROCrate_test\")'", "[INFO][2026-03-27T12:00:01][AGGREGATE] evaluated 'dsBase::classDS(\"dsROCrate_test\")'", "[INFO][2026-03-27T12:00:01][PARSE]     parsed 'dsBase::isValidDS(dsROCrate_test)'", "[INFO][2026-03-27T12:00:01][AGGREGATE] evaluated 'dsBase::isValidDS(dsROCrate_test)'", "[INFO][2026-03-27T12:00:01][PARSE]     parsed 'dsBase::dimDS(\"dsROCrate_test\")'", "[INFO][2026-03-27T12:00:01][AGGREGATE] evaluated 'dsBase::dimDS(\"dsROCrate_test\")'", "[INFO][2026-03-27T12:00:01][PARSE]     parsed 'dsBase::colnamesDS(\"dsROCrate_test\")'", "[INFO][2026-03-27T12:00:01][AGGREGATE] evaluated 'dsBase::colnamesDS(\"dsROCrate_test\")'"]
#>       ]
#>     },
#>     {
#>       "@id": "20260327T120003-dslogs-dsuser_mappings.csv",
#>       "@type": "File",
#>       "dateModified": "2026-03-27 12:00:03",
#>       "name": "20260327T120003-dslogs-dsuser_mappings.csv",
#>       "description": "This file contains mappings and evaluated functions",
#>       "encodingFormat": "text/csv",
#>       "content": [
#>         [
#>           {
#>             "timestamp": "2026-03-27T11:59:57",
#>             "action": "OPEN",
#>             "user": "dsuser",
#>             "r_cmd": "Open session: 84b50a64-e51e-4d54-a155-bd3ebbdbcdf8",
#>             "fx": "DSI::datashield.login",
#>             "session": "84b50a64-e51e-4d54-a155-bd3ebbdbcdf8",
#>             "backend": "OBiBa's Opal"
#>           },
#>           {
#>             "timestamp": "2026-03-27T11:59:59",
#>             "action": "ASSIGN",
#>             "user": "dsuser",
#>             "r_cmd": "dsROCrate_test <- opal[CNSIM.CNSIM1]",
#>             "fx": "base::assign",
#>             "table": "CNSIM.CNSIM1",
#>             "session": "84b50a64-e51e-4d54-a155-bd3ebbdbcdf8",
#>             "backend": "OBiBa's Opal"
#>           },
#>           {
#>             "timestamp": "2026-03-27T12:00:01",
#>             "action": "AGGREGATE",
#>             "user": "dsuser",
#>             "r_cmd": "dsBase::lsDS(search.filter = NULL, 1L)",
#>             "fx": "dsBase::lsDS",
#>             "symbol": "search.filter = NULL, 1L",
#>             "table": "CNSIM.CNSIM1",
#>             "session": "84b50a64-e51e-4d54-a155-bd3ebbdbcdf8",
#>             "backend": "OBiBa's Opal"
#>           },
#>           {
#>             "timestamp": "2026-03-27T12:00:01",
#>             "action": "AGGREGATE",
#>             "user": "dsuser",
#>             "r_cmd": "base::exists(\"dsROCrate_test\")",
#>             "fx": "base::exists",
#>             "symbol": "dsROCrate_test",
#>             "table": "CNSIM.CNSIM1",
#>             "session": "84b50a64-e51e-4d54-a155-bd3ebbdbcdf8",
#>             "backend": "OBiBa's Opal"
#>           },
#>           {
#>             "timestamp": "2026-03-27T12:00:01",
#>             "action": "AGGREGATE",
#>             "user": "dsuser",
#>             "r_cmd": "dsBase::classDS(\"dsROCrate_test\")",
#>             "fx": "dsBase::classDS",
#>             "symbol": "dsROCrate_test",
#>             "table": "CNSIM.CNSIM1",
#>             "session": "84b50a64-e51e-4d54-a155-bd3ebbdbcdf8",
#>             "backend": "OBiBa's Opal"
#>           },
#>           {
#>             "timestamp": "2026-03-27T12:00:01",
#>             "action": "AGGREGATE",
#>             "user": "dsuser",
#>             "r_cmd": "dsBase::isValidDS(dsROCrate_test)",
#>             "fx": "dsBase::isValidDS",
#>             "symbol": "dsROCrate_test",
#>             "table": "CNSIM.CNSIM1",
#>             "session": "84b50a64-e51e-4d54-a155-bd3ebbdbcdf8",
#>             "backend": "OBiBa's Opal"
#>           },
#>           {
#>             "timestamp": "2026-03-27T12:00:01",
#>             "action": "AGGREGATE",
#>             "user": "dsuser",
#>             "r_cmd": "dsBase::dimDS(\"dsROCrate_test\")",
#>             "fx": "dsBase::dimDS",
#>             "symbol": "dsROCrate_test",
#>             "table": "CNSIM.CNSIM1",
#>             "session": "84b50a64-e51e-4d54-a155-bd3ebbdbcdf8",
#>             "backend": "OBiBa's Opal"
#>           },
#>           {
#>             "timestamp": "2026-03-27T12:00:01",
#>             "action": "AGGREGATE",
#>             "user": "dsuser",
#>             "r_cmd": "dsBase::colnamesDS(\"dsROCrate_test\")",
#>             "fx": "dsBase::colnamesDS",
#>             "symbol": "dsROCrate_test",
#>             "table": "CNSIM.CNSIM1",
#>             "session": "84b50a64-e51e-4d54-a155-bd3ebbdbcdf8",
#>             "backend": "OBiBa's Opal"
#>           }
#>         ]
#>       ]
#>     }
#>   ]
#> }
```

###### Markdown report

A markdown report can be created with an overview and details for an
RO-Crate, using the `dsROCrate::report`:

**Only generate .Rmd file**

``` r
safe_people_crate_v1_rmd <- tempfile(fileext = ".Rmd") # temporary file

safe_people_crate_contents <- safe_people_crate_v1 |>
  dsROCrate::report(filepath = safe_people_crate_v1_rmd, render = FALSE)
#> 1 'Author' entity was found!
#> 3 asset entities were found!
#> 1 'Project' entity was found!
#> 22 'CreativeWork', 'PropertyValue' OR 'SoftwareApplication' entities were found!
#> 2 'File' entities were found!

# display Overview diagram
safe_people_crate_contents$overview_diagram
```

<img src="man/figures/README-safe_people_crate_audit_v1-1.png" alt="" width="100%" />

``` r

# display Overview data (Safe People, Safe Projects and Safe Data)
safe_people_crate_contents$overview_data |>
  knitr::kable()
```

| Project | Data   | Access Level | People | Function           | Timestamp           |
|:--------|:-------|:-------------|:-------|:-------------------|:--------------------|
| CNSIM   | CNSIM1 | read         | dsuser | base::assign       | 2026-03-27T11:59:59 |
| CNSIM   | CNSIM1 | read         | dsuser | dsBase::lsDS       | 2026-03-27T12:00:01 |
| CNSIM   | CNSIM1 | read         | dsuser | base::exists       | 2026-03-27T12:00:01 |
| CNSIM   | CNSIM1 | read         | dsuser | dsBase::classDS    | 2026-03-27T12:00:01 |
| CNSIM   | CNSIM1 | read         | dsuser | dsBase::isValidDS  | 2026-03-27T12:00:01 |
| CNSIM   | CNSIM1 | read         | dsuser | dsBase::dimDS      | 2026-03-27T12:00:01 |
| CNSIM   | CNSIM1 | read         | dsuser | dsBase::colnamesDS | 2026-03-27T12:00:01 |
| CNSIM   | CNSIM2 | read         | dsuser |                    |                     |
| CNSIM   | CNSIM3 | read         | dsuser |                    |                     |

**Render and display report (HTML)**

``` r
safe_people_crate_v1 |>
  dsROCrate::report(filepath = safe_people_crate_v1_rmd,
                            title = "DataSHIELD Safe People - Audit Report",
                            render = TRUE, 
                            overwrite = TRUE)
```

### 3.2. Audit Project

##### List users and dataset/table level permissions within a project

``` r
safe_project_crate_v1 <- opalr::opal.login(
  username = USERNAME,
  password = USERPASS,
  url = SERVER
) |>
  dsROCrate::audit(project = "CNSIM")
#> opening file input connection.
#>  Found 55 records... Imported 55 records. Simplifying...
#> closing file input connection.
#> opening file input connection.
#>  Found 55 records... Imported 55 records. Simplifying...
#> closing file input connection.
#> opening file input connection.
#>  Found 55 records... Imported 55 records. Simplifying...
#> closing file input connection.
#> opening file input connection.
#>  Found 55 records... Imported 55 records. Simplifying...
#> closing file input connection.

print(safe_project_crate_v1)
#> {
#>   "@context": "https://w3id.org/ro/crate/1.2/context",
#>   "@graph": [
#>     {
#>       "@id": "ro-crate-metadata.json",
#>       "@type": "CreativeWork",
#>       "about": {
#>         "@id": "./"
#>       },
#>       "conformsTo": {
#>         "@id": "https://w3id.org/ro/crate/1.2"
#>       }
#>     },
#>     {
#>       "@id": "./",
#>       "@type": "Dataset",
#>       "name": "",
#>       "description": "",
#>       "datePublished": "2026-03-27",
#>       "license": {
#>         "@id": "http://spdx.org/licenses/CC-BY-4.0"
#>       },
#>       "conformsTo": {
#>         "@id": "https://w3id.org/5s-crate/0.4"
#>       },
#>       "hasPart": [
#>         {
#>           "@id": "20260327T120011-dslogs-dsuser.log"
#>         },
#>         {
#>           "@id": "20260327T120011-dslogs-dsuser_mappings.csv"
#>         }
#>       ]
#>     },
#>     {
#>       "@id": "https://w3id.org/5s-crate/0.4",
#>       "@type": ["CreativeWork", "Profile"],
#>       "name": "Five Safes RO-Crate profile"
#>     },
#>     {
#>       "@id": "#person:a0af2a94926db1b49ad7a812eef509d2",
#>       "@type": "Person",
#>       "name": "dsuser"
#>     },
#>     {
#>       "@id": "#person:cb809df1c2fb30b154f60b843e62b3d0",
#>       "@type": "Person",
#>       "name": "dsuser1"
#>     },
#>     {
#>       "@id": "#person:a3cd7ce7818436c83b1eadaa5ba47411",
#>       "@type": "Person",
#>       "name": "dsuser2"
#>     },
#>     {
#>       "@id": "#person:5657241505661473308ae9aa9a378293",
#>       "@type": "Person",
#>       "name": "dsuser3"
#>     },
#>     {
#>       "@id": "#project:7ba189863f9f641196596cb28e04aa14",
#>       "@type": "Project",
#>       "name": "CNSIM",
#>       "dateCreated": "2026-03-27T06:29:56.149Z",
#>       "dateModified": "2026-03-27T06:30:01.340Z",
#>       "hasPart": [
#>         {
#>           "@id": "#asset:fad6faf661584d53e58f9730b14c5aae"
#>         },
#>         {
#>           "@id": "#asset:b6721026564c746f604df7ba785931fa"
#>         },
#>         {
#>           "@id": "#asset:14fbb8de0021e6d237a2ed7779f9625d"
#>         }
#>       ]
#>     },
#>     {
#>       "@id": "#perm:9bf7f75b6c5b07d02830b95652cd39a0-dict-summary-read",
#>       "@type": "ReadAction",
#>       "agent": {
#>         "@id": "#person:a0af2a94926db1b49ad7a812eef509d2"
#>       },
#>       "object": {
#>         "@id": "#asset:fad6faf661584d53e58f9730b14c5aae"
#>       },
#>       "actionStatus": "PotentialActionStatus",
#>       "description": "User may view table dictionary and summary statistics only; access to individual values is restricted."
#>     },
#>     {
#>       "@id": "#perm:4d2673da68a58c3bce23a61d97b6df51-dict-summary-read",
#>       "@type": "ReadAction",
#>       "agent": {
#>         "@id": "#person:cb809df1c2fb30b154f60b843e62b3d0"
#>       },
#>       "object": {
#>         "@id": "#asset:fad6faf661584d53e58f9730b14c5aae"
#>       },
#>       "actionStatus": "PotentialActionStatus",
#>       "description": "User may view table dictionary and summary statistics only; access to individual values is restricted."
#>     },
#>     {
#>       "@id": "#perm:363eb627d1e49c08933f2e26142e6d56-dict-summary-read",
#>       "@type": "ReadAction",
#>       "agent": {
#>         "@id": "#person:a0af2a94926db1b49ad7a812eef509d2"
#>       },
#>       "object": {
#>         "@id": "#asset:b6721026564c746f604df7ba785931fa"
#>       },
#>       "actionStatus": "PotentialActionStatus",
#>       "description": "User may view table dictionary and summary statistics only; access to individual values is restricted."
#>     },
#>     {
#>       "@id": "#perm:802d140a064e6ebf3a784f759af1b640-dict-summary-read",
#>       "@type": "ReadAction",
#>       "agent": {
#>         "@id": "#person:a3cd7ce7818436c83b1eadaa5ba47411"
#>       },
#>       "object": {
#>         "@id": "#asset:b6721026564c746f604df7ba785931fa"
#>       },
#>       "actionStatus": "PotentialActionStatus",
#>       "description": "User may view table dictionary and summary statistics only; access to individual values is restricted."
#>     },
#>     {
#>       "@id": "#perm:63b8097908f682bff1760e48d28c5855-dict-summary-read",
#>       "@type": "ReadAction",
#>       "agent": {
#>         "@id": "#person:a0af2a94926db1b49ad7a812eef509d2"
#>       },
#>       "object": {
#>         "@id": "#asset:14fbb8de0021e6d237a2ed7779f9625d"
#>       },
#>       "actionStatus": "PotentialActionStatus",
#>       "description": "User may view table dictionary and summary statistics only; access to individual values is restricted."
#>     },
#>     {
#>       "@id": "#perm:04c3f293c7a360fe0a1b7c29c8363540-dict-summary-read",
#>       "@type": "ReadAction",
#>       "agent": {
#>         "@id": "#person:5657241505661473308ae9aa9a378293"
#>       },
#>       "object": {
#>         "@id": "#asset:14fbb8de0021e6d237a2ed7779f9625d"
#>       },
#>       "actionStatus": "PotentialActionStatus",
#>       "description": "User may view table dictionary and summary statistics only; access to individual values is restricted."
#>     },
#>     {
#>       "@id": "#asset:fad6faf661584d53e58f9730b14c5aae",
#>       "@type": "Dataset",
#>       "name": "CNSIM1",
#>       "description": "",
#>       "url": "/datasource/CNSIM/table/CNSIM1",
#>       "dateCreated": "2026-03-27T00:00:00Z",
#>       "dateModified": "2026-03-27T00:00:00Z",
#>       "isPartOf": {
#>         "@id": "#project:7ba189863f9f641196596cb28e04aa14"
#>       }
#>     },
#>     {
#>       "@id": "#asset:b6721026564c746f604df7ba785931fa",
#>       "@type": "Dataset",
#>       "name": "CNSIM2",
#>       "description": "",
#>       "url": "/datasource/CNSIM/table/CNSIM2",
#>       "dateCreated": "2026-03-27T00:00:00Z",
#>       "dateModified": "2026-03-27T00:00:00Z",
#>       "isPartOf": {
#>         "@id": "#project:7ba189863f9f641196596cb28e04aa14"
#>       }
#>     },
#>     {
#>       "@id": "#asset:14fbb8de0021e6d237a2ed7779f9625d",
#>       "@type": "Dataset",
#>       "name": "CNSIM3",
#>       "description": "",
#>       "url": "/datasource/CNSIM/table/CNSIM3",
#>       "dateCreated": "2026-03-27T00:00:00Z",
#>       "dateModified": "2026-03-27T00:00:00Z",
#>       "isPartOf": {
#>         "@id": "#project:7ba189863f9f641196596cb28e04aa14"
#>       }
#>     },
#>     {
#>       "@id": "#disc:27d8c1d2233ecb654a24b635fd4dbd78",
#>       "@type": "PropertyValue",
#>       "name": "datashield.privacyLevel",
#>       "value": "5"
#>     },
#>     {
#>       "@id": "#disc:46b65707a6b998f3b1364bc10e6d9b4b",
#>       "@type": "PropertyValue",
#>       "name": "default.datashield.privacyControlLevel",
#>       "value": "banana"
#>     },
#>     {
#>       "@id": "#disc:7769282e7b0a1cb8887f60886c7b56ae",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.glm",
#>       "value": "0.33"
#>     },
#>     {
#>       "@id": "#disc:49d822f52075aafbec1d1b2545aa46b7",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.kNN",
#>       "value": "3"
#>     },
#>     {
#>       "@id": "#disc:9a59210a743557bbd61cb21c3f1e0a79",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.levels.density",
#>       "value": "0.33"
#>     },
#>     {
#>       "@id": "#disc:a00b1e31a448142ee66bbb013f990e1f",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.levels.max",
#>       "value": "40"
#>     },
#>     {
#>       "@id": "#disc:29dd5e27a9f1c66d81a7037c236e7dd5",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.noise",
#>       "value": "0.25"
#>     },
#>     {
#>       "@id": "#disc:1c12e549b91e2cc0856f56657988ce54",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.string",
#>       "value": "80"
#>     },
#>     {
#>       "@id": "#disc:786bc0ffcdd3054925e431240caecea5",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.stringShort",
#>       "value": "20"
#>     },
#>     {
#>       "@id": "#disc:fd9bea5ef311d5f14b28d237ecb6e985",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.subset",
#>       "value": "3"
#>     },
#>     {
#>       "@id": "#disc:4e93a50cbd8cfea8f0a6adc50ee7aac0",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.tab",
#>       "value": "3"
#>     },
#>     {
#>       "@id": "#env:disclosure_settings:7d746edc2fb36ee671241a333742b3a8",
#>       "@type": "CreativeWork",
#>       "name": "Disclosure Control Environment",
#>       "description": "Disclosure control settings extract from the OBiBa Opal server connection provided, using the profile: 'default'.",
#>       "hasPart": [
#>         {
#>           "@id": "#disc:27d8c1d2233ecb654a24b635fd4dbd78"
#>         },
#>         {
#>           "@id": "#disc:46b65707a6b998f3b1364bc10e6d9b4b"
#>         },
#>         {
#>           "@id": "#disc:7769282e7b0a1cb8887f60886c7b56ae"
#>         },
#>         {
#>           "@id": "#disc:49d822f52075aafbec1d1b2545aa46b7"
#>         },
#>         {
#>           "@id": "#disc:9a59210a743557bbd61cb21c3f1e0a79"
#>         },
#>         {
#>           "@id": "#disc:a00b1e31a448142ee66bbb013f990e1f"
#>         },
#>         {
#>           "@id": "#disc:29dd5e27a9f1c66d81a7037c236e7dd5"
#>         },
#>         {
#>           "@id": "#disc:1c12e549b91e2cc0856f56657988ce54"
#>         },
#>         {
#>           "@id": "#disc:786bc0ffcdd3054925e431240caecea5"
#>         },
#>         {
#>           "@id": "#disc:fd9bea5ef311d5f14b28d237ecb6e985"
#>         },
#>         {
#>           "@id": "#disc:4e93a50cbd8cfea8f0a6adc50ee7aac0"
#>         }
#>       ]
#>     },
#>     {
#>       "@id": "#software:f8784d80bad08f840fba23fa9c41ec27",
#>       "@type": "SoftwareApplication",
#>       "name": "dsBase",
#>       "version": "6.3.5",
#>       "description": "Base 'DataSHIELD' functions for the server side. 'DataSHIELD' is a software package which allows you to do non-disclosive federated analysis on sensitive data. 'DataSHIELD' analytic functions have been designed to only share non disclosive summary statistics, with built in automated output checking based on statistical disclosure control. With data sites setting the threshold values for the automated output checks. For more details, see 'citation(\"dsBase\")'."
#>     },
#>     {
#>       "@id": "#software:afa897ee58de14b27570462c97a9dd44",
#>       "@type": "SoftwareApplication",
#>       "name": "dsTidyverse",
#>       "version": "1.1.0",
#>       "description": "Implementation of selected 'Tidyverse' functions within 'DataSHIELD', an open-source federated analysis solution in R. Currently, DataSHIELD contains very limited tools for data manipulation, so the aim of this package is to improve the researcher experience by implementing essential functions for data manipulation, including subsetting, filtering, grouping, and renaming variables. This is the serverside package which should be installed on the server holding the data, and is used in conjuncture with the clientside package 'dsTidyverseClient' which is installed in the local R environment of the analyst. For more information, see <https://tidyverse.org/> and <https://datashield.org/>."
#>     },
#>     {
#>       "@id": "#software:d2133fef4ca6df6312f205e51aee541b",
#>       "@type": "SoftwareApplication",
#>       "name": "resourcer",
#>       "version": "1.5.0",
#>       "description": "A resource represents some data or a computation unit. It is described by a URL and credentials. This package proposes a Resource model with \"resolver\" and \"client\" classes to facilitate the access and the usage of the resources."
#>     },
#>     {
#>       "@id": "#software:77514b155cfdb0c8c535fbe54daf67fc",
#>       "@type": "SoftwareApplication",
#>       "name": "Opal",
#>       "version": "5.6.1",
#>       "description": "Opal is OBiBa's (https://www.obiba.org/) core database application for epidemiological studies. Participant data, collected by questionnaires, medical instruments, sensors, administrative databases etc. can be integrated and stored in a central data repository under a uniform model."
#>     },
#>     {
#>       "@id": "#env:software_stack:239d65ed3c0c0c3932e23cebb34be7e1",
#>       "@type": "CreativeWork",
#>       "name": "Approved Analytical Software Environment",
#>       "description": "Software packages installed in the controlled Opal/DataSHIELD environment used for federated analysis.",
#>       "hasPart": [
#>         {
#>           "@id": "#software:f8784d80bad08f840fba23fa9c41ec27"
#>         },
#>         {
#>           "@id": "#software:afa897ee58de14b27570462c97a9dd44"
#>         },
#>         {
#>           "@id": "#software:d2133fef4ca6df6312f205e51aee541b"
#>         },
#>         {
#>           "@id": "#software:77514b155cfdb0c8c535fbe54daf67fc"
#>         }
#>       ]
#>     },
#>     {
#>       "@id": "#control:output-checking",
#>       "@type": "CreativeWork",
#>       "name": "Statistical Disclosure Output Checking",
#>       "description": "Automated disclosure control prevents release of small-cell counts and disclosive statistics."
#>     },
#>     {
#>       "@id": "#control:server-side-analysis",
#>       "@type": "CreativeWork",
#>       "name": "Server-Side Analysis Enforcement",
#>       "description": "Raw data never leaves the secure server; analysis occurs via vetted aggregate functions."
#>     },
#>     {
#>       "@id": "#control:session-logging",
#>       "@type": "CreativeWork",
#>       "name": "Comprehensive Session Logging",
#>       "description": "All analytical actions are logged and auditable."
#>     },
#>     {
#>       "@id": "#control:secure-facility",
#>       "@type": "CreativeWork",
#>       "name": "Secure Data Facility",
#>       "description": "Access restricted to approved secure premises."
#>     },
#>     {
#>       "@id": "#control:access-governance",
#>       "@type": "CreativeWork",
#>       "name": "Access Governance Process",
#>       "description": "Data access committee review and approval required."
#>     },
#>     {
#>       "@id": "#safesetting:8489860e7540c5dfb95b5d8ddab232c5",
#>       "@type": "CreativeWork",
#>       "name": "Safe Setting Controls (Opal)",
#>       "description": "Technical, physical and organisational safeguards applied to minimise disclosure risk.",
#>       "hasPart": [
#>         {
#>           "@id": "#env:disclosure_settings:7d746edc2fb36ee671241a333742b3a8"
#>         },
#>         {
#>           "@id": "#env:software_stack:239d65ed3c0c0c3932e23cebb34be7e1"
#>         },
#>         {
#>           "@id": "#control:output-checking"
#>         },
#>         {
#>           "@id": "#control:server-side-analysis"
#>         },
#>         {
#>           "@id": "#control:session-logging"
#>         },
#>         {
#>           "@id": "#control:secure-facility"
#>         },
#>         {
#>           "@id": "#control:access-governance"
#>         }
#>       ]
#>     },
#>     {
#>       "@id": "#link:b16fbdedcc33e826878020dcd5fad3d3",
#>       "@type": "CreativeWork",
#>       "name": "Safe Settings x Safe Project Link",
#>       "about": {
#>         "@id": "#safesetting:8489860e7540c5dfb95b5d8ddab232c5"
#>       },
#>       "isPartOf": {
#>         "@id": "#project:7ba189863f9f641196596cb28e04aa14"
#>       }
#>     },
#>     {
#>       "@id": "20260327T120011-dslogs-dsuser.log",
#>       "@type": "File",
#>       "dateModified": "2026-03-27 12:00:11",
#>       "name": "20260327T120011-dslogs-dsuser.log",
#>       "description": "This file contains the raw logs for the user: `dsuser` , between: ALL and ALL",
#>       "encodingFormat": "text/plain",
#>       "content": [
#>         ["[INFO][2026-03-27T11:59:57][OPEN]      created a datashield session 84b50a64-e51e-4d54-a155-bd3ebbdbcdf8", "[INFO][2026-03-27T11:59:59][ASSIGN]    created symbol 'dsROCrate_test' from: 'dsROCrate_test <- opal[CNSIM.CNSIM1]'", "[INFO][2026-03-27T12:00:00][PARSE]     parsed 'dsBase::lsDS(search.filter = NULL, 1L)'", "[INFO][2026-03-27T12:00:01][AGGREGATE] evaluated 'dsBase::lsDS(search.filter = NULL, 1L)'", "[INFO][2026-03-27T12:00:01][PARSE]     parsed 'base::exists(\"dsROCrate_test\")'", "[INFO][2026-03-27T12:00:01][AGGREGATE] evaluated 'base::exists(\"dsROCrate_test\")'", "[INFO][2026-03-27T12:00:01][PARSE]     parsed 'dsBase::classDS(\"dsROCrate_test\")'", "[INFO][2026-03-27T12:00:01][AGGREGATE] evaluated 'dsBase::classDS(\"dsROCrate_test\")'", "[INFO][2026-03-27T12:00:01][PARSE]     parsed 'dsBase::isValidDS(dsROCrate_test)'", "[INFO][2026-03-27T12:00:01][AGGREGATE] evaluated 'dsBase::isValidDS(dsROCrate_test)'", "[INFO][2026-03-27T12:00:01][PARSE]     parsed 'dsBase::dimDS(\"dsROCrate_test\")'", "[INFO][2026-03-27T12:00:01][AGGREGATE] evaluated 'dsBase::dimDS(\"dsROCrate_test\")'", "[INFO][2026-03-27T12:00:01][PARSE]     parsed 'dsBase::colnamesDS(\"dsROCrate_test\")'", "[INFO][2026-03-27T12:00:01][AGGREGATE] evaluated 'dsBase::colnamesDS(\"dsROCrate_test\")'"]
#>       ]
#>     },
#>     {
#>       "@id": "20260327T120011-dslogs-dsuser_mappings.csv",
#>       "@type": "File",
#>       "dateModified": "2026-03-27 12:00:11",
#>       "name": "20260327T120011-dslogs-dsuser_mappings.csv",
#>       "description": "This file contains mappings and evaluated functions",
#>       "encodingFormat": "text/csv",
#>       "content": [
#>         [
#>           {
#>             "timestamp": "2026-03-27T11:59:57",
#>             "action": "OPEN",
#>             "user": "dsuser",
#>             "r_cmd": "Open session: 84b50a64-e51e-4d54-a155-bd3ebbdbcdf8",
#>             "fx": "DSI::datashield.login",
#>             "session": "84b50a64-e51e-4d54-a155-bd3ebbdbcdf8",
#>             "backend": "OBiBa's Opal"
#>           },
#>           {
#>             "timestamp": "2026-03-27T11:59:59",
#>             "action": "ASSIGN",
#>             "user": "dsuser",
#>             "r_cmd": "dsROCrate_test <- opal[CNSIM.CNSIM1]",
#>             "fx": "base::assign",
#>             "table": "CNSIM.CNSIM1",
#>             "session": "84b50a64-e51e-4d54-a155-bd3ebbdbcdf8",
#>             "backend": "OBiBa's Opal"
#>           },
#>           {
#>             "timestamp": "2026-03-27T12:00:01",
#>             "action": "AGGREGATE",
#>             "user": "dsuser",
#>             "r_cmd": "dsBase::lsDS(search.filter = NULL, 1L)",
#>             "fx": "dsBase::lsDS",
#>             "symbol": "search.filter = NULL, 1L",
#>             "table": "CNSIM.CNSIM1",
#>             "session": "84b50a64-e51e-4d54-a155-bd3ebbdbcdf8",
#>             "backend": "OBiBa's Opal"
#>           },
#>           {
#>             "timestamp": "2026-03-27T12:00:01",
#>             "action": "AGGREGATE",
#>             "user": "dsuser",
#>             "r_cmd": "base::exists(\"dsROCrate_test\")",
#>             "fx": "base::exists",
#>             "symbol": "dsROCrate_test",
#>             "table": "CNSIM.CNSIM1",
#>             "session": "84b50a64-e51e-4d54-a155-bd3ebbdbcdf8",
#>             "backend": "OBiBa's Opal"
#>           },
#>           {
#>             "timestamp": "2026-03-27T12:00:01",
#>             "action": "AGGREGATE",
#>             "user": "dsuser",
#>             "r_cmd": "dsBase::classDS(\"dsROCrate_test\")",
#>             "fx": "dsBase::classDS",
#>             "symbol": "dsROCrate_test",
#>             "table": "CNSIM.CNSIM1",
#>             "session": "84b50a64-e51e-4d54-a155-bd3ebbdbcdf8",
#>             "backend": "OBiBa's Opal"
#>           },
#>           {
#>             "timestamp": "2026-03-27T12:00:01",
#>             "action": "AGGREGATE",
#>             "user": "dsuser",
#>             "r_cmd": "dsBase::isValidDS(dsROCrate_test)",
#>             "fx": "dsBase::isValidDS",
#>             "symbol": "dsROCrate_test",
#>             "table": "CNSIM.CNSIM1",
#>             "session": "84b50a64-e51e-4d54-a155-bd3ebbdbcdf8",
#>             "backend": "OBiBa's Opal"
#>           },
#>           {
#>             "timestamp": "2026-03-27T12:00:01",
#>             "action": "AGGREGATE",
#>             "user": "dsuser",
#>             "r_cmd": "dsBase::dimDS(\"dsROCrate_test\")",
#>             "fx": "dsBase::dimDS",
#>             "symbol": "dsROCrate_test",
#>             "table": "CNSIM.CNSIM1",
#>             "session": "84b50a64-e51e-4d54-a155-bd3ebbdbcdf8",
#>             "backend": "OBiBa's Opal"
#>           },
#>           {
#>             "timestamp": "2026-03-27T12:00:01",
#>             "action": "AGGREGATE",
#>             "user": "dsuser",
#>             "r_cmd": "dsBase::colnamesDS(\"dsROCrate_test\")",
#>             "fx": "dsBase::colnamesDS",
#>             "symbol": "dsROCrate_test",
#>             "table": "CNSIM.CNSIM1",
#>             "session": "84b50a64-e51e-4d54-a155-bd3ebbdbcdf8",
#>             "backend": "OBiBa's Opal"
#>           }
#>         ]
#>       ]
#>     }
#>   ]
#> }
```

###### Markdown report

A markdown report can be created with an overview and details for an
RO-Crate, using the `dsROCrate::report`:

**Only generate .Rmd file**

``` r
safe_project_crate_v1_rmd <- tempfile(fileext = ".Rmd") # temporary file

safe_project_crate_contents <- safe_project_crate_v1 |>
  dsROCrate::report(filepath = safe_project_crate_v1_rmd, render = FALSE)
#> 4 'Author' entities were found!
#> 3 asset entities were found!
#> 1 'Project' entity was found!
#> 22 'CreativeWork', 'PropertyValue' OR 'SoftwareApplication' entities were found!
#> 2 'File' entities were found!

# display Overview diagram
safe_project_crate_contents$overview_diagram
```

<img src="man/figures/README-safe_project_crate_audit_v1-1.png" alt="" width="100%" />

``` r

# display Overview data (Safe People, Safe Projects and Safe Data)
safe_project_crate_contents$overview_data |>
  knitr::kable()
```

| Project | Data   | Access Level | People  | Function           | Timestamp           |
|:--------|:-------|:-------------|:--------|:-------------------|:--------------------|
| CNSIM   | CNSIM1 | read         | dsuser  | base::assign       | 2026-03-27T11:59:59 |
| CNSIM   | CNSIM1 | read         | dsuser  | dsBase::lsDS       | 2026-03-27T12:00:01 |
| CNSIM   | CNSIM1 | read         | dsuser  | base::exists       | 2026-03-27T12:00:01 |
| CNSIM   | CNSIM1 | read         | dsuser  | dsBase::classDS    | 2026-03-27T12:00:01 |
| CNSIM   | CNSIM1 | read         | dsuser  | dsBase::isValidDS  | 2026-03-27T12:00:01 |
| CNSIM   | CNSIM1 | read         | dsuser  | dsBase::dimDS      | 2026-03-27T12:00:01 |
| CNSIM   | CNSIM1 | read         | dsuser  | dsBase::colnamesDS | 2026-03-27T12:00:01 |
| CNSIM   | CNSIM1 | read         | dsuser1 |                    |                     |
| CNSIM   | CNSIM2 | read         | dsuser  |                    |                     |
| CNSIM   | CNSIM2 | read         | dsuser2 |                    |                     |
| CNSIM   | CNSIM3 | read         | dsuser  |                    |                     |
| CNSIM   | CNSIM3 | read         | dsuser3 |                    |                     |

**Render and display report (HTML)**

``` r
safe_project_crate_v1 |>
  dsROCrate::report(filepath = safe_project_crate_v1_rmd, 
                            title = "DataSHIELD Safe Project - Audit Report",
                            render = TRUE, 
                            overwrite = TRUE)
```

<br />

### 3.3. Audit Study

##### List users and dataset/table level permissions within a study (i.e., multiple servers)

``` r
study_crate_v1 <- 
  list(
    "opal_test" = opalr::opal.login(
      username = USERNAME,
      password = USERPASS,
      url = "https://opal-test.obiba.org"
    ),
    "opal_demo" = opalr::opal.login(
      username = USERNAME,
      password = USERPASS,
      url = "https://opal-demo.obiba.org"
    )
  ) |>
  dsROCrate::audit(project = "CNSIM")
#> opening file input connection.
#>  Found 6 records... Imported 6 records. Simplifying...
#> closing file input connection.
#> opening file input connection.
#>  Found 6 records... Imported 6 records. Simplifying...
#> closing file input connection.
#> opening file input connection.
#>  Found 6 records... Imported 6 records. Simplifying...
#> closing file input connection.
#> opening file input connection.
#>  Found 6 records... Imported 6 records. Simplifying...
#> closing file input connection.
#> opening file input connection.
#>  Found 6 records... Imported 6 records. Simplifying...
#> closing file input connection.
#> opening file input connection.
#>  Found 6 records... Imported 6 records. Simplifying...
#> closing file input connection.
#> opening file input connection.
#>  Found 55 records... Imported 55 records. Simplifying...
#> closing file input connection.
#> opening file input connection.
#>  Found 55 records... Imported 55 records. Simplifying...
#> closing file input connection.
#> opening file input connection.
#>  Found 55 records... Imported 55 records. Simplifying...
#> closing file input connection.
#> opening file input connection.
#>  Found 55 records... Imported 55 records. Simplifying...
#> closing file input connection.

print(study_crate_v1)
#> $opal_test
#> {
#>   "@context": "https://w3id.org/ro/crate/1.2/context",
#>   "@graph": [
#>     {
#>       "@id": "ro-crate-metadata.json",
#>       "@type": "CreativeWork",
#>       "about": {
#>         "@id": "./"
#>       },
#>       "conformsTo": {
#>         "@id": "https://w3id.org/ro/crate/1.2"
#>       }
#>     },
#>     {
#>       "@id": "./",
#>       "@type": "Dataset",
#>       "name": "",
#>       "description": "",
#>       "datePublished": "2026-03-27",
#>       "license": {
#>         "@id": "http://spdx.org/licenses/CC-BY-4.0"
#>       },
#>       "conformsTo": {
#>         "@id": "https://w3id.org/5s-crate/0.4"
#>       }
#>     },
#>     {
#>       "@id": "https://w3id.org/5s-crate/0.4",
#>       "@type": ["CreativeWork", "Profile"],
#>       "name": "Five Safes RO-Crate profile"
#>     },
#>     {
#>       "@id": "#person:8ab380609ec94312fa958741d1f0f0b1",
#>       "@type": "Person",
#>       "name": "user1"
#>     },
#>     {
#>       "@id": "#person:89bba9a8875a3a16196372b4c087edbd",
#>       "@type": "Person",
#>       "name": "ds"
#>     },
#>     {
#>       "@id": "#person:ab761662ca15f3f7658a0b3adeaae564",
#>       "@type": "Person",
#>       "name": "bthillo@gmail.com",
#>       "sub": "109004362127439404576",
#>       "email_verified": true,
#>       "given_name": "Roberto",
#>       "family_name": "Villegas-Diaz",
#>       "picture": "https://lh3.googleusercontent.com/a/ACg8ocK8GIJLuuDRjfevJjXSZ8Ymw_Y67r8_bsud8eLGClA92MS-GLhd8Q=s96-c",
#>       "email": "bthillo@gmail.com"
#>     },
#>     {
#>       "@id": "#person:f53ed7aa4ab05429c9d20f360d451a98",
#>       "@type": "Person",
#>       "name": "i.w.farr@googlemail.com",
#>       "sub": "106174335072326132292",
#>       "email_verified": true,
#>       "given_name": "ian",
#>       "family_name": "farr",
#>       "picture": "https://lh3.googleusercontent.com/a/ACg8ocKBagSKWdPGazh5CWkffgXleyPaSqn66IlAOMm0voLm-79S1A=s96-c",
#>       "email": "i.w.farr@googlemail.com"
#>     },
#>     {
#>       "@id": "#person:a0af2a94926db1b49ad7a812eef509d2",
#>       "@type": "Person",
#>       "name": "dsuser"
#>     },
#>     {
#>       "@id": "#person:315ba97bcf520312d32e7f1e4f5e8575",
#>       "@type": "Person",
#>       "name": "yannick.marcon@obiba.org",
#>       "sub": "112183318969537221630",
#>       "email_verified": true,
#>       "given_name": "Yannick",
#>       "hd": "obiba.org",
#>       "family_name": "Marcon",
#>       "picture": "https://lh3.googleusercontent.com/a/ACg8ocJFG4mQ2lz80itm91vEUX3jnj12IRv1tF_OaVBDf2Ear6pUsA=s96-c",
#>       "email": "yannick.marcon@obiba.org"
#>     },
#>     {
#>       "@id": "#project:7ba189863f9f641196596cb28e04aa14",
#>       "@type": "Project",
#>       "name": "CNSIM",
#>       "dateCreated": "2026-01-08T17:40:46.773Z",
#>       "dateModified": "2026-01-17T10:53:52.663Z",
#>       "hasPart": [
#>         {
#>           "@id": "#asset:fad6faf661584d53e58f9730b14c5aae"
#>         },
#>         {
#>           "@id": "#asset:b6721026564c746f604df7ba785931fa"
#>         },
#>         {
#>           "@id": "#asset:14fbb8de0021e6d237a2ed7779f9625d"
#>         }
#>       ]
#>     },
#>     {
#>       "@id": "#perm:9bf7f75b6c5b07d02830b95652cd39a0-dict-summary-read",
#>       "@type": "ReadAction",
#>       "agent": {
#>         "@id": "#person:a0af2a94926db1b49ad7a812eef509d2"
#>       },
#>       "object": {
#>         "@id": "#asset:fad6faf661584d53e58f9730b14c5aae"
#>       },
#>       "actionStatus": "PotentialActionStatus",
#>       "description": "User may view table dictionary and summary statistics only; access to individual values is restricted."
#>     },
#>     {
#>       "@id": "#asset:fad6faf661584d53e58f9730b14c5aae",
#>       "@type": "Dataset",
#>       "name": "CNSIM1",
#>       "description": "",
#>       "url": "/datasource/CNSIM/table/CNSIM1",
#>       "dateCreated": "2026-01-17T00:00:00Z",
#>       "dateModified": "2026-01-17T00:00:00Z",
#>       "isPartOf": {
#>         "@id": "#project:7ba189863f9f641196596cb28e04aa14"
#>       }
#>     },
#>     {
#>       "@id": "#asset:b6721026564c746f604df7ba785931fa",
#>       "@type": "Dataset",
#>       "name": "CNSIM2",
#>       "description": "",
#>       "url": "/datasource/CNSIM/table/CNSIM2",
#>       "dateCreated": "2026-01-17T00:00:00Z",
#>       "dateModified": "2026-01-17T00:00:00Z",
#>       "isPartOf": {
#>         "@id": "#project:7ba189863f9f641196596cb28e04aa14"
#>       }
#>     },
#>     {
#>       "@id": "#asset:14fbb8de0021e6d237a2ed7779f9625d",
#>       "@type": "Dataset",
#>       "name": "CNSIM3",
#>       "description": "",
#>       "url": "/datasource/CNSIM/table/CNSIM3",
#>       "dateCreated": "2026-01-17T00:00:00Z",
#>       "dateModified": "2026-01-17T00:00:00Z",
#>       "isPartOf": {
#>         "@id": "#project:7ba189863f9f641196596cb28e04aa14"
#>       }
#>     },
#>     {
#>       "@id": "#disc:27d8c1d2233ecb654a24b635fd4dbd78",
#>       "@type": "PropertyValue",
#>       "name": "datashield.privacyLevel",
#>       "value": "5"
#>     },
#>     {
#>       "@id": "#disc:46b65707a6b998f3b1364bc10e6d9b4b",
#>       "@type": "PropertyValue",
#>       "name": "default.datashield.privacyControlLevel",
#>       "value": "banana"
#>     },
#>     {
#>       "@id": "#disc:7769282e7b0a1cb8887f60886c7b56ae",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.glm",
#>       "value": "0.33"
#>     },
#>     {
#>       "@id": "#disc:49d822f52075aafbec1d1b2545aa46b7",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.kNN",
#>       "value": "3"
#>     },
#>     {
#>       "@id": "#disc:9a59210a743557bbd61cb21c3f1e0a79",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.levels.density",
#>       "value": "0.33"
#>     },
#>     {
#>       "@id": "#disc:a00b1e31a448142ee66bbb013f990e1f",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.levels.max",
#>       "value": "40"
#>     },
#>     {
#>       "@id": "#disc:29dd5e27a9f1c66d81a7037c236e7dd5",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.noise",
#>       "value": "0.25"
#>     },
#>     {
#>       "@id": "#disc:1c12e549b91e2cc0856f56657988ce54",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.string",
#>       "value": "80"
#>     },
#>     {
#>       "@id": "#disc:786bc0ffcdd3054925e431240caecea5",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.stringShort",
#>       "value": "20"
#>     },
#>     {
#>       "@id": "#disc:fd9bea5ef311d5f14b28d237ecb6e985",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.subset",
#>       "value": "3"
#>     },
#>     {
#>       "@id": "#disc:4e93a50cbd8cfea8f0a6adc50ee7aac0",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.tab",
#>       "value": "3"
#>     },
#>     {
#>       "@id": "#env:disclosure_settings:7d746edc2fb36ee671241a333742b3a8",
#>       "@type": "CreativeWork",
#>       "name": "Disclosure Control Environment",
#>       "description": "Disclosure control settings extract from the OBiBa Opal server connection provided, using the profile: 'default'.",
#>       "hasPart": [
#>         {
#>           "@id": "#disc:27d8c1d2233ecb654a24b635fd4dbd78"
#>         },
#>         {
#>           "@id": "#disc:46b65707a6b998f3b1364bc10e6d9b4b"
#>         },
#>         {
#>           "@id": "#disc:7769282e7b0a1cb8887f60886c7b56ae"
#>         },
#>         {
#>           "@id": "#disc:49d822f52075aafbec1d1b2545aa46b7"
#>         },
#>         {
#>           "@id": "#disc:9a59210a743557bbd61cb21c3f1e0a79"
#>         },
#>         {
#>           "@id": "#disc:a00b1e31a448142ee66bbb013f990e1f"
#>         },
#>         {
#>           "@id": "#disc:29dd5e27a9f1c66d81a7037c236e7dd5"
#>         },
#>         {
#>           "@id": "#disc:1c12e549b91e2cc0856f56657988ce54"
#>         },
#>         {
#>           "@id": "#disc:786bc0ffcdd3054925e431240caecea5"
#>         },
#>         {
#>           "@id": "#disc:fd9bea5ef311d5f14b28d237ecb6e985"
#>         },
#>         {
#>           "@id": "#disc:4e93a50cbd8cfea8f0a6adc50ee7aac0"
#>         }
#>       ]
#>     },
#>     {
#>       "@id": "#software:f8784d80bad08f840fba23fa9c41ec27",
#>       "@type": "SoftwareApplication",
#>       "name": "dsBase",
#>       "version": "6.3.5",
#>       "description": "Base 'DataSHIELD' functions for the server side. 'DataSHIELD' is a software package which allows you to do non-disclosive federated analysis on sensitive data. 'DataSHIELD' analytic functions have been designed to only share non disclosive summary statistics, with built in automated output checking based on statistical disclosure control. With data sites setting the threshold values for the automated output checks. For more details, see 'citation(\"dsBase\")'."
#>     },
#>     {
#>       "@id": "#software:afa897ee58de14b27570462c97a9dd44",
#>       "@type": "SoftwareApplication",
#>       "name": "dsTidyverse",
#>       "version": "1.1.0",
#>       "description": "Implementation of selected 'Tidyverse' functions within 'DataSHIELD', an open-source federated analysis solution in R. Currently, DataSHIELD contains very limited tools for data manipulation, so the aim of this package is to improve the researcher experience by implementing essential functions for data manipulation, including subsetting, filtering, grouping, and renaming variables. This is the serverside package which should be installed on the server holding the data, and is used in conjuncture with the clientside package 'dsTidyverseClient' which is installed in the local R environment of the analyst. For more information, see <https://tidyverse.org/> and <https://datashield.org/>."
#>     },
#>     {
#>       "@id": "#software:d2133fef4ca6df6312f205e51aee541b",
#>       "@type": "SoftwareApplication",
#>       "name": "resourcer",
#>       "version": "1.5.0",
#>       "description": "A resource represents some data or a computation unit. It is described by a URL and credentials. This package proposes a Resource model with \"resolver\" and \"client\" classes to facilitate the access and the usage of the resources."
#>     },
#>     {
#>       "@id": "#software:0cd42af0c314700303b0c4b14b16b9ce",
#>       "@type": "SoftwareApplication",
#>       "name": "Opal",
#>       "version": "5.6.0-SNAPSHOT",
#>       "description": "Opal is OBiBa's (https://www.obiba.org/) core database application for epidemiological studies. Participant data, collected by questionnaires, medical instruments, sensors, administrative databases etc. can be integrated and stored in a central data repository under a uniform model."
#>     },
#>     {
#>       "@id": "#env:software_stack:55187df92eed3fae2198151d49e29389",
#>       "@type": "CreativeWork",
#>       "name": "Approved Analytical Software Environment",
#>       "description": "Software packages installed in the controlled Opal/DataSHIELD environment used for federated analysis.",
#>       "hasPart": [
#>         {
#>           "@id": "#software:f8784d80bad08f840fba23fa9c41ec27"
#>         },
#>         {
#>           "@id": "#software:afa897ee58de14b27570462c97a9dd44"
#>         },
#>         {
#>           "@id": "#software:d2133fef4ca6df6312f205e51aee541b"
#>         },
#>         {
#>           "@id": "#software:0cd42af0c314700303b0c4b14b16b9ce"
#>         }
#>       ]
#>     },
#>     {
#>       "@id": "#control:output-checking",
#>       "@type": "CreativeWork",
#>       "name": "Statistical Disclosure Output Checking",
#>       "description": "Automated disclosure control prevents release of small-cell counts and disclosive statistics."
#>     },
#>     {
#>       "@id": "#control:server-side-analysis",
#>       "@type": "CreativeWork",
#>       "name": "Server-Side Analysis Enforcement",
#>       "description": "Raw data never leaves the secure server; analysis occurs via vetted aggregate functions."
#>     },
#>     {
#>       "@id": "#control:session-logging",
#>       "@type": "CreativeWork",
#>       "name": "Comprehensive Session Logging",
#>       "description": "All analytical actions are logged and auditable."
#>     },
#>     {
#>       "@id": "#control:secure-facility",
#>       "@type": "CreativeWork",
#>       "name": "Secure Data Facility",
#>       "description": "Access restricted to approved secure premises."
#>     },
#>     {
#>       "@id": "#control:access-governance",
#>       "@type": "CreativeWork",
#>       "name": "Access Governance Process",
#>       "description": "Data access committee review and approval required."
#>     },
#>     {
#>       "@id": "#safesetting:8489860e7540c5dfb95b5d8ddab232c5",
#>       "@type": "CreativeWork",
#>       "name": "Safe Setting Controls (Opal)",
#>       "description": "Technical, physical and organisational safeguards applied to minimise disclosure risk.",
#>       "hasPart": [
#>         {
#>           "@id": "#env:disclosure_settings:7d746edc2fb36ee671241a333742b3a8"
#>         },
#>         {
#>           "@id": "#env:software_stack:55187df92eed3fae2198151d49e29389"
#>         },
#>         {
#>           "@id": "#control:output-checking"
#>         },
#>         {
#>           "@id": "#control:server-side-analysis"
#>         },
#>         {
#>           "@id": "#control:session-logging"
#>         },
#>         {
#>           "@id": "#control:secure-facility"
#>         },
#>         {
#>           "@id": "#control:access-governance"
#>         }
#>       ]
#>     },
#>     {
#>       "@id": "#link:b16fbdedcc33e826878020dcd5fad3d3",
#>       "@type": "CreativeWork",
#>       "name": "Safe Settings x Safe Project Link",
#>       "about": {
#>         "@id": "#safesetting:8489860e7540c5dfb95b5d8ddab232c5"
#>       },
#>       "isPartOf": {
#>         "@id": "#project:7ba189863f9f641196596cb28e04aa14"
#>       }
#>     }
#>   ]
#> }
#> 
#> $opal_demo
#> {
#>   "@context": "https://w3id.org/ro/crate/1.2/context",
#>   "@graph": [
#>     {
#>       "@id": "ro-crate-metadata.json",
#>       "@type": "CreativeWork",
#>       "about": {
#>         "@id": "./"
#>       },
#>       "conformsTo": {
#>         "@id": "https://w3id.org/ro/crate/1.2"
#>       }
#>     },
#>     {
#>       "@id": "./",
#>       "@type": "Dataset",
#>       "name": "",
#>       "description": "",
#>       "datePublished": "2026-03-27",
#>       "license": {
#>         "@id": "http://spdx.org/licenses/CC-BY-4.0"
#>       },
#>       "conformsTo": {
#>         "@id": "https://w3id.org/5s-crate/0.4"
#>       },
#>       "hasPart": [
#>         {
#>           "@id": "20260327T120017-dslogs-dsuser.log"
#>         },
#>         {
#>           "@id": "20260327T120017-dslogs-dsuser_mappings.csv"
#>         }
#>       ]
#>     },
#>     {
#>       "@id": "https://w3id.org/5s-crate/0.4",
#>       "@type": ["CreativeWork", "Profile"],
#>       "name": "Five Safes RO-Crate profile"
#>     },
#>     {
#>       "@id": "#person:a0af2a94926db1b49ad7a812eef509d2",
#>       "@type": "Person",
#>       "name": "dsuser"
#>     },
#>     {
#>       "@id": "#person:cb809df1c2fb30b154f60b843e62b3d0",
#>       "@type": "Person",
#>       "name": "dsuser1"
#>     },
#>     {
#>       "@id": "#person:a3cd7ce7818436c83b1eadaa5ba47411",
#>       "@type": "Person",
#>       "name": "dsuser2"
#>     },
#>     {
#>       "@id": "#person:5657241505661473308ae9aa9a378293",
#>       "@type": "Person",
#>       "name": "dsuser3"
#>     },
#>     {
#>       "@id": "#project:7ba189863f9f641196596cb28e04aa14",
#>       "@type": "Project",
#>       "name": "CNSIM",
#>       "dateCreated": "2026-03-27T06:29:56.149Z",
#>       "dateModified": "2026-03-27T06:30:01.340Z",
#>       "hasPart": [
#>         {
#>           "@id": "#asset:fad6faf661584d53e58f9730b14c5aae"
#>         },
#>         {
#>           "@id": "#asset:b6721026564c746f604df7ba785931fa"
#>         },
#>         {
#>           "@id": "#asset:14fbb8de0021e6d237a2ed7779f9625d"
#>         }
#>       ]
#>     },
#>     {
#>       "@id": "#perm:9bf7f75b6c5b07d02830b95652cd39a0-dict-summary-read",
#>       "@type": "ReadAction",
#>       "agent": {
#>         "@id": "#person:a0af2a94926db1b49ad7a812eef509d2"
#>       },
#>       "object": {
#>         "@id": "#asset:fad6faf661584d53e58f9730b14c5aae"
#>       },
#>       "actionStatus": "PotentialActionStatus",
#>       "description": "User may view table dictionary and summary statistics only; access to individual values is restricted."
#>     },
#>     {
#>       "@id": "#perm:4d2673da68a58c3bce23a61d97b6df51-dict-summary-read",
#>       "@type": "ReadAction",
#>       "agent": {
#>         "@id": "#person:cb809df1c2fb30b154f60b843e62b3d0"
#>       },
#>       "object": {
#>         "@id": "#asset:fad6faf661584d53e58f9730b14c5aae"
#>       },
#>       "actionStatus": "PotentialActionStatus",
#>       "description": "User may view table dictionary and summary statistics only; access to individual values is restricted."
#>     },
#>     {
#>       "@id": "#perm:363eb627d1e49c08933f2e26142e6d56-dict-summary-read",
#>       "@type": "ReadAction",
#>       "agent": {
#>         "@id": "#person:a0af2a94926db1b49ad7a812eef509d2"
#>       },
#>       "object": {
#>         "@id": "#asset:b6721026564c746f604df7ba785931fa"
#>       },
#>       "actionStatus": "PotentialActionStatus",
#>       "description": "User may view table dictionary and summary statistics only; access to individual values is restricted."
#>     },
#>     {
#>       "@id": "#perm:802d140a064e6ebf3a784f759af1b640-dict-summary-read",
#>       "@type": "ReadAction",
#>       "agent": {
#>         "@id": "#person:a3cd7ce7818436c83b1eadaa5ba47411"
#>       },
#>       "object": {
#>         "@id": "#asset:b6721026564c746f604df7ba785931fa"
#>       },
#>       "actionStatus": "PotentialActionStatus",
#>       "description": "User may view table dictionary and summary statistics only; access to individual values is restricted."
#>     },
#>     {
#>       "@id": "#perm:63b8097908f682bff1760e48d28c5855-dict-summary-read",
#>       "@type": "ReadAction",
#>       "agent": {
#>         "@id": "#person:a0af2a94926db1b49ad7a812eef509d2"
#>       },
#>       "object": {
#>         "@id": "#asset:14fbb8de0021e6d237a2ed7779f9625d"
#>       },
#>       "actionStatus": "PotentialActionStatus",
#>       "description": "User may view table dictionary and summary statistics only; access to individual values is restricted."
#>     },
#>     {
#>       "@id": "#perm:04c3f293c7a360fe0a1b7c29c8363540-dict-summary-read",
#>       "@type": "ReadAction",
#>       "agent": {
#>         "@id": "#person:5657241505661473308ae9aa9a378293"
#>       },
#>       "object": {
#>         "@id": "#asset:14fbb8de0021e6d237a2ed7779f9625d"
#>       },
#>       "actionStatus": "PotentialActionStatus",
#>       "description": "User may view table dictionary and summary statistics only; access to individual values is restricted."
#>     },
#>     {
#>       "@id": "#asset:fad6faf661584d53e58f9730b14c5aae",
#>       "@type": "Dataset",
#>       "name": "CNSIM1",
#>       "description": "",
#>       "url": "/datasource/CNSIM/table/CNSIM1",
#>       "dateCreated": "2026-03-27T00:00:00Z",
#>       "dateModified": "2026-03-27T00:00:00Z",
#>       "isPartOf": {
#>         "@id": "#project:7ba189863f9f641196596cb28e04aa14"
#>       }
#>     },
#>     {
#>       "@id": "#asset:b6721026564c746f604df7ba785931fa",
#>       "@type": "Dataset",
#>       "name": "CNSIM2",
#>       "description": "",
#>       "url": "/datasource/CNSIM/table/CNSIM2",
#>       "dateCreated": "2026-03-27T00:00:00Z",
#>       "dateModified": "2026-03-27T00:00:00Z",
#>       "isPartOf": {
#>         "@id": "#project:7ba189863f9f641196596cb28e04aa14"
#>       }
#>     },
#>     {
#>       "@id": "#asset:14fbb8de0021e6d237a2ed7779f9625d",
#>       "@type": "Dataset",
#>       "name": "CNSIM3",
#>       "description": "",
#>       "url": "/datasource/CNSIM/table/CNSIM3",
#>       "dateCreated": "2026-03-27T00:00:00Z",
#>       "dateModified": "2026-03-27T00:00:00Z",
#>       "isPartOf": {
#>         "@id": "#project:7ba189863f9f641196596cb28e04aa14"
#>       }
#>     },
#>     {
#>       "@id": "#disc:27d8c1d2233ecb654a24b635fd4dbd78",
#>       "@type": "PropertyValue",
#>       "name": "datashield.privacyLevel",
#>       "value": "5"
#>     },
#>     {
#>       "@id": "#disc:46b65707a6b998f3b1364bc10e6d9b4b",
#>       "@type": "PropertyValue",
#>       "name": "default.datashield.privacyControlLevel",
#>       "value": "banana"
#>     },
#>     {
#>       "@id": "#disc:7769282e7b0a1cb8887f60886c7b56ae",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.glm",
#>       "value": "0.33"
#>     },
#>     {
#>       "@id": "#disc:49d822f52075aafbec1d1b2545aa46b7",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.kNN",
#>       "value": "3"
#>     },
#>     {
#>       "@id": "#disc:9a59210a743557bbd61cb21c3f1e0a79",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.levels.density",
#>       "value": "0.33"
#>     },
#>     {
#>       "@id": "#disc:a00b1e31a448142ee66bbb013f990e1f",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.levels.max",
#>       "value": "40"
#>     },
#>     {
#>       "@id": "#disc:29dd5e27a9f1c66d81a7037c236e7dd5",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.noise",
#>       "value": "0.25"
#>     },
#>     {
#>       "@id": "#disc:1c12e549b91e2cc0856f56657988ce54",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.string",
#>       "value": "80"
#>     },
#>     {
#>       "@id": "#disc:786bc0ffcdd3054925e431240caecea5",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.stringShort",
#>       "value": "20"
#>     },
#>     {
#>       "@id": "#disc:fd9bea5ef311d5f14b28d237ecb6e985",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.subset",
#>       "value": "3"
#>     },
#>     {
#>       "@id": "#disc:4e93a50cbd8cfea8f0a6adc50ee7aac0",
#>       "@type": "PropertyValue",
#>       "name": "default.nfilter.tab",
#>       "value": "3"
#>     },
#>     {
#>       "@id": "#env:disclosure_settings:7d746edc2fb36ee671241a333742b3a8",
#>       "@type": "CreativeWork",
#>       "name": "Disclosure Control Environment",
#>       "description": "Disclosure control settings extract from the OBiBa Opal server connection provided, using the profile: 'default'.",
#>       "hasPart": [
#>         {
#>           "@id": "#disc:27d8c1d2233ecb654a24b635fd4dbd78"
#>         },
#>         {
#>           "@id": "#disc:46b65707a6b998f3b1364bc10e6d9b4b"
#>         },
#>         {
#>           "@id": "#disc:7769282e7b0a1cb8887f60886c7b56ae"
#>         },
#>         {
#>           "@id": "#disc:49d822f52075aafbec1d1b2545aa46b7"
#>         },
#>         {
#>           "@id": "#disc:9a59210a743557bbd61cb21c3f1e0a79"
#>         },
#>         {
#>           "@id": "#disc:a00b1e31a448142ee66bbb013f990e1f"
#>         },
#>         {
#>           "@id": "#disc:29dd5e27a9f1c66d81a7037c236e7dd5"
#>         },
#>         {
#>           "@id": "#disc:1c12e549b91e2cc0856f56657988ce54"
#>         },
#>         {
#>           "@id": "#disc:786bc0ffcdd3054925e431240caecea5"
#>         },
#>         {
#>           "@id": "#disc:fd9bea5ef311d5f14b28d237ecb6e985"
#>         },
#>         {
#>           "@id": "#disc:4e93a50cbd8cfea8f0a6adc50ee7aac0"
#>         }
#>       ]
#>     },
#>     {
#>       "@id": "#software:f8784d80bad08f840fba23fa9c41ec27",
#>       "@type": "SoftwareApplication",
#>       "name": "dsBase",
#>       "version": "6.3.5",
#>       "description": "Base 'DataSHIELD' functions for the server side. 'DataSHIELD' is a software package which allows you to do non-disclosive federated analysis on sensitive data. 'DataSHIELD' analytic functions have been designed to only share non disclosive summary statistics, with built in automated output checking based on statistical disclosure control. With data sites setting the threshold values for the automated output checks. For more details, see 'citation(\"dsBase\")'."
#>     },
#>     {
#>       "@id": "#software:afa897ee58de14b27570462c97a9dd44",
#>       "@type": "SoftwareApplication",
#>       "name": "dsTidyverse",
#>       "version": "1.1.0",
#>       "description": "Implementation of selected 'Tidyverse' functions within 'DataSHIELD', an open-source federated analysis solution in R. Currently, DataSHIELD contains very limited tools for data manipulation, so the aim of this package is to improve the researcher experience by implementing essential functions for data manipulation, including subsetting, filtering, grouping, and renaming variables. This is the serverside package which should be installed on the server holding the data, and is used in conjuncture with the clientside package 'dsTidyverseClient' which is installed in the local R environment of the analyst. For more information, see <https://tidyverse.org/> and <https://datashield.org/>."
#>     },
#>     {
#>       "@id": "#software:d2133fef4ca6df6312f205e51aee541b",
#>       "@type": "SoftwareApplication",
#>       "name": "resourcer",
#>       "version": "1.5.0",
#>       "description": "A resource represents some data or a computation unit. It is described by a URL and credentials. This package proposes a Resource model with \"resolver\" and \"client\" classes to facilitate the access and the usage of the resources."
#>     },
#>     {
#>       "@id": "#software:77514b155cfdb0c8c535fbe54daf67fc",
#>       "@type": "SoftwareApplication",
#>       "name": "Opal",
#>       "version": "5.6.1",
#>       "description": "Opal is OBiBa's (https://www.obiba.org/) core database application for epidemiological studies. Participant data, collected by questionnaires, medical instruments, sensors, administrative databases etc. can be integrated and stored in a central data repository under a uniform model."
#>     },
#>     {
#>       "@id": "#env:software_stack:239d65ed3c0c0c3932e23cebb34be7e1",
#>       "@type": "CreativeWork",
#>       "name": "Approved Analytical Software Environment",
#>       "description": "Software packages installed in the controlled Opal/DataSHIELD environment used for federated analysis.",
#>       "hasPart": [
#>         {
#>           "@id": "#software:f8784d80bad08f840fba23fa9c41ec27"
#>         },
#>         {
#>           "@id": "#software:afa897ee58de14b27570462c97a9dd44"
#>         },
#>         {
#>           "@id": "#software:d2133fef4ca6df6312f205e51aee541b"
#>         },
#>         {
#>           "@id": "#software:77514b155cfdb0c8c535fbe54daf67fc"
#>         }
#>       ]
#>     },
#>     {
#>       "@id": "#control:output-checking",
#>       "@type": "CreativeWork",
#>       "name": "Statistical Disclosure Output Checking",
#>       "description": "Automated disclosure control prevents release of small-cell counts and disclosive statistics."
#>     },
#>     {
#>       "@id": "#control:server-side-analysis",
#>       "@type": "CreativeWork",
#>       "name": "Server-Side Analysis Enforcement",
#>       "description": "Raw data never leaves the secure server; analysis occurs via vetted aggregate functions."
#>     },
#>     {
#>       "@id": "#control:session-logging",
#>       "@type": "CreativeWork",
#>       "name": "Comprehensive Session Logging",
#>       "description": "All analytical actions are logged and auditable."
#>     },
#>     {
#>       "@id": "#control:secure-facility",
#>       "@type": "CreativeWork",
#>       "name": "Secure Data Facility",
#>       "description": "Access restricted to approved secure premises."
#>     },
#>     {
#>       "@id": "#control:access-governance",
#>       "@type": "CreativeWork",
#>       "name": "Access Governance Process",
#>       "description": "Data access committee review and approval required."
#>     },
#>     {
#>       "@id": "#safesetting:8489860e7540c5dfb95b5d8ddab232c5",
#>       "@type": "CreativeWork",
#>       "name": "Safe Setting Controls (Opal)",
#>       "description": "Technical, physical and organisational safeguards applied to minimise disclosure risk.",
#>       "hasPart": [
#>         {
#>           "@id": "#env:disclosure_settings:7d746edc2fb36ee671241a333742b3a8"
#>         },
#>         {
#>           "@id": "#env:software_stack:239d65ed3c0c0c3932e23cebb34be7e1"
#>         },
#>         {
#>           "@id": "#control:output-checking"
#>         },
#>         {
#>           "@id": "#control:server-side-analysis"
#>         },
#>         {
#>           "@id": "#control:session-logging"
#>         },
#>         {
#>           "@id": "#control:secure-facility"
#>         },
#>         {
#>           "@id": "#control:access-governance"
#>         }
#>       ]
#>     },
#>     {
#>       "@id": "#link:b16fbdedcc33e826878020dcd5fad3d3",
#>       "@type": "CreativeWork",
#>       "name": "Safe Settings x Safe Project Link",
#>       "about": {
#>         "@id": "#safesetting:8489860e7540c5dfb95b5d8ddab232c5"
#>       },
#>       "isPartOf": {
#>         "@id": "#project:7ba189863f9f641196596cb28e04aa14"
#>       }
#>     },
#>     {
#>       "@id": "20260327T120017-dslogs-dsuser.log",
#>       "@type": "File",
#>       "dateModified": "2026-03-27 12:00:17",
#>       "name": "20260327T120017-dslogs-dsuser.log",
#>       "description": "This file contains the raw logs for the user: `dsuser` , between: ALL and ALL",
#>       "encodingFormat": "text/plain",
#>       "content": [
#>         ["[INFO][2026-03-27T11:59:57][OPEN]      created a datashield session 84b50a64-e51e-4d54-a155-bd3ebbdbcdf8", "[INFO][2026-03-27T11:59:59][ASSIGN]    created symbol 'dsROCrate_test' from: 'dsROCrate_test <- opal[CNSIM.CNSIM1]'", "[INFO][2026-03-27T12:00:00][PARSE]     parsed 'dsBase::lsDS(search.filter = NULL, 1L)'", "[INFO][2026-03-27T12:00:01][AGGREGATE] evaluated 'dsBase::lsDS(search.filter = NULL, 1L)'", "[INFO][2026-03-27T12:00:01][PARSE]     parsed 'base::exists(\"dsROCrate_test\")'", "[INFO][2026-03-27T12:00:01][AGGREGATE] evaluated 'base::exists(\"dsROCrate_test\")'", "[INFO][2026-03-27T12:00:01][PARSE]     parsed 'dsBase::classDS(\"dsROCrate_test\")'", "[INFO][2026-03-27T12:00:01][AGGREGATE] evaluated 'dsBase::classDS(\"dsROCrate_test\")'", "[INFO][2026-03-27T12:00:01][PARSE]     parsed 'dsBase::isValidDS(dsROCrate_test)'", "[INFO][2026-03-27T12:00:01][AGGREGATE] evaluated 'dsBase::isValidDS(dsROCrate_test)'", "[INFO][2026-03-27T12:00:01][PARSE]     parsed 'dsBase::dimDS(\"dsROCrate_test\")'", "[INFO][2026-03-27T12:00:01][AGGREGATE] evaluated 'dsBase::dimDS(\"dsROCrate_test\")'", "[INFO][2026-03-27T12:00:01][PARSE]     parsed 'dsBase::colnamesDS(\"dsROCrate_test\")'", "[INFO][2026-03-27T12:00:01][AGGREGATE] evaluated 'dsBase::colnamesDS(\"dsROCrate_test\")'"]
#>       ]
#>     },
#>     {
#>       "@id": "20260327T120017-dslogs-dsuser_mappings.csv",
#>       "@type": "File",
#>       "dateModified": "2026-03-27 12:00:17",
#>       "name": "20260327T120017-dslogs-dsuser_mappings.csv",
#>       "description": "This file contains mappings and evaluated functions",
#>       "encodingFormat": "text/csv",
#>       "content": [
#>         [
#>           {
#>             "timestamp": "2026-03-27T11:59:57",
#>             "action": "OPEN",
#>             "user": "dsuser",
#>             "r_cmd": "Open session: 84b50a64-e51e-4d54-a155-bd3ebbdbcdf8",
#>             "fx": "DSI::datashield.login",
#>             "session": "84b50a64-e51e-4d54-a155-bd3ebbdbcdf8",
#>             "backend": "OBiBa's Opal"
#>           },
#>           {
#>             "timestamp": "2026-03-27T11:59:59",
#>             "action": "ASSIGN",
#>             "user": "dsuser",
#>             "r_cmd": "dsROCrate_test <- opal[CNSIM.CNSIM1]",
#>             "fx": "base::assign",
#>             "table": "CNSIM.CNSIM1",
#>             "session": "84b50a64-e51e-4d54-a155-bd3ebbdbcdf8",
#>             "backend": "OBiBa's Opal"
#>           },
#>           {
#>             "timestamp": "2026-03-27T12:00:01",
#>             "action": "AGGREGATE",
#>             "user": "dsuser",
#>             "r_cmd": "dsBase::lsDS(search.filter = NULL, 1L)",
#>             "fx": "dsBase::lsDS",
#>             "symbol": "search.filter = NULL, 1L",
#>             "table": "CNSIM.CNSIM1",
#>             "session": "84b50a64-e51e-4d54-a155-bd3ebbdbcdf8",
#>             "backend": "OBiBa's Opal"
#>           },
#>           {
#>             "timestamp": "2026-03-27T12:00:01",
#>             "action": "AGGREGATE",
#>             "user": "dsuser",
#>             "r_cmd": "base::exists(\"dsROCrate_test\")",
#>             "fx": "base::exists",
#>             "symbol": "dsROCrate_test",
#>             "table": "CNSIM.CNSIM1",
#>             "session": "84b50a64-e51e-4d54-a155-bd3ebbdbcdf8",
#>             "backend": "OBiBa's Opal"
#>           },
#>           {
#>             "timestamp": "2026-03-27T12:00:01",
#>             "action": "AGGREGATE",
#>             "user": "dsuser",
#>             "r_cmd": "dsBase::classDS(\"dsROCrate_test\")",
#>             "fx": "dsBase::classDS",
#>             "symbol": "dsROCrate_test",
#>             "table": "CNSIM.CNSIM1",
#>             "session": "84b50a64-e51e-4d54-a155-bd3ebbdbcdf8",
#>             "backend": "OBiBa's Opal"
#>           },
#>           {
#>             "timestamp": "2026-03-27T12:00:01",
#>             "action": "AGGREGATE",
#>             "user": "dsuser",
#>             "r_cmd": "dsBase::isValidDS(dsROCrate_test)",
#>             "fx": "dsBase::isValidDS",
#>             "symbol": "dsROCrate_test",
#>             "table": "CNSIM.CNSIM1",
#>             "session": "84b50a64-e51e-4d54-a155-bd3ebbdbcdf8",
#>             "backend": "OBiBa's Opal"
#>           },
#>           {
#>             "timestamp": "2026-03-27T12:00:01",
#>             "action": "AGGREGATE",
#>             "user": "dsuser",
#>             "r_cmd": "dsBase::dimDS(\"dsROCrate_test\")",
#>             "fx": "dsBase::dimDS",
#>             "symbol": "dsROCrate_test",
#>             "table": "CNSIM.CNSIM1",
#>             "session": "84b50a64-e51e-4d54-a155-bd3ebbdbcdf8",
#>             "backend": "OBiBa's Opal"
#>           },
#>           {
#>             "timestamp": "2026-03-27T12:00:01",
#>             "action": "AGGREGATE",
#>             "user": "dsuser",
#>             "r_cmd": "dsBase::colnamesDS(\"dsROCrate_test\")",
#>             "fx": "dsBase::colnamesDS",
#>             "symbol": "dsROCrate_test",
#>             "table": "CNSIM.CNSIM1",
#>             "session": "84b50a64-e51e-4d54-a155-bd3ebbdbcdf8",
#>             "backend": "OBiBa's Opal"
#>           }
#>         ]
#>       ]
#>     }
#>   ]
#> }
```

###### Markdown report

A markdown report can be created with an overview and details for an
RO-Crate, using the `dsROCrate::report`:

**Only generate .Rmd file**

``` r
study_crate_v1_rmd <- tempfile(fileext = ".Rmd") # temporary file

safe_project_crate_contents <- study_crate_v1 |>
  dsROCrate::report(filepath = study_crate_v1_rmd, render = FALSE)
#> 6 'Author' entities were found!
#> 3 asset entities were found!
#> 1 'Project' entity was found!
#> 22 'CreativeWork', 'PropertyValue' OR 'SoftwareApplication' entities were found!
#> 4 'Author' entities were found!
#> 3 asset entities were found!
#> 1 'Project' entity was found!
#> 22 'CreativeWork', 'PropertyValue' OR 'SoftwareApplication' entities were found!
#> 2 'File' entities were found!

# display Overview diagram
safe_project_crate_contents$overview_diagram
```

<img src="man/figures/README-study_crate_audit_v1-1.png" alt="" width="100%" />

``` r

# display Overview data (Safe People, Safe Projects and Safe Data)
safe_project_crate_contents$overview_data |>
  knitr::kable()
```

| Server | Project | Data | Access Level | People | Function | Timestamp |
|:---|:---|:---|:---|:---|:---|:---|
| opal_demo | CNSIM | CNSIM1 | read | dsuser | base::assign | 2026-03-27T11:59:59 |
| opal_demo | CNSIM | CNSIM1 | read | dsuser | dsBase::lsDS | 2026-03-27T12:00:01 |
| opal_demo | CNSIM | CNSIM1 | read | dsuser | base::exists | 2026-03-27T12:00:01 |
| opal_demo | CNSIM | CNSIM1 | read | dsuser | dsBase::classDS | 2026-03-27T12:00:01 |
| opal_demo | CNSIM | CNSIM1 | read | dsuser | dsBase::isValidDS | 2026-03-27T12:00:01 |
| opal_demo | CNSIM | CNSIM1 | read | dsuser | dsBase::dimDS | 2026-03-27T12:00:01 |
| opal_demo | CNSIM | CNSIM1 | read | dsuser | dsBase::colnamesDS | 2026-03-27T12:00:01 |
| opal_demo | CNSIM | CNSIM1 | read | dsuser1 |  |  |
| opal_demo | CNSIM | CNSIM2 | read | dsuser |  |  |
| opal_demo | CNSIM | CNSIM2 | read | dsuser2 |  |  |
| opal_demo | CNSIM | CNSIM3 | read | dsuser |  |  |
| opal_demo | CNSIM | CNSIM3 | read | dsuser3 |  |  |
| opal_test | CNSIM | CNSIM1 | read | dsuser |  |  |

**Render and display report (HTML)**

``` r
study_crate_v1 |>
  dsROCrate::report(filepath = study_crate_v1_rmd, 
                            title = "DataSHIELD Study audit",
                            render = TRUE, 
                            overwrite = TRUE)
```

<br />

## 4. Identity

You are welcome to use any of the following hex codes when referencing
`{dsROCrate}`:

[<img src="man/figures/logo.png" alt="logo" align="left" height="150" style="float:left; height:150px;"/>](man/figures/logo.png)
[<img src="man/figures/logo_white.png" alt="logo-white" align="left" height="150" style="float:left; height:150px;"/>](man/figures/logo_white.png)
[<img src="man/figures/logo_black.png" alt="logo-black" align="left" height="150" style="float:left; height:150px;"/>](man/figures/logo_black.png)
