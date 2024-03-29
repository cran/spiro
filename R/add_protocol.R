#' Add a test protocol to an exercise testing data set
#'
#' \code{add_protocol()} adds a predefined test protocol to an existing set of
#' data from an exercise test.
#'
#' @param data A spiro \code{data.frame} containing the exercise testing data.
#' @param protocol A \code{data.frame} containing the test protocol, as created
#'   by \code{\link{set_protocol}}, \code{\link{set_protocol_manual}} or
#'   \code{\link{get_protocol}}.
#'
#' @return A \code{data.frame} of the class \code{spiro} with cardiopulmonary
#'   parameters and the corresponding load data.
#'
#' @examples
#' # Get example data
#' file <- spiro_example("zan_gxt")
#'
#' s <- spiro(file)
#' out <- add_protocol(
#'   s,
#'   set_protocol(pt_pre(60), pt_steps(300, 50, 50, 7, 30))
#' )
#' head(out)
#' @seealso [set_protocol] for protocol setting with helper functions.
#' @seealso [set_protocol_manual] for manual protocol design.
#' @seealso [get_protocol] For automated extraction of protocols from raw data.
#' @export

add_protocol <- function(data, protocol) {
  # attach the protocol to the data frame
  if (is.null(protocol)) { # no protocol given
    add <- data.frame(
      load = rep.int(0, nrow(data)),
      step = rep.int(0, nrow(data))
    )
    ptcl <- NULL
  } else {
    # preprocess the protocol
    ptcl <- get_features(protocol)

    # write load and step code vectors
    add <- data.frame(
      load = rep.int(ptcl$load, ptcl$duration),
      step = rep.int(ptcl$code, ptcl$duration)
    )
    if (nrow(data) < nrow(add)) { # protocol longer than data
      add <- add[seq_len(nrow(data)), ] # remove last protocol values
      rownames(add) <- NULL
    } else if (nrow(data) > nrow(add)) { # protocol shorter than data
      dif <- nrow(data) - nrow(add)
      end <- data.frame( # code last seconds as post measures
        load = rep.int(0, dif),
        step = rep.int(-2, dif)
      )
      add <- rbind(add, end)
    }
  }

  # add protocol variables to the existing data
  out <- cbind(add, data[, !names(data) %in% c("load", "step"), drop = FALSE])

  # preserve and create attributes
  attr(out, "info") <- attr(data, "info")
  attr(out, "protocol") <- ptcl
  attr(out, "raw") <- attr(data, "raw")
  attr(out, "testtype") <- get_testtype(ptcl)
  testtype_class <- switch(attr(out, "testtype"),
    "constant" = "spiro_clt",
    "ramp" = "spiro_rmp",
    "incremental" = "spiro_gxt",
    NULL
  )
  class(out) <- c(testtype_class, class(data))

  out
}


#' Guess a test protocol from a corresponding exercise testing data set
#'
#' \code{get_protocol()} gets the underlying test protocol based on given load
#' data.
#'
#' @param data A \code{data.frame} containing the exercise testing data. It is
#'   highly recommend to parse non-interpolated breath-by-breath data or
#'   processed data with a very short interpolating/averaging interval.
#'
#' @return A \code{data.frame} with the duration and load of each protocol step.
#'
#' @examples
#' # Import example data
#' raw_data <- spiro_raw(data = spiro_example("zan_gxt"))
#'
#' get_protocol(raw_data)
#' @export

get_protocol <- function(data) {
  # Round load data before protocol guessing assuming that power data will be
  # only relevant in steps of 5W and velocity data in steps of .05 m/s or km/h.
  # This is necessary as load data will sometimes show minor fluctuations, which
  # should not influence the protocol guessing

  if (max(data$load, na.rm = TRUE) > 30) {
    # cycling
    data$load <- round(data$load / 5) * 5
  } else {
    # running
    data$load <- round(data$load * 20) / 20
  }

  # get data indices of load changes
  values <- c(1, which(diff(data$load) != 0) + 1)

  # get time and load for every time point when load changes
  changes <- data[values, c("time", "load")]

  # advanced protocol guessing for breath-by-breath data
  # single data points with unique load values (e.g. acceleration of an
  # treadmill) are removed from protocol guessing

  if (check_bb(data$time)) {
    breath_count <- diff(as.numeric(rownames(changes)))
    last_count <- nrow(data) - as.numeric(rownames(changes)[nrow(changes)])
    changes$breath_count <- c(breath_count, last_count)
    changes <- changes[changes$breath_count > 3, ]
    changes <- changes[c(1, which(diff(changes$load) != 0) + 1), ]
  }

  # calculate duration of each load step
  duration <- c(
    diff(changes$time),
    max(data$time, na.rm = TRUE) - changes$time[nrow(changes)] # last duration
  )

  data.frame(
    duration = round(duration, -1), # round to full 10 seconds
    load = changes$load
  )
}

#' Extract features from an exercise test protocol
#'
#' \code{get_features()} adds characteristic features to the load steps of
#' an exercise testing protocol.
#'
#' @noRd
get_features <- function(protocol) {
  # create empty columns
  protocol$type <- NA
  protocol$code <- NA

  if (protocol$load[[1]] == 0) {
    protocol$type[1] <- "pre measures"
    protocol$code[1] <- 0
  }
  d <- diff(protocol$load[protocol$load != 0]) # calculate differences

  # check if differences between steps are all equal
  # if first difference is unusual, this suggests that a warm-up is present
  # this is only done if the protocol contains more than three load steps
  if (length(d) >= 3) {
    if (d[[1]] != d[[2]] && d[[2]] == d[[3]]) {
      protocol$type[min(which(protocol$load != 0))] <- "warm up"
      protocol$code[min(which(protocol$load != 0))] <- 0.5
    }
  }

  # write load steps and rest
  code_i <- 1
  for (i in which(is.na(protocol$type))) {
    if (protocol$load[i] == 0) { # no load means rest
      protocol$type[i] <- "rest"
      protocol$code[i] <- -1
    } else {
      protocol$type[i] <- "load"
      protocol$code[i] <- code_i
      code_i <- code_i + 1 # consecutive numbers for load steps
    }
  }
  # check whether post measures exist
  # if the load of the last step is less or equal to a third of the last
  # previous step with load, it is considered a post measure (rest or cool-down)
  if (nrow(protocol) > 1) {
    last_load <- protocol$load[nrow(protocol)]
    cut_load <- protocol$load[protocol$load[-nrow(protocol)] != 0]
    # evaluate post measures only if measures with load are available before the
    # last load step
    if (any(isTRUE(cut_load))) {
      if (last_load <= (1 / 3) * cut_load[length(cut_load)]) {
        protocol$type[nrow(protocol)] <- "post measures"
        protocol$code[nrow(protocol)] <- -2
      }
    }
  }
  protocol
}


#' Guess the type of exercise test protocol
#'
#' \code{get_testtype()} guesses which type of testing protocol a exercise test
#' used.
#'
#' @noRd

get_testtype <- function(protocol) {
  if (is.null(protocol) || nrow(protocol) == 1) {
    testtype <- "unknown"
  } else {
    # round load increases to prevent non-exact equality
    d <- round(diff(protocol$load[protocol$type == "load"]), 4)
    t <- protocol$duration[protocol$type == "load"]
    if (all(d[-1] == 0)) { # no load changes
      testtype <- "constant"
    } else if (all(t[-1] < 120)) { # load steps shorter than 120 seconds
      testtype <- "ramp"
    } else if (all(d[-1] == d[2])) { # same increment for all steps
      testtype <- "incremental"
    } else {
      testtype <- "other"
    }
  }
  testtype
}


#' Setting an exercise testing profile
#'
#' \code{set_protocol()} allows to set a load profile for an exercise test
#' based on profile sections.
#'
#' @param ... Functions related to sections of the load profile, such as
#'   \code{pt_pre}, \code{pt_wu}, \code{pt_const} or \code{pt_step}. Sections
#'   will be evaluated in the order they are entered.
#' @param duration A number, giving the duration of the test section or
#'   a single load within the test section (in seconds).
#' @param rest.duration A number, specifying the duration of (each) rest (in
#'   seconds).
#' @param load A number, giving the (initial) load of a section.
#' @param increment A number, giving the difference in load between the current
#'   and the following load step.
#' @param count An integer for the number of load sections.
#' @param last.duration A number, giving the duration of the last load step (in
#' seconds).
#'
#' @return A \code{data.frame} with the duration and load of each protocol step.
#'
#' @seealso [set_protocol_manual] for manual protocol design.
#' @seealso [get_protocol] for automated extracting of protocols from raw data.
#'
#' @examples
#' set_protocol(pt_pre(60), pt_wu(300, 100), pt_steps(180, 150, 25, 8, 30))
#' @export
set_protocol <- function(...) {
  l <- list(...)

  # select only inputs that resulted in data frames
  l <- l[which(vapply(l, class, character(1)) == "data.frame")]

  do.call("rbind", l)
}

#' @describeIn set_protocol Add pre-measures to a load protocol
#' @export

pt_pre <- function(duration) {
  # validate inputs
  if ((duration <= 0) | !is.numeric(duration)) {
    stop("pre measures 'duration' must be an integer greater than 0")
  }

  data.frame(
    duration = duration,
    load = 0
  )
}

#' @describeIn set_protocol Add a warm up to a load protocol
#' @export

pt_wu <- function(duration, load, rest.duration = 0) {
  # validate inputs
  if ((duration <= 0) | !is.numeric(duration)) {
    stop("warm up 'duration' must be an integer greater than 0")
  }
  if ((load < 0) | !is.numeric(load)) {
    stop("warm up 'load' must be an integer equal to or greater than 0")
  }
  if ((rest.duration < 0) | !is.numeric(rest.duration)) {
    stop(
      "warm up 'rest.duration' must be an integer equal to or greater than 0"
    )
  }

  if (rest.duration == 0) { # no rest after warm up
    p <- NULL
    l <- NULL
  } else {
    p <- rest.duration
    l <- 0
  }
  data.frame(
    duration = c(duration, p),
    load = c(load, l)
  )
}

#' @describeIn set_protocol Add a stepwise load protocol
#' @export

pt_steps <- function(duration,
                     load,
                     increment,
                     count,
                     rest.duration = 0,
                     last.duration = NULL) {
  # validate inputs
  if ((duration <= 0) | !is.numeric(duration)) {
    stop("step 'duration' must be an integer greater than 0")
  }
  if ((load < 0) | !is.numeric(load)) {
    stop("intial step 'load' must be an integer equal to or greater than 0")
  }
  if (!is.numeric(increment)) {
    stop("load step 'increment' must be an integer")
  }
  if ((count < 1) | !is.numeric(count)) {
    stop("step 'count' must be an integer equal to or greater than 1")
  }
  count <- round(count)
  if ((rest.duration < 0) | !is.numeric(rest.duration)) {
    stop("step 'rest.duration' must be an integer equal to or greater than 0")
  }
  if (!is.null(last.duration)) {
    if ((last.duration <= 0) | !is.numeric(last.duration)) {
      stop(
        "last step duration 'last.duration' must be an integer greater than 1"
      )
    }
  }

  rest.load <- 0
  if (rest.duration == 0) {
    rest.load <- NULL
    rest.duration <- NULL
  }
  i <- 1
  l <- load
  ds <- NULL
  ls <- NULL
  # repeatedly binds load (and eventually rest) measures until step count is
  # reached
  while (i <= count) {
    ds <- c(ds, duration, rest.duration)
    ls <- c(ls, l, rest.load)
    l <- l + increment
    i <- i + 1
  }

  # change last load duration if necessary
  if (!is.null(last.duration)) {
    ds[max(which(ls != 0))] <- last.duration
  }

  d <- data.frame(
    duration = ds,
    load = ls
  )
  if (is.null(rest.load)) d else d[-nrow(d), ] # remove last rest interval
}

#' @describeIn set_protocol Add a constant load protocol
#' @export

pt_const <- function(duration,
                     load,
                     count,
                     rest.duration = 0,
                     last.duration = NULL) {
  pt_steps(
    duration = duration,
    load = load,
    increment = 0,
    count = count,
    rest.duration = rest.duration,
    last.duration = last.duration
  )
}

#' Manually setting a testing profile
#'
#' \code{set_protocol_manual()} allows to set any user-defined load profile
#' for an exercise test.
#'
#' @param duration Either a numeric vector containing the duration (in seconds)
#'   of each load step, or a \code{data.frame} containing columns for duration
#'   and load.
#' @param load A numeric vector of the same length as \code{duration} containing
#'   the corresponding load of each step. Not needed, if load and duration are
#'   both given in a \code{data.frame} as the first argument of the function.
#'
#' @return A \code{data.frame} with the duration and load of each protocol step.
#'
#' @examples
#' set_protocol_manual(
#'   duration = c(300, 120, 300, 60, 300),
#'   load = c(3, 5, 3, 6, 3)
#' )
#'
#' # using a data.frame as input
#' pt_data <- data.frame(
#'   duration = c(180, 150, 120, 90, 60, 30),
#'   load = c(200, 250, 300, 350, 400, 450)
#' )
#' set_protocol_manual(pt_data)
#' @seealso [set_protocol] for protocol setting with helper functions.
#' @seealso [get_protocol] For automated extracting of protocols from raw data.
#' @export

set_protocol_manual <- function(duration, load = NULL) {
  UseMethod("set_protocol_manual")
}

#' @describeIn set_protocol_manual Default method when duration and load are
#'   given separately
#' @export

set_protocol_manual.default <- function(duration, load) {
  # validate inputs
  if (length(duration) != length(load)) {
    stop("'duration' and 'load' must be vectors of the same length")
  }
  if (any(duration <= 0 | !is.numeric(duration))) {
    stop("'duration' must only contain integers greater than 0")
  }
  if (any(load < 0 | !is.numeric(load))) {
    stop("'load' must only contain integers greater than or equal to 0")
  }

  data.frame(
    duration = duration,
    load = load
  )
}

#' @describeIn set_protocol_manual Method for data frames with a duration and a
#'   load column
#' @export

set_protocol_manual.data.frame <- function(duration, load = NULL) {
  # check if data frame has columns names 'duration' and 'load'
  if (any(names(duration) == "duration") && any(names(duration) == "load")) {
    out <- data.frame(
      duration = duration$duration,
      load = duration$load
    )
    # check if data frame has only two colummns
    # first column will be interpreted as duration, second as load
  } else if (ncol(duration) == 2) {
    out <- data.frame(
      duration = duration[, 1],
      load = duration[, 2]
    )
  } else {
    stop("data.frame must contain columns 'duration' and 'load'")
  }

  # validate result
  if (any(out$duration <= 0 | !is.numeric(out$duration))) {
    stop("'duration' must only contain integers greater than 0")
  }
  if (any(out$load < 0 | !is.numeric(out$load))) {
    stop("'load' must only contain integers greater than or equal to 0")
  }
  out
}
