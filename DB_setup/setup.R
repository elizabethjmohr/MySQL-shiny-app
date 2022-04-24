library(tidyverse)
library(DBI)
library(caddisDB)

# Set up ssh tunneling and connect to database
connection <- connect()
cn <- connection[[2]]

#### Metrics ####
metrics <- tibble(
  metric_name = c("Nitrate",
                  "Nitrite",
                  "Nitrate+Nitrite",
                  "Ammonium",
                  "Dissolved Oxygen",
                  "Dissolved Organic Nitrogen",
                  "Dissolved Organic Carbon",
                  "Sulfate",
                  "N2",
                  "N20",
                  "15N-N2",
                  "15N-N20",
                  "15N-NO3",
                  "Conductivity",
                  "Specific Conductance",
                  "Temperature",
                  "Light Intensity",
                  "Pressure",
                  "Caddisflies"),
  metric_units = c("ppb_as_N",
                   "ppb_as_N",
                   "ppb_as_N",
                   "ppb_as_N",
                   "mg/L",
                   "ppm_as_N",
                   "ppm_as_C",
                   "ppm_as_S",
                   "ppm",
                   "ppm",
                   "atom %",
                   "atom %",
                   "atom %",
                   "uS/cm",
                   "uS/cm",
                   "degrees_C",
                   "lumens/ft^2",
                   "psi",
                   "#"))

DBI::dbExecute(cn,
               statement = paste("INSERT IGNORE INTO Metrics (metric_name, metric_units)",
                                "VALUES",
                                paste(paste0("('", metrics$metric_name, "','", metrics$metric_units, "')"),
                                      collapse = ",")))

#### Labs ####
labs <- tibble(
  lab_name = c("MSU Environmental Analytical Lab",
               "Energy Labs",
               "FLBS Freshwater Research Lab",
               "UC Davis Stable Isotope Facility")
)

DBI::dbExecute(cn,
               statement = paste("INSERT IGNORE INTO Labs (lab_name)",
                                 "VALUES",
                                 paste(paste0("('", labs$lab_name,"')"),
                                       collapse = ",")))

#### Loggers ####
loggers <- tibble(
  make_name = c(rep(c("HOBO", "PME"), each = 16), rep("HOBO", times = 6)),
  model_name = c(rep(c("U24 Conductivity Data Logger", "MiniDOT"), each = 16), rep("Pendant temp/light", times = 3), rep("U20 Water Level Data Logger", times = 3)),
  serialNo = c(
    10104871,10104867,10104877,20974599,20974597,10104862,10104865,10104875,10104866,20974598,20974600,10104863,10104869,20974596,10104864,10104863, #HOBO Conductivity Loggers
    415148, 432269, 467606, 488982, 493593, 497232, 511686, 567371,648356,688268,701237,702726,728987,736634,739125,921379, #miniDOTs
    10316713, 850953,9791255, #light loggers
    10145131,9800865,9800872 #pressure loggers
    )
)

DBI::dbExecute(cn,
               statement = paste("INSERT IGNORE INTO Makes (make_name)",
                                 "VALUES",
                                 paste(paste0("('", unique(loggers$make_name),"')"),
                                       collapse = ",")))

DBI::dbExecute(cn,
               statement = paste("INSERT IGNORE INTO Models (model_name)",
                                 "VALUES",
                                 paste(paste0("('", unique(loggers$model_name),"')"),
                                       collapse = ",")))
DBI::dbExecute(cn,
               statement = paste("INSERT IGNORE INTO Loggers (serialNo, make_id, model_id)",
                                 "VALUES",
                                 paste(paste0(
                                   "(",unique(loggers$serialNo),",",
                                   "(SELECT make_id FROM Makes WHERE make_name = '",loggers$make_name,"'),",
                                   "(SELECT model_id FROM Models WHERE model_name = '",loggers$model_name,"')",")"),
                                   collapse = ",")))

#### Locations ####
locations <- tibble(
  location_name = c(paste("Flume", LETTERS[1:15]),
                    "Outflow Reservoir", "Inflow",
                    "Salt Slug", "Blank",
                    "Cherry Creek",
                    "Leon Johnson Hall 819",
                    "Temperature Bath",
                    "Spike Solution")
)

DBI::dbExecute(cn,
               statement = paste("INSERT IGNORE INTO Locations (location_name)",
                                 "VALUES",
                                 paste(paste0("('", locations$location_name,"')"),
                                       collapse = ",")))

#### Treatments ####
treatments <- tibble(
  treatment_name = c("0 caddisflies",
                     "16 caddisflies",
                     "47 caddisflies",
                     "133 caddisflies",
                     "390 caddisflies")
)

DBI::dbExecute(cn,
               statement = paste("INSERT IGNORE INTO Treatments (treatment_name)",
                                 "VALUES",
                                 paste(paste0("('", treatments$treatment_name,"')"),
                                       collapse = ",")))



