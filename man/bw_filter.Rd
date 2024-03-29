% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/spiro_smooth.R
\name{bw_filter}
\alias{bw_filter}
\title{Smooth data with a (zero-phase) Butterworth filter}
\usage{
bw_filter(x, n = 3, W = 0.04, zero_lag = TRUE)
}
\arguments{
\item{x}{A numeric vector on which the digital filter should be applied}

\item{n}{Order of the Butterworth filter, defaults to 3}

\item{W}{Low-pass cut-off frequency of the filter, defaults to 0.04}

\item{zero_lag}{Whether a zero phase (forwards-backwards) filter should be
applied.}
}
\value{
A numeric vector of the same length as x.
}
\description{
Internal function for \code{\link{spiro_smooth}}.
}
\details{
Digital filtering might be a preferable processing strategy for smoothing
data from gas exchange measures when compared to moving averages. Robergs et
al. (2010) proposes a third order Butterworth filter with a low-pass cut-off
frequency of 0.04 for filtering VO2 data.

It should be noted that Butterworth filter comprise a time lag. A method to
create a time series with zero lag is to subsequently apply two Butterworth
filters in forward and reverse direction (forwards-backwards filtering).
While this procedure removes any time lag it changes the magnitude of the
filtering response, i.e. the resulting filter has not the same properties
(order and cut-off frequency) as a single filter.
}
\examples{
# Get VO2 data from example file
vo2_vector <- spiro(spiro_example("zan_gxt"))$VO2

out <- bw_filter(vo2_vector)
head(out, n = 20)
}
