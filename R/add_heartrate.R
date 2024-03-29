#' Import and add heart rate data to cardiopulmonary exercise testing data
#'
#' \code{add_hr()} imports an external file containing heart rate data and adds
#' it to an existing gas exchange data file.
#'
#' Heart rate data will be imported from a \code{.tcx} file. After interpolating
#' the data to full seconds, it is then matched to the imported gas exchange
#' data.
#'
#' @param data A \code{data.frame} of the class \code{spiro} containing the gas
#'   exchange data. Usually the output of a \code{\link{spiro}} call.
#'
#' @inheritParams spiro
#'
#' @return A \code{data.frame} of the class \code{spiro} containing the
#'   cardiopulmonary exercise testing data including heart rate data.
#'
#' @examples
#' # Get example data
#' oxy_file <- spiro_example("zan_ramp")
#' hr_file <- spiro_example("hr_ramp.tcx")
#'
#' # Import and process spiro data
#' oxy_data <- spiro(oxy_file)
#'
#' # Add heart rate data
#' out <- add_hr(oxy_data, hr_file)
#' head(out)
#' @export

add_hr <- function(data, hr_file, hr_offset = 0) {
  # input validation
  if (!any(class(hr_file) == "character") | length(hr_file) != 1) {
    stop("'hr_offset' must be a single numeric value")
  }
  if (!is.numeric(hr_offset) | length(hr_offset) != 1) {
    stop("'hr_offset' must be a single numeric value")
  }

  # import heart rate data
  hr_data <- hr_import(hr_file)

  # handle beginning of data
  if (hr_offset < 0) {
    # if heart rate measures started before gas exchange measures:
    # cut first part of heart rate data
    hr_prewhile <- hr_data[-1:hr_offset]
  } else {
    # if heart rate measures started after gas exchange measures:
    # write NAs for the first heart rate data points
    hr_prewhile <- c(rep(NA, hr_offset), hr_data)
  }

  # handle end of data
  if (length(hr_prewhile) >= nrow(data)) {
    # if heart rate measures ended after gas exchange measures:
    # cut end of heart rate data
    data$HR <- as.numeric(hr_prewhile[seq_len(nrow(data))])
  } else {
    # if heart rate measures ended before gas exchange measures:
    # write NAs for the last heart rate data points
    mis <- nrow(data) - length(hr_prewhile)
    data$HR <- as.numeric(c(hr_prewhile, rep(NA, mis)))
  }
  data
}

hr_import <- function(hr_file) {
  # currently working for Garmin .tcx files

  # -- TO DO --
  # check if it works for other types of heart rate data files and rewrite
  # accordingly

  # read XML file
  tcx <- xml2::read_xml(hr_file)

  # read HR and time data
  time_raw <- xml2::xml_text(xml2::xml_find_all(tcx, "//d1:Time"))
  hr_raw <- xml2::xml_text(xml2::xml_find_all(tcx, "//d1:HeartRateBpm"))

  # handle missing heart rate values
  # search which values are missing
  hr_index <- grepl("HeartRateBpm", xml2::xml_find_all(tcx, "//d1:Trackpoint"))
  # assign heart rate values to NA vector
  hr <- rep.int(NA, length(time_raw))
  hr[hr_index] <- hr_raw

  tcx_data <- data.frame(
    time = time_raw,
    hr = hr
  )

  # interpolate heart rate data to seconds
  hr <- hr_interpolate(tcx_data)

  hr
}

hr_interpolate <- function(data) {
  # get time data from tcx
  dt <- vapply(data$time, gettime, FUN.VALUE = character(1), USE.NAMES = FALSE)
  # convert to seconds
  ds <- to_seconds(dt)
  # handle duplicated values
  time <- dupl(ds - (ds[[1]] - 1))
  # perform linear interpolation
  hr <- stats::approx(
    x = time,
    y = data$hr,
    xout = seq.int(1, max(time), 1)
  )$y
  hr
}

gettime <- function(text) {
  regmatches(text, regexpr(
    "\\d\\d\\:\\d\\d\\:\\d\\d",
    text
  ))
}
