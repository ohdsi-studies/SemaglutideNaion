Estimation of risk of NAION and other vision disorders from exposure to semaglutide
=============

<img src="https://img.shields.io/badge/Study%20Status-Repo%20Created-lightgray.svg" alt="Study Status: Repo Created">

- Analytics use case(s): **Population-Level Estimation**
- Study type: **Clinical Application**
- Tags: **Eye Care & Vision Research, Type 2 Diabetes**
- Study lead: **-**
- Study lead forums tag: **[[Lead tag]](https://forums.ohdsi.org/u/[Lead tag])**
- Study start date: **-**
- Study end date: **-**
- Protocol: **-**
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
you opted to download the study package).

This study package uses [renv](https://rstudio.github.io/renv/) to setup the
execution environment to ensure that all of the required R packages are 
properly installed for the project. Please note that this will NOT change
any of your R package. Any/all packages installed whie