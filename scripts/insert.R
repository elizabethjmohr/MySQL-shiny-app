# This script is a template for adding new records to the database, and could
# also be used to recreate the database from scratch if needed.
# TODO: use targets to manage dependencies and update DB as needed?

library(tidyverse)
library(lubridate)
library(DBI)
library(readxl)
library(caddisDB)

#### Setup ####

# Set up ssh tunneling and connect to database
connection <- connect()
cn <- connection[[2]]

# Specify file paths
# TODO: replace this with pointer to Sharepoint, need to work with IT to get access using Microsoft365R package
sharepoint_path <- "/Users/elizabethmohr/Library/CloudStorage/OneDrive-SharedLibraries-MontanaStateUniversity/Caddisflies & Metabolism - Documents"
metadata_dir <- file.path(sharepoint_path, "Data", "Metadata", "Metadata_and_MeterData.xlsx")
DO_dir <- file.path(sharepoint_path, "Data", "Logger Data", "miniDOTData")
conductivity_dir <- file.path(sharepoint_path,"Data", "Logger Data","Conductivity Logger Data","textfiles")
light_dir <- file.path(sharepoint_path,"Data", "Logger Data","Light Logger Data","textfiles")
pressure_dir <- file.path(sharepoint_path,"Data", "Logger Data","Pressure Logger Data","textfiles")

#### Deployments ####
deployments <- read_xlsx(metadata_dir,
                         sheet = "Logger Deployments",
                         col_names = c("serialNo", "location_name", "deployment_start_date", "deployment_start_time", "deployment_end_date", "deployment_end_time", "notes"),
                         skip = 1) %>%
  mutate(
    deployment_start = as_datetime(
      paste(
        deployment_start_date,
        hour(deployment_start_time),
        ":",
        minute(deployment_start_time),
        ":",
        second(deployment_start_time)
      ),
      tz = "US/Mountain"),
    deployment_end = as_datetime(
      paste(
        deployment_end_date,
        hour(deployment_end_time),
        ":",
        minute(deployment_end_time),
        ":",
        second(deployment_end_time)
      ),
      tz = "US/Mountain")
  ) %>%
  select(serialNo, location_name, deployment_start, deployment_end)

DBI::dbExecute(cn,
               statement = paste("INSERT IGNORE INTO Deployments (logger_id, deployment_start, deployment_end, location_id)",
                                 "VALUES",
                                 paste(paste0(
                                   "(",
                                   "(SELECT logger_id FROM Loggers WHERE serialNo = ",deployments$serialNo,"), '",
                                   deployments$deployment_start,"', '",
                                   deployments$deployment_end,"',",
                                   "(SELECT location_id FROM Locations WHERE location_name = '",deployments$location_name,"')",
                                   ")"),
                                   collapse = ",")))

#### Conductivity ####
# Get all HOBO conductivity logger serial numbers
conductivityLoggerSerialNumbers <- dbGetQuery(
  conn = cn,
  statement = "SELECT serialNo FROM Loggers
               LEFT JOIN Models
               ON Loggers.model_id = Models.model_id
               WHERE model_name = 'U24 Conductivity Data Logger'"
) %>%
  pull(serialNo)

# Read in conductivity data from 2021
conductivityData <- read_HOBODir(
  startDate = "2021-01-01",
  endDate = "2021-12-31",
  loggers = conductivityLoggerSerialNumbers,
  dirName = conductivity_dir
)

# Break up conductivity data into a list so that some
# data will be loaded in case of a disconnection
conductivityDataList <- splitLoggerData(conductivityData)

# Load conductivity data
loadLoggerDataList(conductivityDataList)

#### Dissolved Oxygen ####
miniDOTSerialNumbers <- dbGetQuery(
  conn = cn,
  statement = "SELECT serialNo FROM Loggers
               LEFT JOIN Models
               ON Loggers.model_id = Models.model_id
               WHERE model_name = 'MiniDOT'"
) %>%
  pull(serialNo)

DODataPaths <- list.dirs(DO_dir)[-c(1)]

# Read in miniDOT data and break up into a list
DODataList <- map_dfr(DODataPaths, read_miniDOTDir) %>%
  splitLoggerData()

# Load miniDOT data into database
loadLoggerDataList(DODataList)

