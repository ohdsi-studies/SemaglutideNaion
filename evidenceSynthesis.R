library(dplyr)
library(Strategus)
outputLocation <- 'D:/git/ohdsi-studies/SemaglutideNaion'

# Specify the connection to the results database
resultsConnectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = 'postgresql', 
  user = keyring::key_get("OHDSI_RESULTS_USER"),
  password = keyring::key_get("OHDSI_RESULTS_PASSWORD"),
  server = keyring::key_get("OHDSI_RESULTS_SERVER")
)

esModuleSettingsCreator = EvidenceSynthesisModule$new()
evidenceSynthesisSourceCm <- esModuleSettingsCreator$createEvidenceSynthesisSource(
  sourceMethod = "CohortMethod",
  likelihoodApproximation = "adaptive grid"
)
metaAnalysisCm <- esModuleSettingsCreator$createBayesianMetaAnalysis(
  evidenceSynthesisAnalysisId = 1,
  alpha = 0.05,
  evidenceSynthesisDescription = "Bayesian random-effects alpha 0.05 - adaptive grid",
  evidenceSynthesisSource = evidenceSynthesisSourceCm
)
evidenceSynthesisSourceSccs <- esModuleSettingsCreator$createEvidenceSynthesisSource(
  sourceMethod = "SelfControlledCaseSeries",
  likelihoodApproximation = "adaptive grid"
)
metaAnalysisSccs <- esModuleSettingsCreator$createBayesianMetaAnalysis(
  evidenceSynthesisAnalysisId = 2,
  alpha = 0.05,
  evidenceSynthesisDescription = "Bayesian random-effects alpha 0.05 - adaptive grid",
  evidenceSynthesisSource = evidenceSynthesisSourceSccs
)
evidenceSynthesisAnalysisList <- list(metaAnalysisCm, metaAnalysisSccs)
evidenceSynthesisAnalysisSpecifications <- esModuleSettingsCreator$createModuleSpecifications(
  evidenceSynthesisAnalysisList
)
esAnalysisSpecifications <- Strategus::createEmptyAnalysisSpecificiations() |>
  Strategus::addModuleSpecifications(evidenceSynthesisAnalysisSpecifications)

if (!dir.exists(outputLocation)) {
  dir.create(outputLocation, recursive = TRUE)
}
ParallelLogger::saveSettingsToJson(esAnalysisSpecifications, file.path(outputLocation, "inst/esAnalysisSpecification.json"))


resultsExecutionSettings <- Strategus::createResultsExecutionSettings(
  resultsDatabaseSchema = "semanaion",
  resultsFolder = file.path(outputLocation, "results", "evidence_sythesis", "results_folder"),
  workFolder = file.path(outputLocation, "results", "evidence_sythesis", "work_folder")
)

Strategus::execute(
  analysisSpecifications = esAnalysisSpecifications,
  executionSettings = resultsExecutionSettings,
  connectionDetails = resultsConnectionDetails
)

resultsDataModelSettings <- Strategus::createResultsDataModelSettings(
  resultsDatabaseSchema = "semanaion",
  resultsFolder = resultsExecutionSettings$resultsFolder,
)

Strategus::createResultDataModel(
  analysisSpecifications = esAnalysisSpecifications,
  resultsDataModelSettings = resultsDataModelSettings,
  resultsConnectionDetails = resultsConnectionDetails
)

Strategus::uploadResults(
  analysisSpecifications = esAnalysisSpecifications,
  resultsDataModelSettings = resultsDataModelSettings,
  resultsConnectionDetails = resultsConnectionDetails
)
