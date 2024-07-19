library(dplyr)
library(Strategus)
rootFolder <- "D:/git/ohdsi-studies/SemaglutideNaion"


# Shared Resources -------------------------------------------------------------
# Get the list of cohorts
cohortDefinitionSet <- CohortGenerator::getCohortDefinitionSet(
  settingsFileName = "inst/Cohorts.csv",
  jsonFolder = "inst/cohorts",
  sqlFolder = "inst/sql/sql_server",
  cohortFileNameFormat = "%s_%s",
  cohortFileNameValue = c("cohortId", "cohortName")
)
sccsTList <- CohortGenerator::readCsv("inst/sccsTList.csv")

# CohortGeneratorModule --------------------------------------------------------
cgModuleSettingsCreator <- CohortGeneratorModule$new()
cohortDefinitionShared <- cgModuleSettingsCreator$createCohortSharedResourceSpecifications(cohortDefinitionSet)
cohortGeneratorModuleSpecifications <- cgModuleSettingsCreator$createModuleSpecifications(
  incremental = TRUE,
  generateStats = TRUE
)

# Exclude some cohorts from the diagnostics
cohortsToExclude <- c(
  17809, # sema Dec2017-Jan2020
  17810, # sema Feb2020-Jun2021
  17811, # sema Jul2021-Dec2023
  17812, # empa Dec2017-Jan2020
  17813, # empa Feb2020-Jun2021
  17814, # empa Jul2021-Dec2023
  sccsTList$targetCohortId
)
cdCohortIds <- setdiff(cohortDefinitionSet$cohortId, cohortsToExclude)

# Cohort Diagnostics -----------------
cdModuleSettingsCreator <- CohortDiagnosticsModule$new()
cdModuleSpecifications <- cdModuleSettingsCreator$createModuleSpecifications(
  cohortIds = cdCohortIds,
  runInclusionStatistics = TRUE,
  runIncludedSourceConcepts = TRUE,
  runOrphanConcepts = TRUE,
  runTimeSeries = FALSE,
  runVisitContext = TRUE,
  runBreakdownIndexEvents = TRUE,
  runIncidenceRate = TRUE,
  runCohortRelationship = TRUE,
  runTemporalCohortCharacterization = TRUE,
  incremental = FALSE
)

# Combine across modules -------------------------------------------------------
analysisSpecifications <- Strategus::createEmptyAnalysisSpecificiations() |>
  Strategus::addSharedResources(cohortDefinitionShared) |> 
  Strategus::addModuleSpecifications(cohortGeneratorModuleSpecifications) |>
  Strategus::addModuleSpecifications(cdModuleSpecifications)

if (!dir.exists(rootFolder)) {
  dir.create(rootFolder, recursive = TRUE)
}
ParallelLogger::saveSettingsToJson(analysisSpecifications, file.path(rootFolder, "inst/cohortDiagnosticsAnalysisSpecification.json"))