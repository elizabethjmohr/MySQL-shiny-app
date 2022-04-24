#' Read in a spreadsheet containing data from an analytical lab for a single analyte
#'
#' @param filepath path to the spreadsheet
#'
#' @return a list with the lab name, analysis date, filename, metric name,
#' metric units, detection limit, and tibble of lab data.
#' @export
#'
read_labData <- function(filepath){
  lab_name <- readxl::read_xlsx(filepath,range = "Data!B1",col_names =c("caddis"))[[1]] #col_name is useless placeholder to avoid getting a message
  batch_date <- readxl::read_xlsx(filepath,range = "Data!B2",col_names = "flies")[[1]]
  filename <- readxl::read_xlsx(filepath,range = "Data!B3",col_names = "caddis")[[1]]
  metric_name <- readxl::read_xlsx(filepath,range = "Data!B4",col_names = "flies")[[1]]
  metric_units <- readxl::read_xlsx(filepath,range = "Data!B5",col_names = "caddis")[[1]]
  detection_limit <- readxl::read_xlsx(filepath,range = "Data!B6",col_names = "flies", col_types = "numeric")[[1]]

  lab_data <- readxl::read_xlsx(filepath,
                                skip = 8,
                                col_names = c("sample_name", "measurement_value"),
                                col_types = c("text", "numeric")) %>%
    group_by(sample_name) %>%
    summarise(measurement_value = mean(measurement_value), .groups = "drop") %>% # take mean if lab measured sample twice
    # assume that if measurement value isn't numeric, it is below detection limit (this is true for FLBS data)
    mutate(bd_flag = if_else(is.na(measurement_value), 1, 0),
           measurement_value = replace_na(measurement_value, detection_limit))

  return(list(
    lab_name = lab_name,
    batch_date = paste(batch_date),
    filename = filename,
    metric_name = metric_name,
    metric_units = metric_units,
    detection_limit = detection_limit,
    data_table = lab_data
  ))
}

#' Correct isotope data for unlabeled nitrate spikes
#'
#' @param isotope_data data table of atom percents to be corrected
#' @param nitrate_data data table of nitrate concentrations for samples in isotope_data
#' @param spike_table table with sample IDs of spiked samples, volume of sample, and volume of spike
#' @param C_sp Nitrate concentration of spike solution
#' @param AP_sp Atom percent (N15-Nitrate/(N14-Nitrate + N15 Nitrate)) of spike solutions
#'
#' @return
#' @export
#'
correctForSpikes <- function(isotope_data, nitrate_data, spike_table, C_sp, AP_sp){
  isotope_data %>%
    mutate(sample_id = str_sub(sample_name, 1, 13)) %>%
    rename(atom_percent = measurement_value) %>%
    left_join(nitrate_data %>%
                mutate(sample_id = str_sub(sample_name, 1, 13)) %>%
                group_by(sample_id) %>%
                summarize(nitrate = mean(measurement_value), .groups = "drop"),
              by = "sample_id") %>%
    left_join(spike_table,
              by = "sample_name") %>%
    mutate(corrected_AP = (atom_percent * (C_sp*volume_spike_mL + nitrate*volume_sample_mL)-
                             C_sp*AP_sp*volume_spike_mL)/(nitrate*volume_sample_mL)) %>%
    mutate(measurement_value = if_else(is.na(corrected_AP), atom_percent, corrected_AP)) %>%
    select(sample_name, measurement_value, bd_flag)
}

#' Create batches of lab data in the data base
#'
#' @param cn MariaDB connection object
#' @param labDataList list of lists returned by read_labData
#'
#' @return
#' @export
create_batches <- function(cn, labDataList){
  all_labs <- dbGetQuery(cn, "SELECT lab_id, lab_name FROM Labs")
  lab_idxs <- map_chr(labDataList, function(list) `$`(list, `lab_name`)) %>%
    match(all_labs$lab_name)
  lab_ids <- all_labs[lab_idxs,"lab_id"]
  batch_dates <- map_chr(labDataList, function(list) `$`(list, `batch_date`))
  filenames <- map_chr(labDataList, function(list) `$`(list, `filename`))
  batches <- tibble(
    lab_id = lab_ids,
    batch_date = batch_dates,
    filename = filenames
  ) %>%
    distinct()
  statement <- paste("INSERT IGNORE INTO Batches (lab_id, batch_date, filename) VALUES",
                     paste0("(", lab_ids, ", '", batch_dates, "', '", filenames, "')", collapse = ","))
  n <- dbExecute(cn, statement)
  return(paste0(n, " new batches were created"))
}

#' Load data from lab into the database
#'
#' @param cn MariaDB connection object
#' @param labData list of lab data as returned by read_labData
#'
#' @return
#' @export
#'
load_labData <- function(cn, labData){

  # Get batch_id and throw an error if it doesn't exist
  tryCatch(
    {
      all_batches <- dbGetQuery(cn, "SELECT batch_id, filename FROM Batches")
      batch_id <- all_batches %>%
        filter(filename == labData$filename) %>%
        pull(batch_id)

      if(length(batch_id) == 0){
        stop("No batch associated with ", labData$filename)
      }
    },
    error = function(c){
      message(paste0(c$message))
      return(NULL)
    }
  )
  # Get metric_id, throw an error if it doesn't exist
  tryCatch(
    {
      all_metrics <- dbGetQuery(cn, "SELECT metric_id, metric_name, metric_units FROM Metrics")

      metric_id <- all_metrics %>%
        filter(metric_name == labData$metric_name,
               metric_units == labData$metric_units) %>%
        pull(metric_id)

      if(length(metric_id) == 0){
        stop("No metric associated with ", labData$metric_name, "(", labData$metric_units, ")")
      }
    },
    error = function(c){
      message(paste0(c$message))
      return(NULL)
    }
  )
  # Get sample id, throw a warning if it doesn't exist for one or more samples
  tryCatch(
    {
      all_samples <- dbGetQuery(cn, "SELECT sample_id, sample_name FROM Samples")

      data_to_load <- labData$data_table %>%
        left_join(all_samples, by = "sample_name")

      bad_samples <- data_to_load %>%
        filter(is.na(sample_id))

      # Check to make sure sample metadata has already been loaded into the database
      if(nrow(bad_samples > 0)){
        warning("The following samples don't have metadata in the database:", paste(bad_samples$sample_name, collapse = ","))
        data_to_load <- data_to_load %>%
          filter(!(is.na(sample_id)))
      }else{
        data_to_load
      }
    },
    warning = function(w){
      message(paste0(w$message))
      return(NULL)
    }
  )

  data_to_load <- data_to_load %>%
     mutate(batch_id = batch_id,
            metric_id = metric_id) %>%
    select(sample_id, batch_id, measurement_value, metric_id, bd_flag)

  statement <- paste("INSERT IGNORE INTO Measurements (sample_id, batch_id, measurement_value, metric_id, bd_flag) VALUES",
                     paste0("(",
                            data_to_load$sample_id, ",",
                            data_to_load$batch_id, ",",
                            data_to_load$measurement_value,",",
                            data_to_load$metric_id,",",
                            data_to_load$bd_flag,
                            ")",
                            collapse = ","))

  n <- dbExecute(cn, statement)
  print(paste0(n, " new measurements were loaded"))
  return(n)
}


