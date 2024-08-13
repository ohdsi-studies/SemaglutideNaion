Estimation of risk of NAION and other vision disorders from exposure to semaglutide
=============

<img src="https://img.shields.io/badge/Study%20Status-Started-blue.svg" alt="Study Status: Started">

- Analytics use case(s): **Population-Level Estimation**
- Study type: **Clinical Application**
- Tags: **Eye Care & Vision Research, Type 2 Diabetes**
- Study lead: **Cindy X. Cai**
- Study lead forums tag: **[[Cindy X. Cai]](https://forums.ohdsi.org/u/cindyxcai)**
- Study start date: **-**
- Study end date: **-**
- Protocol: **<a href="docs/Protocol.html">HTML Document</a>**
- Publications: **-**
- Results explorer: **-**

OHDSI network study for population-level effect estimation of risk of NAION and other vision disorders from exposure to semaglutide.

# How to run the study

The following instructions will guide you through the process of setting
up your system to run this network study.

## System setup and configuration

Start by making sure your R environment is set up by following the instructions
on the [OHDSI HADES R Setup site](https://ohdsi.github.io/Hades/rSetup.html). 
Be sure to install R, RTools, RStudio and Java. Next, verify that you can
properly connect from R to your OMOP CDM via DatabaseConnector per the instructions
[here](https://ohdsi.github.io/Hades/connecting.html#Configuring_your_connection) and
[here](https://ohdsi.github.io/DatabaseConnector/articles/Connecting.html).

Once you have installed the tools mentioned above and confirmed database
connectivity via R, you are ready to take the next step.

## Download the study package

To get started, you will want to download the study code in this repository
to your local machine. Instructions for downloading are found [here](https://docs.github.com/en/repositories/working-with-files/using-files/downloading-source-code-archives#downloading-source-code-archives-from-the-repository-view). In this guide, we will assume that you have
downloaded the .ZIP archive to **`D:/git/ohdsi-studies/SemaglutideNaion`.**

## Restore the execution environment

[Use RStudio to open the project file](https://support.posit.co/hc/en-us/articles/200526207-Using-RStudio-Projects#:~:text=There%20are%20several%20ways%20to,Rproj).) `SemaglutideNaion.Rproj` which is found in 
the root directory of `D:/git/ohdsi-studies/SemaglutideNaion` (or wherever
you opted to download the study package). When you open the project, you will
see the following:

```r
R version 4.2.3 (2023-03-15 ucrt) -- "Shortstop Beagle"
Copyright (C) 2023 The R Foundation for Statistical Computing
Platform: x86_64-w64-mingw32/x64 (64-bit)

R is free software and comes with ABSOLUTELY NO WARRANTY.
You are welcome to redistribute it under certain conditions.
Type 'license()' or 'licence()' for distribution details.

  Natural language support but running in an English locale

R is a collaborative project with many contributors.
Type 'contributors()' for more information and
'citation()' on how to cite R or R packages in publications.

Type 'demo()' for some demos, 'help()' for on-line help, or
'help.start()' for an HTML browser interface to help.
Type 'q()' to quit R.

# Bootstrapping renv 1.0.7 ---------------------------------------------------
- Downloading renv ... OK
- Installing renv  ... OK

- Project 'D:/git/ohdsi-studies/SemaglutideNaion' loaded. [renv 1.0.7]
- One or more packages recorded in the lockfile are not installed.
- Use `renv::status()` for more details.
```

The first time you run this study, you will need to restore the execution
environment using [renv](https://rstudio.github.io/renv/). To do this,
in the console run:

`renv::restore()`

and follow the prompts to install all of the packages. This will take some time
to complete (approximately 30 minutes). Once this operation is complete, please
close RStudio and re-open the project. You will again see the message above stating
that packages recorded in the lockfile are not installed. You can safely 
ignore this message moving forward. At this point you are ready to run the study.

## Running the study

Open the file `StrategusCodeToRun.R` found in the root of your study package
directory (e.g. `D:/git/ohdsi-studies/SemaglutideNaion`). This script will
require some modification to work in your environment. At the top of the 
script, you will a commented out note to tell you to run `renv::restore()`. If 
you followed the earlier instructions, this is not necessary but is a reminder.

### Environment Settings

```r
# ENVIRONMENT SETTINGS NEEDED FOR RUNNING Strategus ------------
Sys.setenv("_JAVA_OPTIONS"="-Xmx4g") # Sets the Java maximum heap space to 4GB
Sys.setenv("VROOM_THREADS"=1) # Sets the number of threads to 1 to avoid deadlocks on file system
```

Please make sure that you either set these options by running these commands
or by adding them to your .Renviron file. If you choose to add these options to
your .Renviron file, please restart your R session after making these changes
to ensure the environment variables are set.

### Study execution settings & CDM connection details

The next block of code will require edits for your environment:

```r
##=========== START OF INPUTS ==========
cdmDatabaseSchema <- "main"
workDatabaseSchema <- "main"
outputLocation <- 'D:/git/ohdsi-studies/SemaglutideNaion'
databaseName <- "Eunomia" # Only used as a folder name for results from the study
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
```

To detail these settings:

- **cdmDatabaseSchema**: The name of the database schema holding your OMOP CDM patient level data.
- **workDatabaseSchema**: The name of the database schema that will hold your cohort tables. 
You must have write access to this schema to create/drop tables and to insert/delete data.
- **outputLocation**: Set this to the path where you have your project, in our
example `D:/git/ohdsi-studies/SemaglutideNaion`.
- **databaseName**: Set this to the name of your site's OMOP CDM database. Please avoid special
characters as this value is used to create a folder with the `databaseName` to hold the results
of running the study.
- **minCellCount**: Set this value based on any site specific requirements you have for censoring
small cell counts. 
- **cohortTableName**: This is a prefix that will be appended to the cohort tables created in your
`workDatabaseSchema`. There is no need to change this value unless you'd like to have a different
way to identify the tables from this study.
- **connectionDetails**: This holds the connection details for your CDM. Please follow the
instructions here: https://ohdsi.github.io/DatabaseConnector/reference/createConnectionDetails.html to 
configure this value. **IMPORTANT:** Please be sure to follow the instructions from above in the
System setup and configuration section.

### Executing the study

Once you have set the values as described above, you can run the entire study by
running the full `StrategusCodeToRun.R` script. Here we'll describe what the
code is doing to run the study via Strategus:

```r
analysisSpecifications <- ParallelLogger::loadSettingsFromJson(
  fileName = "inst/fullStudyAnalysisSpecification.json"
)

# UNCOMMENT TO RUN COHORT DIAGNOSTICS - IF YOU DO THIS, PLEASE
# COMMENT OUT THE COMMAND ABOVE THAT LOADS THE FULL STUDY
# ANALYSIS SPECIFICATION.
# analysisSpecifications <- ParallelLogger::loadSettingsFromJson(
#   fileName = "inst/cohortDiagnosticsAnalysisSpecification.json"
# )

executionSettings <- Strategus::createCdmExecutionSettings(
  workDatabaseSchema = workDatabaseSchema,
  cdmDatabaseSchema = cdmDatabaseSchema,
  cohortTableNames = CohortGenerator::getCohortTableNames(cohortTable = cohortTableName),
  workFolder = file.path(outputLocation, "results", databaseName, "strategusWork"),
  resultsFolder = file.path(outputLocation, "results", databaseName, "strategusOutput"),
  minCellCount = minCellCount
)

if (!dir.exists(file.path(outputLocation, "results", databaseName))) {
  dir.create(file.path(outputLocation, "results", databaseName), recursive = T)
}
ParallelLogger::saveSettingsToJson(
  object = executionSettings,
  fileName = file.path(outputLocation, "results", databaseName, "executionSettings.json")
)

Strategus::execute(
  analysisSpecifications = analysisSpecifications,
  executionSettings = executionSettings,
  connectionDetails = connectionDetails
)
```

The first section loads the `inst/fullStudyAnalysisSpecification.json` which 
contains the full study specification as described in the protocol. Next, 
the execution settings (based on your inputs). These execution settings
are saved using `ParallelLogger::saveSettingsToJson` in case you need
to refer back to these settings. Finally, `Strategus::execute` is called
to execute the analysis against your OMOP CDM.


### Running Cohort Diagnostics

If you'd like to run Cohort Diagnostics on your OMOP CDM, you can modify the
section of the script above to look like this:

```r
# PLEASE NOTE THIS SECTION IS NOW DISABLED VIA COMMENTS
#analysisSpecifications <- ParallelLogger::loadSettingsFromJson(
#  fileName = "inst/fullStudyAnalysisSpecification.json"
#)

# PLEASE NOTE THIS SECTION IS NOW ACTIVE
analysisSpecifications <- ParallelLogger::loadSettingsFromJson(
 fileName = "inst/cohortDiagnosticsAnalysisSpecification.json"
)

executionSettings <- Strategus::createCdmExecutionSettings(
  workDatabaseSchema = workDatabaseSchema,
  cdmDatabaseSchema = cdmDatabaseSchema,
  cohortTableNames = CohortGenerator::getCohortTableNames(cohortTable = cohortTableName),
  workFolder = file.path(outputLocation, "results", databaseName, "strategusWork"),
  resultsFolder = file.path(outputLocation, "results", databaseName, "strategusOutput"),
  minCellCount = minCellCount
)

if (!dir.exists(file.path(outputLocation, "results", databaseName))) {
  dir.create(file.path(outputLocation, "results", databaseName), recursive = T)
}
ParallelLogger::saveSettingsToJson(
  object = executionSettings,
  fileName = file.path(outputLocation, "results", databaseName, "executionSettings.json")
)

Strategus::execute(
  analysisSpecifications = analysisSpecifications,
  executionSettings = executionSettings,
  connectionDetails = connectionDetails
)
```

The main change is noted above whereby we comment out the analysis specification
to use the `inst/cohortDiagnosticsAnalysisSpecification.json` and the rest of the
code remains the same.


## Sharing Results

Once you have successfully executed the study, your results will be located in
the folder: `D:/git/ohdsi-studies/SemaglutideNaion/results/<your databasename>/strategusOutput`.
Within this folder you will see subfolders for each of the Strategus HADES analytical
modules that produced results. These results are stored as CSV files which you can inspect
before providing the results to the study coordinator.

Once you have reviewed your results and are ready to provide them to the study
coordinator, you can use the `ShareResults.R` script located in the root of the 
project in `D:/git/ohdsi-studies/SemaglutideNaion`. This script will require some modifications
to reflect the choices you made when running the study:

```r
##=========== START OF INPUTS ==========
outputLocation <- 'D:/git/ohdsi-studies/SemaglutideNaion'
databaseName <- "MDCD"
# For uploading the results. You should have received the key file from the study coordinator:
keyFileName <- "[location where you are storing: e.g. ~/keys/study-data-site-covid19.dat]"
userName <- "[user name provided by the study coordinator: eg: study-data-site-covid19]"

##=========== END OF INPUTS ==========
```

To explain these settings:

- **outputLocation**: Set this to the path where you have your project, in our
example `D:/git/ohdsi-studies/SemaglutideNaion`. This must match what you
set in your `StrategusCodeToRun.R`.
- **databaseName**: Set this to the name of your site's OMOP CDM database to 
match what you set in your `StrategusCodeToRun.R`.
- **keyFileName**: The path to an RSA private key that is provided by the study
coordinator.
- **userName**: The user name provided by the study coordinator.