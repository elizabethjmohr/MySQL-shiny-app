% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/logger_data_tools.R
\name{load_loggerDataList}
\alias{load_loggerDataList}
\title{Load a list of tibbles into the database}
\usage{
load_loggerDataList(dataList, cn)
}
\arguments{
\item{dataList}{list of tibbles}

\item{cn}{DBI connection object}
}
\value{
inserts records into the database and returns a tibble with
the number of records inserted for each data chunk
}
\description{
Load a list of tibbles into the database
}
