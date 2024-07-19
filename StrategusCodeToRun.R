# -------------------------------------------------------
#                     PLEASE READ
# -------------------------------------------------------
#
# You must call "renv::restore()" and follow the prompts
# to install all of the necessary R libraries to run this
# project. This is a one-time operation that you must do
# before running any code.
#
# -------------------------------------------------------

renv::restore()

##=========== START OF INPUTS ==========
workDatabaseSchema <- "main"
cdmDatabaseSchema <- "main"
databaseName <- "Eunomia" # Only used as a folder name for results from the study
outputLocation <- 'D:/git/ohdsi-studies/SemaglutideNaion'
minCellCount <- 5
cohortTableName <- "sema_naion"

# Create the connection details for your CDM
# More details on how to do this are found here:
# https://ohdsi.github.io/DatabaseConnector/reference/createConnectionDetails.html
connectionDetails = DatabaseConnector::createConnectionDetails(
  dbms = "redshift",
  connectionString = "jdbc://",
  user = "my_cdm_user_name",
  password = "my_cdm_password"
)

##=========== END OF INPUTS ==========
analysisSpecifications <- ParallelLogger::loadSettingsFromJson(
  fileName = "inst/fullStudyAnalysisSpecification.json"
)

# UNCOMMENT TO RUN COHORT DIAGNOSTICS
# analysisSpecifications <- ParallelLogger::loadSettingsFromJson(
#   fileName = "inst/cohortDiagnosticsAnalysisSpecification.json"
# )

executionSettings <- Strategus::createCdmExecutionSettings(
  workDatabaseSchema = workDatabaseSchema,
  cdmDatabaseSchema = cdmDatabaseSchema,
  cohortTableNames = CohortGenerator::getCohortTableNames(cohortTable = cohortTableName),
  workFolder = file.path(outputLocation, databaseName, "strategusWork"),
  resultsFolder = file.path(outputLocation, databaseName, "strategusOutput"),
  minCellCount = minCellCount
)

Strategus::execute(
  analysisSpecifications = analysisSpecifications,
  executionSettings = executionSettings,
  connectionDetails = connectionDetails
)


