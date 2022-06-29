# This script generates a Ecological Metadata Language (EML) file
# documenting all tables and associated fields in the MySQL database.

library(EML)

# Treatments table -------------------------------------------------------------
treatments_attributes <-tibble::tribble(
  ~attributeName,  ~attributeDefinition,                                                           ~formatString, ~definition,              ~unit,            ~numberType,
  "treatment_id",   "primary key",                                                                      NA,        NA,                      "dimensionless",  "int",
  "treatment_name", "experimental treatment description (e.g., 200 caddisflies per square meter)",      NA,        "treatment description",  NA,              NA
)

treatments_attributeList <- set_attributes(
  treatments_attributes,
  col_classes = c("numeric", "character"))

treatments_dataTable <- list(
  entityName = "Treatments",
  entityDescription = "Experimental treatments applied to mesocosms",
  attributeList = treatments_attributeList)

# Assignments table ------------------------------------------------------------
assignments_attributes <-tibble::tribble(
  ~attributeName,    ~attributeDefinition,                            ~formatString, ~definition,     ~unit,            ~numberType,
  "assignment_id",    "primary key",                                    NA,           NA,             "dimensionless",  "int",
  "location_id",      "foreign key referencing Locations table",        NA,           NA,             "dimensionless",  "int",
  "treatment_id",     "foreign key reference Treatments table",         NA,           NA,             "dimensionless",  "int",
  "assignment_start", "date when treatment was applied at location",    "YYYY-MM-DD", NA,             NA,                 NA,
  "assignment_end",   "date when treatment ended at location",          "YYYY-MM-DD", NA,             NA,                 NA
)

assignments_attributeList <- set_attributes(
  assignments_attributes,
  col_classes = c("numeric", "numeric", "numeric", "Date", "Date"))

assignments_dataTable <- list(
  entityName = "Assignments",
  entityDescription = "Experimental treatment assignments (i.e., which mesocosms were subject to which treatments)",
  attributeList = assignments_attributeList)

# Locations table --------------------------------------------------------------

locations_attributes <- tibble::tribble(
  ~attributeName,    ~attributeDefinition,   ~formatString,  ~definition,        ~unit,            ~numberType,
  "location_id",     "primary key",          NA,             NA,                 "dimensionless",  "int",
  "location_name",   "name of location",     NA,             "name of location", NA,               NA
)

locations_attributeList <- set_attributes(
  locations_attributes,
  col_classes = c("numeric", "character"))

locations_dataTable <- list(
  entityName = "Locations",
  entityDescription = "Locations (e.g., Flume A)",
  attributeList = locations_attributeList)

# Metrics table ----------------------------------------------------------------
metrics_attributes <- tibble::tribble(
  ~attributeName,    ~attributeDefinition,   ~formatString,  ~definition,        ~unit,            ~numberType,
  "metric_id",       "primary key",          NA,             NA,                 "dimensionless",  "int",
  "metric_name",     "name of metric",       NA,             "name of metric",   NA,               NA,
  "metric_units",    "metric units",         NA,             "metric units",     NA,               NA
)

metrics_attributeList <- set_attributes(
  metrics_attributes,
  col_classes = c("numeric", "character", "character"))

metrics_dataTable <- list(
  entityName = "Metrics",
  entityDescription = "Metrics measured during experiment with units (e.g., nitrate (ppb NO3-N))",
  attributeList = metrics_attributeList)

# Makes table ------------------------------------------------------------------
makes_attributes <- tibble::tribble(
  ~attributeName,    ~attributeDefinition,           ~formatString,  ~definition,        ~unit,            ~numberType,
  "make_id",        "primary key",                   NA,             NA,                 "dimensionless",  "int",
  "make_name",      "logger brand name (e.g. HOBO)", NA,             "logger brand name", NA,               NA
)

makes_attributeList <- set_attributes(
  makes_attributes,
  col_classes = c("numeric", "character"))

makes_dataTable <- list(
  entityName = "Makes",
  entityDescription = "Brands of loggers used in experiment (e.g., HOBO)",
  attributeList = makes_attributeList)

# Models table -----------------------------------------------------------------
models_attributes <- tibble::tribble(
  ~attributeName,    ~attributeDefinition,                  ~formatString,  ~definition,           ~unit,            ~numberType,
  "model_id",        "primary key",                         NA,             NA,                    "dimensionless",  "int",
  "model_name",      "name of logger model (e.g. MiniDOT)", NA,             "name of logger model", NA,               NA
)

models_attributeList <- set_attributes(
  models_attributes,
  col_classes = c("numeric", "character"))

models_dataTable <- list(
  entityName = "Models",
  entityDescription = "Logger models (e.g., MiniDOT)",
  attributeList = models_attributeList)

# Loggers table ----------------------------------------------------------------
loggers_attributes <- tibble::tribble(
  ~attributeName,    ~attributeDefinition,                                  ~formatString,  ~definition,        ~unit,            ~numberType,
  "logger_id",       "primary key",                                         NA,             NA,                 "dimensionless",  "int",
  "serial_No",       "logger serial number",                                NA,             NA,                 "dimensionless",  "int",
  "make_id",         "foreign key referencing a make in the Makes table",   NA,             NA,                 "dimensionless",  "int",
  "model_id",        "foreign key referencing a model in the models table", NA,             NA,                 "dimensionless",  "int"
)

loggers_attributeList <- set_attributes(
  loggers_attributes,
  col_classes = c("numeric", "numeric", "numeric", "numeric"))

loggers_dataTable <- list(
  entityName = "Loggers",
  entityDescription = "Individual loggers used in experiment",
  attributeList = loggers_attributeList)

# Labs table -------------------------------------------------------------------
labs_attributes <- tibble::tribble(
  ~attributeName, ~attributeDefinition,     ~formatString,  ~definition,              ~unit,            ~numberType,
  "lab_id",       "primary key",            NA,             NA,                       "dimensionless",  "int",
  "lab_name",     "name of analytical lab", NA,             "name of analytical lab", NA,               NA
)

labs_attributeList <- set_attributes(
  labs_attributes,
  col_classes = c("numeric", "character"))

labs_dataTable <- list(
  entityName = "Labs",
  entityDescription = "Analytical labs that analyzed samples from the experiment",
  attributeList = labs_attributeList)

# Batches table ----------------------------------------------------------------
batches_attributes <-tibble::tribble(
  ~attributeName,    ~attributeDefinition,                              ~formatString, ~definition,                                     ~unit,            ~numberType,
  "batch_id",        "primary key",                                     NA,            NA,                                              "dimensionless",  "int",
  "lab_id",          "foreign key referencing a lab in the Labs table", NA,            NA,                                              "dimensionless",  "int",
  "batch_date",      "date when batch of samples were analyzed",        "YYYY-MM-DD",  NA,                                               NA,                 NA,
  "filename",        "name of file containing data received from lab",  NA,            "name of file containing data received from lab", NA,                 NA
)

batches_attributeList <- set_attributes(
  batches_attributes,
  col_classes = c("numeric", "numeric", "Date", "character"))

batches_dataTable <- list(
  entityName = "Batches",
  entityDescription = "",
  attributeList = batches_attributeList)

# Deployments table ------------------------------------------------------------
deployments_attributes <- tibble::tribble(
  ~attributeName,     ~attributeDefinition,                                        ~formatString, ~definition, ~unit,           ~numberType,
  "deployment_id",    "primary key",                                                NA,            NA,         "dimensionless",  "int",
  "logger_id",        "foreign key referencing a logger in the Loggers table",      NA,            NA,         "dimensionless",  "int",
  "location_id",      "foreign key referencing a location in the Location table",   NA,            NA,         "dimensionless",  "int",
  "deployment_start", "date when logger was deploymed",                             "YYYY-MM-DD",  NA,          NA,               NA,
  "deployment_end",   "date when logger was retrieved",                             "YYYY-MM-DD",  NA,          NA,               NA
)

deployments_attributeList <- set_attributes(
  deployments_attributes,
  col_classes = c("numeric", "numeric", "numeric", "Date", "Date"))

deployments_dataTable <- list(
  entityName = "Deployments",
  entityDescription = "Deployments, each defined by the placement of a logger at a location for a certain period of time",
  attributeList = deployments_attributeList)

# Readings table ---------------------------------------------------------------
readings_attributes <- tibble::tribble(
  ~attributeName,     ~attributeDefinition,                                            ~formatString,         ~definition, ~unit,             ~numberType,
  "reading_id",       "primary key",                                                   NA,                    NA,         "dimensionless",     "int",
  "deployment_id",    "foreign key referencing a deployment in the Deployments table", NA,                    NA,         "dimensionless",     "int",
  "metric_id",        "foreign key referencing a metric in the Metrics table",         NA,                    NA,         "dimensionless",     "int",
  "reading_datetime", "date-time 0f reading",                                          "YYYY-MM-DD hh:mm:ss", NA,          NA,                  NA,
  "value",            "value of metric recorded by logger",                            NA,                    NA,         "dimensionless",     "real"
)

# Note: units for the value field are listed as "dimensionless", though the
# actual units are variable and depend on metric_id.

readings_attributeList <- set_attributes(
  readings_attributes,
  col_classes = c("numeric", "numeric", "numeric", "Date", "numeric"))

readings_dataTable <- list(
  entityName = "Readings",
  entityDescription = "Logger readings",
  attributeList = readings_attributeList)

# Observations table -----------------------------------------------------------
observations_attributes <- tibble::tribble(
  ~attributeName,     ~attributeDefinition,                                         ~formatString, ~definition, ~unit,             ~numberType,
  "observation_id",   "primary key",                                                NA,            NA,         "dimensionless",     "int",
  "location_id",      "foreign key referencing a locaion in the Locations table",   NA,            NA,         "dimensionless",     "int",
  "metric_id",        "foreign key referencing a metric in the Metrics table",      NA,            NA,         "dimensionless",     "int",
  "observation_date", "date of observation",                                        "YYYY-MM-DD",  NA,          NA,                  NA,
  "observation_time", "time of observation",                                        "hh:mm:ss",    NA,          NA,                  NA,
  "observation_value","value of metric measured",                                   NA,            NA,         "dimensionless",     "real"
)

# Note: units for the value field are listed as "dimensionless", though the
# actual units are variable and depend on metric_id.

observations_attributeList <- set_attributes(
  observations_attributes,
  col_classes = c("numeric", "numeric", "numeric", "Date", "Date", "numeric"))

observations_dataTable <- list(
  entityName = "Observations",
  entityDescription = "Observations, defined as any measurement not associated with a logger reading or water sample (e.g., caddisfly counts, meter readings) ",
  attributeList = observations_attributeList)

# Samples table ----------------------------------------------------------------
samples_attributes <- tibble::tribble(
  ~attributeName,     ~attributeDefinition,                                            ~formatString,         ~definition,          ~unit,             ~numberType,
  "sample_id",        "primary key",                                                   NA,                    NA,                   "dimensionless",     "int",
  "location_id",      "foreign key referencing a location in the Locations table",     NA,                    NA,                   "dimensionless",     "int",
  "sample_datetime",  "date/time when sample was collected",                           "YYYY-MM-DD hh:mm:ss", NA,                   NA,                  NA,
  "sample_notes",     "notes about sample",                                            NA,                    "notes about sample", NA,                  NA,
  "sample_volume_mL", "volume of water removed from mesocosm during sample collection",NA,                    NA,                   "mL",                "real"
)

samples_attributeList <- set_attributes(
  samples_attributes,
  col_classes = c("numeric", "numeric", "Date", "character", "numeric"))

samples_dataTable <- list(
  entityName = "Samples",
  entityDescription = "Water samples",
  attributeList = samples_attributeList)

# Measurements table -----------------------------------------------------------
measurements_attributes <- tibble::tribble(
  ~attributeName,     ~attributeDefinition,                                                            ~formatString, ~definition, ~unit,             ~numberType,
  "measurement_id",   "primary key",                                                                   NA,            NA,         "dimensionless",     "int",
  "sample_id",        "foreign key referencing a sample in the Samples table",                         NA,            NA,         "dimensionless",     "int",
  "metric_id",        "foreign key referencing a metric in the Metrics table",                         NA,            NA,         "dimensionless",     "int",
  "batch_id",         "foreign key referencing a batch in the Batches table",                          NA,            NA,         "dimensionless",     "int",
  "bd_flag",          "indicates whether sample is above (1) or below (0) the method detection limit", NA,            NA,         "dimensionless",     "int",
  "measurement_value","value of metric measured",                                                      NA,            NA,         "dimensionless",     "real"
)

# Note: units for the value field are listed as "dimensionless", though the
# actual units are variable and depend on metric_id.

measurements_attributeList <- set_attributes(
  measurements_attributes,
  col_classes = c("numeric", "numeric", "numeric", "numeric", "numeric", "numeric"))

measurements_dataTable <- list(
  entityName = "Measurements",
  entityDescription = "Measurements made on water samples analyzed at analytical lab",
  attributeList = measurements_attributeList)


# Additional dataset metadata --------------------------------------------------

title <- "The Effect of Net-Spinning Caddisflies on Hyporheic Exchange and Nitrate Uptake in Stream Mesocosms"
abstract <- "The aim of this research was to experimentally investigate the effect
of net-spinning caddisfly larvae on rates of hyporheic exchange and nitrate uptake.
To do this, we constructed 15 circular stream mesocosms and released caddisflies into each
according to one of five caddisfly density treatments. We measured hyporheic exchange
several times over the course of the experiment by releasing a slug of NaCl solution to
each mescocosm and measuring specific conductance. At the end of the experiment,
we measured nitrate uptake by adding a slug of 15N-enriched KNO3 solution to each mescocosm
and then collecting samples several times over the course of 8 hours. Samples were analyzed for
concentrations and isotopic concentrations of nitrate and N2-gas. The data from these experiments
is stored in a MySQL database which is documented here."

# Note: Several other modules could be added as needed (e.g. contact info, intellectual rights, etc.)
dataset <- list(
  title = title,
  abstract = abstract,
  dataTable = treatments_dataTable,
  dataTable = assignments_dataTable,
  dataTable = locations_dataTable,
  dataTable = metrics_dataTable,
  dataTable = makes_dataTable,
  dataTable = models_dataTable,
  dataTable = loggers_dataTable,
  dataTable = labs_dataTable,
  dataTable = batches_dataTable,
  dataTable = deployments_dataTable,
  dataTable = readings_dataTable,
  dataTable = observations_dataTable,
  dataTable = samples_dataTable,
  dataTable = measurements_dataTable
)

# EML file creation ------------------------------------------------------------
eml <- list(
  packageId = uuid::UUIDgenerate(),
  system = "uuid", # type of identifier
  dataset = dataset
)

write_eml(eml, "eml.xml")
eml_validate("eml.xml")

