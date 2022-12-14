% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/spiro_import.R
\name{spiro_import}
\alias{spiro_import}
\title{Import raw data from spiroergometric devices}
\usage{
spiro_import(file, device = NULL, anonymize = TRUE)
}
\arguments{
\item{file}{The absolute or relative path of the file that contains the gas
exchange data.}

\item{device}{A character string, specifying the device for measurement. By
default the device type is guessed by the characteristics of the
\code{file}. This can be overridden by setting the argument to
\code{"cortex"}, \code{"cosmed"}, \code{"vyntus"} or \code{"zan"}.}

\item{anonymize}{Whether meta data should be anonymized during import.
Defaults to TRUE. See \code{\link{get_anonid}} for more information.}
}
\value{
A \code{data.frame} with data. The attribute \code{info} contains
addition meta-data retrieved from the original file.
}
\description{
\code{spiro_import()} retrieves cardiopulmonary data from various types of
metabolic cart files.
}
\details{
Different metabolic carts yield different output formats for their data. By
default, this function will guess the used device based on the
characteristics of the given file. This behavior can be overridden by
explicitly stating \code{device}.

The currently supported metabolic carts are:
\itemize{
\item \strong{CORTEX} (\code{.xlsx}, \code{.xls} or files \code{.xml} in
English or German language)
\item \strong{COSMED} (\code{.xlsx} or \code{.xls} files, in English or
German language)
\item \strong{Vyntus} (\code{.txt} files in German or French language)
\item \strong{ZAN} (\code{.dat} files in German language, usually with
names in the form of \code{"EXEDxxx"})
}
}
\examples{
# Get example data
file <- spiro_example("zan_gxt")

out <- spiro_import(file)
head(out)
}
