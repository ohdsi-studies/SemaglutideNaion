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
library(dplyr)

##=========== START OF INPUTS ==========
outputLocation <- 'D:/git/ohdsi-studies/SemaglutideNaion'
databaseName <- "CCAE"
minCellCount <- 5

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

# Apply minCellCount
censor <- function(data, minValues) {
  values <- pull(data, "SUM_VALUE")
  toCensor <- !is.na(values) & (values < minValues) & (values != 0)
  if (all(is.na(toCensor)) || all(is.na(minValues))) {
    data[, "SUM_VALUE"] <- NA
    data[, "AVERAGE_VALUE"] <- NA
  } else if (length(minValues) == 1) {
    data[toCensor, "SUM_VALUE"] <- -minValues
    data[toCensor, "AVERAGE_VALUE"] <- 0
  } else {
    data[toCensor, "SUM_VALUE"] <- -minValues[toCensor]
    data[toCensor, "AVERAGE_VALUE"] <- 0
  }
  return(data)  
}

censoredData <- censor(x, minCellCount)

readr::write_csv(
  x = censoredData,
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