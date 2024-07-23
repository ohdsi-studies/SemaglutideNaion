# Read the list of cohorts needed for the study from the spreadsheet
cmTcList <- openxlsx::read.xlsx(file.path("extras", "semaNAION cohort inputs.xlsx"), sheet = 1)
sccsTList <- openxlsx::read.xlsx(file.path("extras", "semaNAION cohort inputs.xlsx"), sheet = 2)
sccsIList <- openxlsx::read.xlsx(file.path("extras", "semaNAION cohort inputs.xlsx"), sheet = 3)
oList <- openxlsx::read.xlsx(file.path("extras", "semaNAION cohort inputs.xlsx"), sheet = 4)
ncoList <- openxlsx::read.xlsx(file.path("extras", "semaNAION cohort inputs.xlsx"), sheet = 5)

names(cmTcList) <- SqlRender::snakeCaseToCamelCase(names(cmTcList))
names(sccsTList) <- SqlRender::snakeCaseToCamelCase(names(sccsTList))
names(sccsIList) <- SqlRender::snakeCaseToCamelCase(names(sccsIList))
names(oList) <- SqlRender::snakeCaseToCamelCase(names(oList))
names(ncoList) <- SqlRender::snakeCaseToCamelCase(names(ncoList))


# Download the cohorts for the study project
baseUrl <- keyring::key_get("WEBAPI_URL_EPI_PROD")


ROhdsiWebApi::authorizeWebApi(
  baseUrl = baseUrl,
  authMethod = "windows"
)
cohortDefinitionSet <- ROhdsiWebApi::exportCohortDefinitionSet(
  cohortIds =  unique(
    c(
      cmTcList$targetCohortId,
      cmTcList$comparatorCohortId,
      sccsTList$targetCohortId,
      sccsIList$indicationCohortId,
      oList$outcomeCohortId
    )
  ),
  generateStats = TRUE,
  baseUrl = baseUrl
)

# Remove the study prefix from the cohort names
cohortDefinitionSet$cohortName <- gsub("^\\[semaNAION\\] ", "", cohortDefinitionSet$cohortName)
cmTcList$targetCohortName <- gsub("^\\[semaNAION\\] ", "", cmTcList$targetCohortName)
cmTcList$comparatorCohortName <- gsub("^\\[semaNAION\\] ", "", cmTcList$comparatorCohortName)
sccsTList$targetCohortName <- gsub("^\\[semaNAION\\] ", "", sccsTList$targetCohortName)
sccsIList$indicationCohortName <- gsub("^\\[semaNAION\\] ", "", sccsIList$indicationCohortName)
oList$outcomeCohortName <- gsub("^\\[semaNAION\\] ", "", oList$outcomeCohortName)

# Save the cohort definition set for the study
CohortGenerator::saveCohortDefinitionSet(
  cohortDefinitionSet = cohortDefinitionSet,
  cohortFileNameFormat = "%s_%s",
  cohortFileNameValue = c("cohortId", "cohortName")
)

# Save the list of negative control outcomes
CohortGenerator::writeCsv(
  x = ncoList,
  file = file.path("inst", "negativeControlOutcomes.csv"),
  warnOnFileNameCaseMismatch = F
)

# Save the other study design assets that we need for
# creating the analysis specification
CohortGenerator::writeCsv(
  x = cmTcList,
  file = file.path("inst", "cmTcList.csv"),
  warnOnFileNameCaseMismatch = F
)

CohortGenerator::writeCsv(
  x = sccsTList,
  file = file.path("inst", "sccsTList.csv"),
  warnOnFileNameCaseMismatch = F
)

CohortGenerator::writeCsv(
  x = sccsIList,
  file = file.path("inst", "sccsIList.csv"),
  warnOnFileNameCaseMismatch = F
)

CohortGenerator::writeCsv(
  x = oList,
  file = file.path("inst", "oList.csv"),
  warnOnFileNameCaseMismatch = F
)

# Download Concept Sets