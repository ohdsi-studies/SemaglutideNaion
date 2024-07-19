library(dplyr)
library(Strategus)
rootFolder <- "D:/git/ohdsi-studies/SemaglutideNaion"


# Get the list of cohorts
cohortDefinitionSet <- CohortGenerator::getCohortDefinitionSet(
  settingsFileName = "inst/Cohorts.csv",
  jsonFolder = "inst/cohorts",
  sqlFolder = "inst/sql/sql_server",
  cohortFileNameFormat = "%s_%s",
  cohortFileNameValue = c("cohortId", "cohortName")
)

# Get the design assets
cmTcList <- CohortGenerator::readCsv("inst/cmTcList.csv")
sccsTList <- CohortGenerator::readCsv("inst/sccsTList.csv")
sccsIList <- CohortGenerator::readCsv("inst/sccsIList.csv")
oList <- CohortGenerator::readCsv("inst/oList.csv")
ncoList <- CohortGenerator::readCsv("inst/negativeControlOutcomes.csv")
excludedCovariateConcepts <- CohortGenerator::readCsv("inst/excludedCovariateConcepts.csv")

# tcis <- list(
#   list(
#     targetId = 1782488, # fluoroquinalone
#     comparatorId = 1782487, # cephalosporin
#     indicationId = 1782485, # urinary tract infection
#     genderConceptIds = c(8507, 8532), # use valid genders (remove unknown)
#     minAge = 35, # All ages In years. Can be NULL
#     maxAge = NULL, # All ages In years. Can be NULL
#     excludedCovariateConceptIds = c(
#       923081, 1592954,1707800, 1712549, 1716721, 1716903, 1721543, 1733765, 1742253, 1743222, 1747032, 1789276, 1797513, 19027679, 19041153, 19050750, 35197897, 35197938, 35198003, 35198165, 35834909, 36878831, 40161662, 43009030, # fluoroquinalone
#       40798709,1768849,1769535,19070174,19070680,40798700,1771162,43009082,43009044,1796458,1747005,19028241,1796435,40798704,19072255,43008993,19028286,19072857,1773402,19028288,1774470,1774932,19051271,1775741,43009045,1749008,1738366,43009083,19051345,1776684,35198137,43008994,1749083,1777254,1777806,1778162,1786621,19052683,19086759,19086790,1786842,43009087,1708100,19126622 # cephalosporin
#     ) 
#   ),
#   list(
#     targetId = 1782488, # fluoroquinalone
#     comparatorId = 1782670, # trimethoprim
#     indicationId = 1782485, # urinary tract infection
#     genderConceptIds = c(8507, 8532), # use valid genders (remove unknown)
#     minAge = 35, # All ages In years. Can be NULL
#     maxAge = NULL, # All ages In years. Can be NULL
#     excludedCovariateConceptIds = c(
#       923081, 1592954,1707800, 1712549, 1716721, 1716903, 1721543, 1733765, 1742253, 1743222, 1747032, 1789276, 1797513, 19027679, 19041153, 19050750, 35197897, 35197938, 35198003, 35198165, 35834909, 36878831, 40161662, 43009030, # fluoroquinalone
#       1705674, # trimethoprim
#       1836430 # sulfamethoxazole
#     ) 
#   )
# )
# outcomes <- tibble(
#   cohortId = c(1782671, 1782672, 1782489), # AA, AD, AA or AD
#   cleanWindow = c(365, 365, 365)
# )
# negativeConceptSetId <- 1873446  #candidate controls for antibiotics 
timeAtRisks <- tibble(
  label = c("On treatment"),
  riskWindowStart  = c(1),
  startAnchor = c("cohort start"),
  riskWindowEnd  = c(0),
  endAnchor = c("cohort end")
)
# # Try to avoid intent-to-treat TARs for SCCS, or then at least disable calendar time spline:
# sccsTimeAtRisks <- tibble(
#   label = c("30d fixed window", "60d fixed window", "90d fixed window", "365d fixed window"),
#   riskWindowStart  = c(1, 1, 1, 1),
#   startAnchor = c("cohort start", "cohort start", "cohort start", "cohort start"),
#   riskWindowEnd  = c(30, 60, 90, 365),
#   endAnchor = c("cohort start", "cohort start", "cohort start", "cohort start"),
# )
# # Try to use fixed-time TARs for patient-level prediction:
# plpTimeAtRisks <- tibble(
#   riskWindowStart  = c(1, 1, 1, 1),
#   startAnchor = c("cohort start", "cohort start", "cohort start", "cohort start"),
#   riskWindowEnd  = c(30, 60, 90, 365),
#   endAnchor = c("cohort start", "cohort start", "cohort start", "cohort start"),
# )
studyStartDate <- '20171201' #YYYYMMDD
studyEndDate <- '20231231'   #YYYYMMDD

# Probably don't change below this line ----------------------------------------

useCleanWindowForPriorOutcomeLookback <- FALSE # If FALSE, lookback window is all time prior, i.e., including only first events
psMatchMaxRatio <- 1 # If bigger than 1, the outcome model will be conditioned on the matched set

# Don't change below this line (unless you know what you're doing) -------------


# Shared Resources -------------------------------------------------------------
cgModuleSettingsCreator <- CohortGeneratorModule$new()
negativeControlOutcomeCohortSet <- ncoList %>%
  rename(cohortName = "conceptname") %>%
  mutate(cohortId = row_number() + 1000)


# # Get the unique subset criteria from the tcis
# # object to construct the cohortDefintionSet's 
# # subset definitions for each target/comparator
# # cohort
# dfUniqueTcis <- data.frame()
# for (i in seq_along(tcis)) {
#   dfUniqueTcis <- rbind(dfUniqueTcis, data.frame(cohortId = tcis[[i]]$targetId,
#                                                  indicationId = paste(tcis[[i]]$indicationId, collapse = ","),
#                                                  genderConceptIds = paste(tcis[[i]]$genderConceptIds, collapse = ","),
#                                                  minAge = paste(tcis[[i]]$minAge, collapse = ","),
#                                                  maxAge = paste(tcis[[i]]$maxAge, collapse = ",")
#   ))
#   dfUniqueTcis <- rbind(dfUniqueTcis, data.frame(cohortId = tcis[[i]]$comparatorId,
#                                                  indicationId = paste(tcis[[i]]$indicationId, collapse = ","),
#                                                  genderConceptIds = paste(tcis[[i]]$genderConceptIds, collapse = ","),
#                                                  minAge = paste(tcis[[i]]$minAge, collapse = ","),
#                                                  maxAge = paste(tcis[[i]]$maxAge, collapse = ",")
#   ))
# }
# 
# dfUniqueTcis <- unique(dfUniqueTcis)
# dfUniqueTcis$subsetDefinitionId <- 0 # Adding as a placeholder for loop below
# dfUniqueSubsetCriteria <- unique(dfUniqueTcis[,-1])
# 
# for (i in 1:nrow(dfUniqueSubsetCriteria)) {
#   uniqueSubsetCriteria <- dfUniqueSubsetCriteria[i,]
#   dfCurrentTcis <- dfUniqueTcis[dfUniqueTcis$indicationId == uniqueSubsetCriteria$indicationId &
#                                   dfUniqueTcis$genderConceptIds == uniqueSubsetCriteria$genderConceptIds &
#                                   dfUniqueTcis$minAge == uniqueSubsetCriteria$minAge & 
#                                   dfUniqueTcis$maxAge == uniqueSubsetCriteria$maxAge,]
#   targetCohortIdsForSubsetCriteria <- as.integer(dfCurrentTcis[, "cohortId"])
#   dfUniqueTcis <- dfUniqueTcis %>%
#     inner_join(dfCurrentTcis) %>%
#     mutate(subsetDefinitionId = i)
#     
#   subsetOperators <- list()
#   if (uniqueSubsetCriteria$indicationId != "") {
#     subsetOperators[[length(subsetOperators) + 1]] <- CohortGenerator::createCohortSubset(
#       cohortIds = uniqueSubsetCriteria$indicationId,
#       negate = FALSE,
#       cohortCombinationOperator = "all",
#       startWindow = CohortGenerator::createSubsetCohortWindow(-99999, 0, "cohortStart"),
#       endWindow = CohortGenerator::createSubsetCohortWindow(-99999, 99999, "cohortStart")
#     )
#   }
#   subsetOperators[[length(subsetOperators) + 1]] <- CohortGenerator::createLimitSubset(
#     priorTime = 365,
#     followUpTime = 1,
#     limitTo = "firstEver"
#   )
#   if (uniqueSubsetCriteria$genderConceptIds != "" ||
#       uniqueSubsetCriteria$minAge != "" ||
#       uniqueSubsetCriteria$maxAge != "") {
#     subsetOperators[[length(subsetOperators) + 1]] <- CohortGenerator::createDemographicSubset(
#       ageMin = if(uniqueSubsetCriteria$minAge == "") 0 else as.integer(uniqueSubsetCriteria$minAge),
#       ageMax = if(uniqueSubsetCriteria$maxAge == "") 99999 else as.integer(uniqueSubsetCriteria$maxAge),
#       gender = if(uniqueSubsetCriteria$genderConceptIds == "") NULL else as.integer(strsplit(uniqueSubsetCriteria$genderConceptIds, ",")[[1]])
#     )
#   }
#   if (studyStartDate != "" || studyEndDate != "") {
#     subsetOperators[[length(subsetOperators) + 1]] <- CohortGenerator::createLimitSubset(
#       calendarStartDate = if (studyStartDate == "") NULL else as.Date(studyStartDate, "%Y%m%d"),
#       calendarEndDate = if (studyEndDate == "") NULL else as.Date(studyEndDate, "%Y%m%d")
#     )
#   }
#   subsetDef <- CohortGenerator::createCohortSubsetDefinition(
#     name = "",
#     definitionId = i,
#     subsetOperators = subsetOperators
#   )
#   cohortDefinitionSet <- cohortDefinitionSet %>%
#     CohortGenerator::addCohortSubsetDefinition(
#       cohortSubsetDefintion = subsetDef,
#       targetCohortIds = targetCohortIdsForSubsetCriteria
#     ) 
#   
#   if (!is.null(uniqueSubsetCriteria$indicationId)) {
#     # Also create restricted version of indication cohort:
#     subsetDef <- CohortGenerator::createCohortSubsetDefinition(
#       name = "",
#       definitionId = i + 100,
#       subsetOperators = subsetOperators[2:length(subsetOperators)]
#     )
#     cohortDefinitionSet <- cohortDefinitionSet %>%
#       CohortGenerator::addCohortSubsetDefinition(
#         cohortSubsetDefintion = subsetDef,
#         targetCohortIds = as.integer(uniqueSubsetCriteria$indicationId)
#       )
#   }  
# }

# CohortGeneratorModule --------------------------------------------------------
if (any(duplicated(cohortDefinitionSet$cohortId, negativeControlOutcomeCohortSet$cohortId))) {
  stop("*** Error: duplicate cohort IDs found ***")
}
cohortDefinitionShared <- cgModuleSettingsCreator$createCohortSharedResourceSpecifications(cohortDefinitionSet)
negativeControlsShared <- cgModuleSettingsCreator$createNegativeControlOutcomeCohortSharedResourceSpecifications(
  negativeControlOutcomeCohortSet = negativeControlOutcomeCohortSet,
  occurrenceType = "first",
  detectOnDescendants = TRUE
)
cohortGeneratorModuleSpecifications <- cgModuleSettingsCreator$createModuleSpecifications(
  incremental = TRUE,
  generateStats = TRUE
)

# CharacterizationModule Settings ---------------------------------------------
cModuleSettingsCreator <- CharacterizationModule$new()
characterizationModuleSpecifications <- cModuleSettingsCreator$createModuleSpecifications(
  targetIds = cohortDefinitionSet$cohortId, # NOTE: This is all T/C/I/O
  outcomeIds = oList$outcomeCohortId,
  dechallengeStopInterval = 30,
  dechallengeEvaluationWindow = 30,
  timeAtRisk = timeAtRisks,
  minPriorObservation = 365,
  covariateSettings = FeatureExtraction::createDefaultCovariateSettings()
)


# CohortIncidenceModule --------------------------------------------------------
ciModuleSettingsCreator <- CohortIncidenceModule$new()
tciIds <- cohortDefinitionSet %>%
  filter(!cohortId %in% oList$outcomeCohortId) %>%
  pull(cohortId)
targetList <- lapply(
  tciIds,
  function(cohortId) {
    CohortIncidence::createCohortRef(
      id = cohortId, 
      name = cohortDefinitionSet$cohortName[cohortDefinitionSet$cohortId == cohortId]
    )
  }
)
outcomeList <- lapply(
  seq_len(nrow(oList)),
  function(i) {
    CohortIncidence::createOutcomeDef(
      id = i, 
      name = cohortDefinitionSet$cohortName[cohortDefinitionSet$cohortId == oList$outcomeCohortId[i]], 
      cohortId = oList$outcomeCohortId[i], 
      cleanWindow = oList$cleanWindow[i]
    )
  }
)
tars <- list()
for (i in seq_len(nrow(timeAtRisks))) {
  tars[[i]] <- CohortIncidence::createTimeAtRiskDef(
    id = i, 
    startWith = gsub("cohort ", "", timeAtRisks$startAnchor[i]), 
    endWith = gsub("cohort ", "", timeAtRisks$endAnchor[i]), 
    startOffset = timeAtRisks$riskWindowStart[i],
    endOffset = timeAtRisks$riskWindowEnd[i]
  )
}
analysis1 <- CohortIncidence::createIncidenceAnalysis(
  targets = tciIds,
  outcomes = seq_len(nrow(oList)),
  tars = seq_along(tars)
)
# NOTE: Do we want 10 year age breaks?
irDesign <- CohortIncidence::createIncidenceDesign(
  targetDefs = targetList,
  outcomeDefs = outcomeList,
  tars = tars,
  analysisList = list(analysis1),
  strataSettings = CohortIncidence::createStrataSettings(
    byYear = TRUE,
    byGender = TRUE,
    byAge = TRUE,
    ageBreaks = seq(0, 110, by = 10)
  )
)
cohortIncidenceModuleSpecifications <- ciModuleSettingsCreator$createModuleSpecifications(
  irDesign = irDesign$toList()
)


# CohortMethodModule -----------------------------------------------------------
cmModuleSettingsCreator <- CohortMethodModule$new()
covariateSettings <- FeatureExtraction::createDefaultCovariateSettings(
  addDescendantsToExclude = TRUE # Keep TRUE because you're excluding concepts
)
outcomeList <- append(
  lapply(seq_len(nrow(oList)), function(i) {
    if (useCleanWindowForPriorOutcomeLookback)
      priorOutcomeLookback <- oList$cleanWindow[i]
    else
      priorOutcomeLookback <- 99999
    CohortMethod::createOutcome(
      outcomeId = oList$outcomeCohortId[i],
      outcomeOfInterest = TRUE,
      trueEffectSize = NA,
      priorOutcomeLookback = priorOutcomeLookback
    )
  }),
  lapply(negativeControlOutcomeCohortSet$cohortId, function(i) {
    CohortMethod::createOutcome(
      outcomeId = i,
      outcomeOfInterest = FALSE,
      trueEffectSize = 1
    )
  })
)
targetComparatorOutcomesList <- list()
for (i in seq_along(cmTcList)) {
  targetComparatorOutcomesList[[i]] <- CohortMethod::createTargetComparatorOutcomes(
    targetId = cmTcList$targetCohortId[i],
    comparatorId = cmTcList$comparatorCohortId[i],
    outcomes = outcomeList,
    excludedCovariateConceptIds = c(
      cmTcList$targetConceptId[i], 
      cmTcList$comparatorConceptId[i],
      excludedCovariateConcepts$conceptId
    )
  )
}
getDbCohortMethodDataArgs <- CohortMethod::createGetDbCohortMethodDataArgs(
  restrictToCommonPeriod = TRUE,
  studyStartDate = studyStartDate,
  studyEndDate = studyEndDate,
  maxCohortSize = 0,
  covariateSettings = covariateSettings
)
createPsArgs = CohortMethod::createCreatePsArgs(
  maxCohortSizeForFitting = 250000,
  errorOnHighCorrelation = TRUE,
  stopOnError = FALSE, # Setting to FALSE to allow Strategus complete all CM operations; when we cannot fit a model, the equipoise diagnostic should fail
  estimator = "att",
  prior = Cyclops::createPrior(
    priorType = "laplace", 
    exclude = c(0), 
    useCrossValidation = TRUE
  ),
  control = Cyclops::createControl(
    noiseLevel = "silent", 
    cvType = "auto", 
    seed = 1, 
    resetCoefficients = TRUE, 
    tolerance = 2e-07, 
    cvRepetitions = 10, 
    startingVariance = 0.01
  )
)
matchOnPsArgs = CohortMethod::createMatchOnPsArgs(
  maxRatio = psMatchMaxRatio,
  caliper = 0.2,
  caliperScale = "standardized logit",
  allowReverseMatch = FALSE,
  stratificationColumns = c()
)
# stratifyByPsArgs <- CohortMethod::createStratifyByPsArgs(
#   numberOfStrata = 5,
#   stratificationColumns = c(),
#   baseSelection = "all"
# )
computeSharedCovariateBalanceArgs = CohortMethod::createComputeCovariateBalanceArgs(
  maxCohortSize = 250000,
  covariateFilter = NULL
)
computeCovariateBalanceArgs = CohortMethod::createComputeCovariateBalanceArgs(
  maxCohortSize = 250000,
  covariateFilter = FeatureExtraction::getDefaultTable1Specifications()
)
fitOutcomeModelArgs = CohortMethod::createFitOutcomeModelArgs(
  modelType = "cox",
  stratified = psMatchMaxRatio != 1,
  useCovariates = FALSE,
  inversePtWeighting = FALSE,
  prior = Cyclops::createPrior(
    priorType = "laplace", 
    useCrossValidation = TRUE
  ),
  control = Cyclops::createControl(
    cvType = "auto", 
    seed = 1, 
    resetCoefficients = TRUE,
    startingVariance = 0.01, 
    tolerance = 2e-07, 
    cvRepetitions = 10, 
    noiseLevel = "quiet"
  )
)
cmAnalysisList <- list()
for (i in seq_len(nrow(timeAtRisks))) {
  createStudyPopArgs <- CohortMethod::createCreateStudyPopulationArgs(
    firstExposureOnly = FALSE,
    washoutPeriod = 0,
    removeDuplicateSubjects = "keep first",
    censorAtNewRiskWindow = TRUE,
    removeSubjectsWithPriorOutcome = TRUE,
    priorOutcomeLookback = 99999,
    riskWindowStart = timeAtRisks$riskWindowStart[[i]],
    startAnchor = timeAtRisks$startAnchor[[i]],
    riskWindowEnd = timeAtRisks$riskWindowEnd[[i]],
    endAnchor = timeAtRisks$endAnchor[[i]],
    minDaysAtRisk = 1,
    maxDaysAtRisk = 99999
  )
  cmAnalysisList[[i]] <- CohortMethod::createCmAnalysis(
    analysisId = i,
    description = sprintf(
      "Cohort method, %s",
      timeAtRisks$label[i]
    ),
    getDbCohortMethodDataArgs = getDbCohortMethodDataArgs,
    createStudyPopArgs = createStudyPopArgs,
    createPsArgs = createPsArgs,
    matchOnPsArgs = matchOnPsArgs,
    # stratifyByPsArgs = stratifyByPsArgs,
    computeSharedCovariateBalanceArgs = computeSharedCovariateBalanceArgs,
    computeCovariateBalanceArgs = computeCovariateBalanceArgs,
    fitOutcomeModelArgs = fitOutcomeModelArgs
  )
}
cohortMethodModuleSpecifications <- cmModuleSettingsCreator$createModuleSpecifications(
  cmAnalysisList = cmAnalysisList,
  targetComparatorOutcomesList = targetComparatorOutcomesList,
  analysesToExclude = NULL,
  refitPsForEveryOutcome = FALSE,
  refitPsForEveryStudyPopulation = FALSE,  
  cmDiagnosticThresholds = CohortMethod::createCmDiagnosticThresholds(
    mdrrThreshold = Inf,
    easeThreshold = 0.25,
    sdmThreshold = 0.1,
    equipoiseThreshold = 0.2,
    generalizabilitySdmThreshold = 1 # NOTE using default here
  )
)


# SelfControlledCaseSeriesmodule -----------------------------------------------
sccsModuleSettingsCreator <- SelfControlledCaseSeriesModule$new()

# uniqueTargetIndications <- lapply(sccsTList,
#                                   function(x) data.frame(
#                                     exposureId = x,
#                                     indicationId = sccsIList$indicationCohortId,
#                                     genderConceptIds = c(8507, 8532),
#                                     minAge = 18,
#                                     maxAge = NA
#                                   )) %>%
#   bind_rows() %>%
#   distinct()

uniqueTargetIds <- sccsTList$targetCohortId

eoList <- list()
for (targetId in uniqueTargetIds) {
  for (outcomeId in oList$outcomeCohortId) {
    eoList[[length(eoList) + 1]] <- SelfControlledCaseSeries::createExposuresOutcome(
      outcomeId = outcomeId,
      exposures = list(
        SelfControlledCaseSeries::createExposure(
          exposureId = targetId,
          trueEffectSize = NA
        )
      )
    )
  }
  for (outcomeId in negativeControlOutcomeCohortSet$cohortId) {
    eoList[[length(eoList) + 1]] <- SelfControlledCaseSeries::createExposuresOutcome(
      outcomeId = outcomeId,
      exposures = list(SelfControlledCaseSeries::createExposure(
        exposureId = targetId, 
        trueEffectSize = 1
      ))
    )
  }
}
sccsAnalysisList <- list()
analysisToInclude <- data.frame()
for (i in seq_len(nrow(sccsIList))) {
  indicationId <- sccsIList$indicationCohortId[i]
  getDbSccsDataArgs <- SelfControlledCaseSeries::createGetDbSccsDataArgs(
    maxCasesPerOutcome = 1000000,
    useNestingCohort = TRUE,
    nestingCohortId = indicationId,
    studyStartDate = studyStartDate,
    studyEndDate = studyEndDate,
    deleteCovariatesSmallCount = 0
  )
  createStudyPopulationArgs = SelfControlledCaseSeries::createCreateStudyPopulationArgs(
    firstOutcomeOnly = TRUE,
    naivePeriod = 365,
    minAge = 18,
    genderConceptIds = c(8507, 8532)
  )
  covarPreExp <- SelfControlledCaseSeries::createEraCovariateSettings(
    label = "Pre-exposure",
    includeEraIds = "exposureId",
    start = -30,
    startAnchor = "era start",
    end = -1,
    endAnchor = "era start",
    firstOccurrenceOnly = FALSE,
    allowRegularization = FALSE,
    profileLikelihood = FALSE,
    exposureOfInterest = FALSE
  )
  calendarTimeSettings <- SelfControlledCaseSeries::createCalendarTimeCovariateSettings(
    calendarTimeKnots = 5,
    allowRegularization = TRUE,
    computeConfidenceIntervals = FALSE
  )
  # seasonalitySettings <- SelfControlledCaseSeries:createSeasonalityCovariateSettings(
  #   seasonKnots = 5,
  #   allowRegularization = TRUE,
  #   computeConfidenceIntervals = FALSE
  # )
  fitSccsModelArgs <- SelfControlledCaseSeries::createFitSccsModelArgs(
    prior = Cyclops::createPrior("laplace", useCrossValidation = TRUE), 
    control = Cyclops::createControl(
      cvType = "auto", 
      selectorType = "byPid", 
      startingVariance = 0.1, 
      seed = 1, 
      resetCoefficients = TRUE, 
      noiseLevel = "quiet")
  )
  for (j in seq_len(nrow(timeAtRisks))) {
    covarExposureOfInt <- SelfControlledCaseSeries::createEraCovariateSettings(
      label = "Main",
      includeEraIds = "exposureId",
      start = timeAtRisks$riskWindowStart[j],
      startAnchor = gsub("cohort", "era", timeAtRisks$startAnchor[j]),
      end = timeAtRisks$riskWindowEnd[j],
      endAnchor = gsub("cohort", "era", timeAtRisks$endAnchor[j]),
      firstOccurrenceOnly = FALSE,
      allowRegularization = FALSE,
      profileLikelihood = TRUE,
      exposureOfInterest = TRUE
    )
    createSccsIntervalDataArgs <- SelfControlledCaseSeries::createCreateSccsIntervalDataArgs(
      eraCovariateSettings = list(covarPreExp, covarExposureOfInt),
      # seasonalityCovariateSettings = seasonalityCovariateSettings,
      calendarTimeCovariateSettings = calendarTimeSettings
    )
    description <- "SCCS"
    description <- sprintf("%s, having %s - male, female, age >= %s", description, cohortDefinitionSet %>% 
                             filter(cohortId == indicationId) %>%
                             pull(cohortName), createStudyPopulationArgs$minAge)
    description <- sprintf("%s, %s", description, timeAtRisks$label[j])
    sccsAnalysisList[[length(sccsAnalysisList) + 1]] <- SelfControlledCaseSeries::createSccsAnalysis(
      analysisId = length(sccsAnalysisList) + 1,
      description = description,
      getDbSccsDataArgs = getDbSccsDataArgs,
      createStudyPopulationArgs = createStudyPopulationArgs,
      createIntervalDataArgs = createSccsIntervalDataArgs,
      fitSccsModelArgs = fitSccsModelArgs
    )
  }
}
selfControlledModuleSpecifications <- sccsModuleSettingsCreator$createModuleSpecifications(
  sccsAnalysisList = sccsAnalysisList,
  exposuresOutcomeList = eoList,
  combineDataFetchAcrossOutcomes = FALSE,
  sccsDiagnosticThresholds = SelfControlledCaseSeries::createSccsDiagnosticThresholds(
    mdrrThreshold = 10,
    easeThreshold = 0.25,
    timeTrendPThreshold = 0.05,
    preExposurePThreshold = 0.05
  )
)

# Combine across modules -------------------------------------------------------
analysisSpecifications <- Strategus::createEmptyAnalysisSpecificiations() |>
  Strategus::addSharedResources(cohortDefinitionShared) |> 
  Strategus::addSharedResources(negativeControlsShared) |>
  Strategus::addModuleSpecifications(cohortGeneratorModuleSpecifications) |>
  Strategus::addModuleSpecifications(characterizationModuleSpecifications) %>%
  Strategus::addModuleSpecifications(cohortIncidenceModuleSpecifications) %>%
  Strategus::addModuleSpecifications(cohortMethodModuleSpecifications) %>%
  Strategus::addModuleSpecifications(selfControlledModuleSpecifications)

if (!dir.exists(rootFolder)) {
  dir.create(rootFolder, recursive = TRUE)
}
ParallelLogger::saveSettingsToJson(analysisSpecifications, file.path(rootFolder, "inst/analysisSpecification.json"))