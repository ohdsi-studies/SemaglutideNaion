source("extras/RenvHelpers.R")
lf <- compareLockFiles(
  filename1 = "D:/git/ohdsi-studies/SemaglutideNaion/renv.lock",
  filename2 = "D:/git/ohdsi-studies/SemaglutideNaion/extras/cd-renv.lock"
)

# Loop through and record the versions of any missing packages
for(i in 1:nrow(lf)) {
  if (is.na(lf$lockfile1Version[i]) && !is.na(lf$lockfile2Version[i])) {
    print(lf$lockfile1Name[i])
    if (lf$lockfile2Source[i] == "Repository") {
      item <- list(
        Package = lf$lockfile1Name[i],
        Version = lf$lockfile2Version[i],
        Source = "Repository",
        Repository = "CRAN"
      )
      packageToRecord <- list()
      packageToRecord[[lf$lockfile1Name[i]]] <- item
      renv::record(packageToRecord, lockfile = "D:/git/ohdsi-studies/SemaglutideNaion/renv.lock")
    } else {
      renv::record(paste0("OHDSI/", lf$lockfile1Name[i], "@v", lf$lockfile2Version[i]))
    }
  }
}

# Manually set some package versions
# Notes: 
# - FeatureExtraction < 3.6 needed to not break Characterization v0.2.0
# - CohortIncidence v3.3.1 and Characterization v0.2.0 used for compatibility w/ Shiny results viewer
updatedPackages <- list(
  list(
    Package = "FeatureExtraction",
    Version = "3.5.2",
    Source = "Repository",
    Repository = "CRAN"
  ),
  list(
    Package = "Cyclops",
    Version = "3.4.1",
    Source = "Repository",
    Repository = "CRAN"
  ),
  list(
    Package = "SqlRender",
    Version = "1.18.0",
    Source = "Repository",
    Repository = "CRAN"
  ),
  "OHDSI/Characterization@v0.2.0",
  "OHDSI/CohortDiagnostics@v3.2.5",
  "OHDSI/CohortGenerator@v0.10.0",
  "OHDSI/CohortIncidence@v3.3.1",
  "OHDSI/CohortMethod@v5.3.0",
  "OHDSI/SelfControlledCaseSeries@v5.2.2",
  "OHDSI/ResultModelManager@v0.5.8",
  "OHDSI/Strategus@4b90144536941c290b75f6e81ac1ec0d44a9738c",
  "OHDSI/OhdsiSharing"
)
renv::record(updatedPackages)