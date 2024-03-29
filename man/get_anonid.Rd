% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/spiro_get.R
\name{get_anonid}
\alias{get_anonid}
\title{Get the anonymization id from personal data}
\usage{
get_anonid(name, surname, birthday = NULL)
}
\arguments{
\item{name}{A character string, containing the participant's name as present
in the raw data file.}

\item{surname}{A character string, containing the participant's surname as
present in the raw data file.}

\item{birthday}{A character string, containing the participant's birthday as
present in the raw data file. If no birthday data is available in the raw
data, this is ignored.}
}
\value{
A character string, containing the anonymized id.
}
\description{
\code{get_anonid()} returns the anonymization id corresponding to given
personal data.
}
\details{
By default, the spiro package anonymizes personal information obtained from
file meta data. The data are saved to the "info" attribute of a spiro() call.
The default anonymization ensures that no personal information is
accidentally revealed, e.g. by sharing spiro outputs as .Rda files.

While there is no way to directly deanonymize the data, get_anonid() allows
you to recreate the ids, when meta data (name, surname and birthday) are
known. Birthday is only used within the id generation if available in the
original raw data.

To disable the anonymization process during import use
\code{spiro(anonymize = FALSE)}
}
\examples{
get_anonid("Jesse", "Owens", "12.09.1913")
}
