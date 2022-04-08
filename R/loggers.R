#' Read in a single HOBO conductivity logger text file
#'
#' @param serialNo Logger serial number
#' @param fileName name of file
#' @param dirName name of directory containing file
#'
#' @return tibble with columns for datetime, temperature, conductivity, and serial number
#' @export
#'
read_HOBOCondData <- function(serialNo, fileName, dirName){
  # Get serial number from text file column names
  serialNo_fromFile <- read_tsv(paste0(dirName, "/",fileName),
                       n_max = 1,
                       show_col_types = FALSE) %>%
    names() %>%
    `[`(2) %>%
    str_sub(-8,-1)

  # read in data if serial number from file matches serial number in column header
  tryCatch(
    {
      # Check if serial number from file name matches serial number in column header
      if(serialNo_fromFile != serialNo){
        stop()
      }
        # Read the data
        table <- read_tsv(paste0(dirName, "/",fileName),
                          col_names = c("datetime",
                                        "Conductivity_uS_cm",
                                        "Temp_F",
                                        "coupler_detached",
                                        "coupler_attached",
                                        "connected",
                                        "stopped",
                                        "endOfFile"),
                          skip = 1,
                          show_col_types = FALSE) %>%
          select(1:3) %>%
          mutate(datetime = as_datetime(datetime, tz = "US/Mountain",  format= "%m/%d/%y %H:%M:%S")) %>%
          drop_na(Conductivity_uS_cm, Temp_F) %>%
          mutate(serialNo = serialNo)%>%
          # Format conductivity and temperature data for loading into database
          mutate(Temp_C = (Temp_F-30)/1.8) %>% # Convert temperature in degrees Fahrenheit to Celsius
          select(reading_datetime = datetime,
                 Temperature = Temp_C,
                 Conductivity = Conductivity_uS_cm,
                 serialNo = serialNo) %>%
          pivot_longer(2:3,
                       names_to = "metric_name",
                       values_to = "value")
        return(table)
    },
    error = function(c){
      message(paste0('Serial number from the file name (',
                     serialNo,
                     ') does not match the serial number in the file (',
                     serialNo_fromFile,
                     ') for file name of', fileName,'. Data from this file were not read.'))
      return(NULL)
    }
  )
}

#' Read in and combine multiple HOBO conductivity logger
#' text files within a single directory
#'
#' @param loggers Vector of serial numbers for which to read in data
#' @param startDate earliest date when the logger was programmed with format %m/%d/%y
#' @param endDate latest date when the logger was programmed with format %m/%d/%y
#' @param dirName name of directory with conductivity text files
#' @param dataType one of Conductivity, Light, or Pressure
#'
#' @return tibble with columns for datetime, temperature, conductivity, and serial number
#' @export
#'
read_HOBODir <- function(startDate, endDate, loggers, dirName, datatype = "Conductivity"){
  fileList <- tibble(
    fileName = list.files(path = dirName),
    date = str_sub(fileName, 1, 10),
    loggerSerialNo = str_sub(fileName, 12,19)
  ) %>%
    filter(loggerSerialNo %in% loggers,
           date >= lubridate::as_date(startDate),
           date <= lubridate::as_date(endDate))
  serialNumbers <- list.files(path = dirName)
  # TODO: Set function based on datatype
  # Read in files
  data <- map2(fileList$loggerSerialNo, fileList$fileName, read_HOBOCondData, dirName = dirName)%>%
    bind_rows()
  return(data)
}

#' Read in a single day of MiniDOT data from a single logger
#'
#' @param filePath Path of the MiniDOT text file to read in
#'
#' @return Tibble with columns for time (seconds), DO (mg/L),
#'  and temperature (degrees C)
#'
#' @export
#'
read_miniDOTData <- function(filePath){
  data <- read_csv(filePath, skip = 2)
  names(data) <- c("Time_sec", "BV_volts","T_degC", "DO_mgL", "Q")
  return(data)
}

#' Read in and concatenate all miniDOT data files for a single logger
#'
#' @param dir path to directory containing all text files
#' for single logger
#' @param serialNos vector of valid serialNumbers
#' @param startDate first date of data to read in, as a Date object
#' @param endDate last date of data to read in, as a Date object
#'
#' @return Tibble with columns for logger serial number, time (seconds),
#' DO (mg/L), and temperature (degrees C)
#'
#' @export
#'
read_miniDOTDir <- function(dir, serialNos, startDate = as_date("2021-01-01"), endDate = as_date("2022-01-01")){

  tryCatch(
    {
      # check if serial number is in list of miniDOT serial numbers
      serialNo <- stringr::str_sub(dir, -6, -1) %>%
        as.numeric()
      if(!(serialNo %in% serialNos)){
        stop("Not a valid serial number")
      }

      # read in the data
      fileNames <- list.files(dir)
      dates <- lubridate::as_date(stringr::str_sub(fileNames, 1,10))
      fileNames <- fileNames[dates >=startDate & dates <= endDate]

      # read in the data
      df <- purrr::map(paste0(dir, "/", fileNames), read_miniDOTData) %>%
        purrr::map_dfr(bind_rows) %>%
        mutate(serialNo = str_sub(dir, start = -6L, end = -1L),
               reading_datetime = lubridate::with_tz(lubridate::as_datetime(Time_sec), tzone = "US/Mountain")) %>%
        select(reading_datetime,
               Temperature = T_degC,
               `Dissolved Oxygen` = DO_mgL,
               serialNo) %>%
        pivot_longer(2:3,
                     names_to = "metric_name",
                     values_to = "value")
      return(df)
    },
    error = function(c){
      message(paste0(c$message, " (serial number = " , serialNo, ")"))
      return(NULL)
    }
  )
}


#' Upload conductivity data to database
#'
#' @param data tibble of readings,as produced by e.g. read_HOBODir or read_miniDOTDir
#' @param cn DBI connection object
#'
#' @return inserts records into the database and returns the number of records inserted
#' @export
#'
loadLoggerData <- function(cn, data){

  n <- DBI::dbExecute(cn,
                 statement = paste("INSERT IGNORE INTO Readings (deployment_id, reading_datetime, metric_id, value) VALUES",
                                   paste(paste0(
                                     "(","(SELECT deployment_id FROM Deployments AS d LEFT JOIN Loggers AS l ON d.logger_id = l.logger_id WHERE l.serialNo = ",
                                     as.numeric(data$serialNo),
                                     " AND '",data$reading_datetime, "' BETWEEN d.deployment_start AND d.deployment_end), '",
                                     data$reading_datetime,"',",
                                     "(SELECT metric_id FROM Metrics WHERE metric_name = '",data$metric_name,"'),",
                                     data$value,
                                     ")"),
                                     collapse = ",")))

  print(paste0(as_date(data$reading_datetime[1]),":", n, " records added"))

  return(n)
}

#'Break up logger data by
#'
#' @param data
#'
#' @return A list of tibbles broken up first by date and, if needed,
#' into smaller subsets with a maximum of 10,000 rows
#' @export
#'
splitLoggerData <- function(data){
  data %>%
    mutate(date = as_date(reading_datetime)) %>%
    group_split(date) %>%
    map(~.x %>% mutate(group = ceiling(row_number()/10000)) %>% group_split(group)) %>%
    unlist(recursive = FALSE)
}

#' Load a list of tibbles into the database
#'
#' @param dataList list of tibbles
#'
#' @return inserts records into the database and returns a tibble with
#' the number of records inserted for each data chunk
#' @export
#'
loadLoggerDataList <- function(dataList){
  recordsChanged <- tibble(
    date = map(dataList, ~.x$date[1]) %>%
      reduce(c),
    n = 0
  )

  for(i in 1:length(dataList)){
    recordsChanged[i, "n"] <- loadLoggerData(cn, dataList[[i]])
  }

  return(recordsChanged)
}
