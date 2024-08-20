# -------------------------------------------------------
#                     PLEASE READ
# -------------------------------------------------------
#
# This script will export the full set of characterization
# results which were truncated to the first 1 million rows.
# Please make sure that for the inputs you use the same
# values that were used in the StrategusCodeToRun.R
#
# -------------------------------------------------------

##=========== START OF INPUTS ==========
outputLocation <- 'D:/git/ohdsi-studies/SemaglutideNaion'
databaseName <- "Pharmetrics"

## Do not change below this line -------------
resultsFolder = file.path(outputLocation, "results", databaseName, "strategusOutput")
workFolder = file.path(outputLocation, "results", databaseName, "strategusWork")
zipFile <- file.path(outputLocation, paste0(databaseName, "_c_covariates", ".zip"))

# Rename the truncated file
file.rename(
  from = file.path(resultsFolder, "CharacterizationModule", "c_covariates.csv"),
  to = file.path(resultsFolder, "CharacterizationModule", "c_covariates_limited_to_1m.bak")
)

connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = "sqlite",
  server = file.path(workFolder, "CharacterizationModule", "sqliteCharacterization", "sqlite.sqlite")
)

connection <- DatabaseConnector::connect(connectionDetails)
sql <- "SELECT * from main.c_covariates;"
x <- DatabaseConnector::querySql(connection = connection, sql = sql)
readr::write_csv(
  x = x,
  file = file.path(resultsFolder, "CharacterizationModule", "c_covariates.csv")
)
DatabaseConnector::disconnect(connection)

# Zip up the characterization results
DatabaseConnector::createZipFile(
  zipFile = zipFile,
  files = file.path(resultsFolder, "CharacterizationModule", "c_covariates.csv"),
  rootFolder = outputLocation
)

message("Patched characterization results are now available at: ", zipFile)