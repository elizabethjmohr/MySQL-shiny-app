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
lab_dir <- file.path(sharepoint_path,"Data", "Lab Data","Tidy_Spreadsheets")

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
# TODO: Turn this into a function or move it into read_HOBODir
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
  datatype = "Conductivity",
  dirName = conductivity_dir
)

# Break up conductivity data into a list so that some
# data will be loaded in case of a disconnection
conductivityDataList <- split_loggerData(conductivityData)

# Load conductivity data
load_loggerDataList(conductivityDataList, cn)

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

DODataList <- map_dfr(DODataPaths,
                      read_miniDOTDir,
                      serialNos = miniDOTSerialNumbers,
                      startDate = as_date("2021-08-01"),
                      endDate = as_date("2022-01-01")) %>%
  split_loggerData()

caddisDB::load_loggerDataList(DODataList, cn)

#### Light ####
lightLoggerSerialNumbers <- dbGetQuery(
  conn = cn,
  statement = "SELECT serialNo FROM Loggers
               LEFT JOIN Models
               ON Loggers.model_id = Models.model_id
               WHERE model_name = 'Pendant temp/light'"
) %>%
  pull(serialNo)

lightData <- read_HOBODir(
  startDate = "2021-01-01",
  endDate = "2021-12-31",
  datatype = "Light",
  loggers = lightLoggerSerialNumbers,
  dirName = light_dir
)%>%
  split_loggerData()

load_loggerDataList(lightData, cn)

#### Pressure ####
pressureLoggerSerialNumbers <- dbGetQuery(
  conn = cn,
  statement = "SELECT serialNo FROM Loggers
               LEFT JOIN Models
               ON Loggers.model_id = Models.model_id
               WHERE model_name = 'U20 Water Level Data Logger'"
) %>%
  pull(serialNo)

pressureData <- read_HOBODir(
  startDate = "2021-01-01",
  endDate = "2021-12-31",
  datatype = "Pressure",
  loggers = pressureLoggerSerialNumbers,
  dirName = pressure_dir
)%>%
  split_loggerData()

load_loggerDataList(pressureData, cn)

#### Sample Metadata ####
samples <- read_xlsx(metadata_dir,
                     sheet = "Samples",
                     col_names = c("sample_name", "location_name", "date", "time", "sample_volume_mL","sample_notes"),
                     col_types = c("text", "text", "date", "date", "numeric", "text"),
                     skip = 1) %>%
  mutate(
    sample_datetime = as_datetime(
      paste(
        date,
        hour(time),
        ":",
        minute(time),
        ":",
        second(time)
      ),
      tz = "US/Mountain")
  ) %>%
  select(sample_name, location_name, sample_datetime, sample_notes, sample_volume_mL)

DBI::dbExecute(cn,
               statement = paste("INSERT IGNORE INTO Samples (sample_name, location_id, sample_datetime, sample_notes, sample_volume_mL)",
                                 "VALUES",
                                 paste(paste0(
                                   "('",
                                   samples$sample_name,
                                   "', (SELECT location_id FROM Locations WHERE location_name = '",samples$location_name,"'), '",
                                   samples$sample_datetime,"',",
                                   if_else(is.na(samples$sample_notes), "NULL", paste0("'",samples$sample_notes, "'")), ",",
                                   if_else(is.na(samples$sample_volume_mL), "NULL", as.character(samples$sample_volume_mL)),
                                   ")"),
                                   collapse = ",")))
#### Lab Data ####
labFileNames<- list.files(lab_dir)
labFileNames <- labFileNames[-which(labFileNames == "Lab_Data_Template.xlsx")]
labFilePaths <- file.path(lab_dir, labFileNames)

# read in lab data
labDataList <- map(labFilePaths, read_labData)

# get info on spiked samples
spikedBlanks <- c("CAD_211015_SP1i","CAD_211015_SP2i","CAD_211015_SP3i","CAD_211015_SP4i",
                  "CAD_211015_SP1c","CAD_211015_SP2c","CAD_211015_SP3c","CAD_211015_SP4c")
spikeInfo <- readxl::read_xlsx(file.path(sharepoint_path, "Data", "Metadata","2021-10-05_Nitrate_spikes.xlsx"),
                               col_names = c("sample_name", "volume_sample_mL", "volume_spike_mL"),
                               skip = 1)

volBlankSpike <- 0.05 # 50 uL pipetted into 15 mL of blank sample
volBlank <- 15

# calculate mean atom percent of spiked blanks
N15NO3_index <- which(labFileNames == "2022-02-28_SIF_N15NO3.xlsx")
APSpikedBlank <- labDataList[[N15NO3_index]]$data_table %>%
  filter(sample_name %in% spikedBlanks) %>%
  pull(measurement_value) %>%
  mean()

# calculate mean nitrate concentration of spiked blanks
NO3_index <- which(labFileNames == "2021-11-10_FLBS_NOx.xlsx")
concSpikedBlank <-labDataList[[NO3_index]]$data_table %>%
  filter(sample_name %in% spikedBlanks) %>%
  pull(measurement_value) %>%
  mean()

# calculate nitrate concentration of spike solution
concSpike <- ((volBlankSpike + volBlank)*concSpikedBlank)/volBlankSpike #ppb as N

# correct isotope data
labDataList[[N15NO3_index]]$data_table <-
  correctForSpikes(isotope_data = labDataList[[N15NO3_index]]$data_table,
                   nitrate_data = labDataList[[which(labFileNames == "2021-10-01_FLBS_NOx.xlsx")]]$data_table,
                   spike_table = spikeInfo,
                   C_sp = concSpike,
                   AP_sp = APSpikedBlank)

# create batches for each set of lab data
create_batches(cn, labDataList)

# load data
n_measurements_loaded <- map_dbl(labDataList, load_labData, cn = cn)

n_measurements <- dbGetQuery(cn, "SELECT COUNT(*) FROM Measurements")

#### Caddisfly Counts ####
caddisflyMetricID <- dbGetQuery(cn, "SELECT metric_id FROM Metrics WHERE metric_name = 'Caddisflies'")
caddisflies <- read_csv(file.path(sharepoint_path,
                                  "Data",
                                  "Lab Data",
                                  "From_Lab",
                                  "2022-02-24_Albertson_CaddisTotals.csv")) %>%
  mutate(location_name = paste0("Flume ", Flume),
         metric_id = caddisflyMetricID$metric_id,
         observation_date = "2021-09-21") %>%
  select(metric_id,
         observation_value = Total,
         location_name,
         observation_date)

statement <- paste("INSERT IGNORE INTO Observations (metric_id, observation_value, location_id, observation_date) VALUES",
               paste0("(",
                      caddisflies$metric_id, ",",
                      caddisflies$observation_value, ",",
                      "(SELECT location_id FROM Locations WHERE location_name = '", caddisflies$location_name,"'), '",
                      caddisflies$observation_date,"'",
                      ")",
                      collapse = ","))
dbExecute(cn, statement)

#### Slugs ####
slugs<- read_xlsx(metadata_dir,
                  sheet = "Slugs",
                  col_types = c("text", "date", "date"),
                  col_names = c("location_name", "date", "time"),
                  skip = 1) %>%
  mutate(
    datetime = as_datetime(
      paste(
        date,
        hour(time),
        ":",
        minute(time),
        ":",
        second(time)
      ),
      tz = "US/Mountain")
    )
statement <- paste("INSERT IGNORE INTO Slugs (slug_datetime, location_id) VALUES",
                   paste0(
                     "(",
                     "'", slugs$datetime, "',",
                     "(SELECT location_id FROM Locations WHERE location_name = '", slugs$location_name, "')",
                     ")",
                     collapse = ","))
dbExecute(cn, statement)

#### Treatments ####
assignments <- read_xlsx(metadata_dir,
                        sheet = "Treatment Assignments",
                        col_types = c("text", "date", "text", "date"),
                        col_names = c("location_name", "assignment_start", "treatment_name", "assignment_end"),
                        skip = 1) %>%
  mutate(assignment_start = as_date(assignment_start),
         assignment_end = as_date(assignment_end))

statement <- paste("INSERT IGNORE INTO Assignments (location_id, treatment_id, assignment_start, assignment_end) VALUES",
                   paste0(
                     "(",
                     "(SELECT location_id FROM Locations WHERE location_name = '", assignments$location_name, "'),",
                     "(SELECT treatment_id FROM Treatments WHERE treatment_name = '", assignments$treatment_name, "'),",
                     "'", assignments$assignment_start, "',",
                     "'", assignments$assignment_end, "'",
                     ")",
                     collapse = ","))
dbExecute(cn, statement)

#### Conductivity Meter Readings ####
conductivityMetricID <- dbGetQuery(cn, "SELECT metric_id FROM Metrics WHERE metric_name = 'Conductivity'")$metric_id
temperatureMetricID <- dbGetQuery(cn, "SELECT metric_id FROM Metrics WHERE metric_name = 'Temperature'")$metric_id
meterObservations <- read_xlsx(metadata_dir,
                               sheet = "Conductivity Meter Data",
                               col_types = c("text", "date", "date", "numeric", "numeric"),
                               col_names = c("location_name", "date", "time", "SC_uS_cm", "Temp_C"),
                               skip = 1) %>%
  mutate(
    time =  paste0(time) %>% substr(12, 19),
    date = as_date(date),
    observation_value = SC_uS_cm * (1+0.021*(Temp_C - 25))
  )

statement <- paste("INSERT IGNORE INTO Observations (metric_id, observation_value, location_id, observation_date, observation_time) VALUES",
                   paste0("(",
                          conductivityMetricID, ",",
                          meterObservations$observation_value, ",",
                          "(SELECT location_id FROM Locations WHERE location_name = '", meterObservations$location_name,"'), '",
                          meterObservations$date,"', '",
                          meterObservations$time, "'",
                          ")",
                          collapse = ","))
dbExecute(cn, statement)

statement <- paste("INSERT IGNORE INTO Observations (metric_id, observation_value, location_id, observation_date, observation_time) VALUES",
                   paste0("(",
                          temperatureMetricID, ",",
                          meterObservations$Temp_C, ",",
                          "(SELECT location_id FROM Locations WHERE location_name = '", meterObservations$location_name,"'), '",
                          meterObservations$date,"', '",
                          meterObservations$time, "'",
                          ")",
                          collapse = ","))
dbExecute(cn, statement)
