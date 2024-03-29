#' Summarize data from cardiopulmonary exercise testing for each load step
#'
#' \code{spiro_summary()} returns a \code{data.frame} summarizing the main
#' parameters for each step of a cardiopulmonary exercise test.
#'
#' This function generates mean values of gas exchange and cardiac parameters
#' for all steps of an exercise test. The calculation returns the mean of a
#' given \code{interval} before the end of each step.
#'
#' If the interval exceeds the duration of any step, a message will be
#' displayed. If the interval exceeds the duration of all steps, it will be
#' reset to the duration of the longest step. You can silence all messages by
#' setting \code{quiet = TRUE}.
#'
#' When setting \code{exclude = TRUE} the function will check whether the last
#' load step was terminated early. If this was the case, the step will not be
#' displayed in the summary.
#'
#' @param data A \code{data.frame} of the class \code{spiro}, as it is generated
#'   by \code{\link{spiro}}.
#' @param interval An integer giving the length of the computational interval in
#'   seconds.
#' @param quiet A logical value, whether or not messages should be displayed,
#'   for example when intervals are shortened for specific steps.
#' @param exclude A logical value, whether the last step should be excluded from
#'   the summary if it was not completely performed.
#'
#' @return A \code{data.frame} with the mean parameters for each step of the
#'   exercise protocol.
#'
#' @examples
#' # Import and process example data
#' gxt_data <- spiro(file = spiro_example("zan_gxt"))
#'
#' spiro_summary(gxt_data)
#' @export

spiro_summary <- function(data,
                          interval = 120,
                          quiet = FALSE,
                          exclude = FALSE) {
  # step wise summary only works when load step are available
  protocol <- attr(data, "protocol")
  if (is.null(protocol)) {
    stop("Data does not contain an exercise protocol")
  }

  # input validation
  if (!is.numeric(interval)) {
    stop("'interval' must be an integer")
  } else if (interval < 1) {
    stop("'interval' must be greater or equal to 1")
  }

  if (!is.logical(quiet)) {
    stop("'quiet' must be either TRUE or FALSE")
  }

  if (!is.logical(exclude)) {
    stop("'exclude' must be either TRUE or FALSE")
  }


  # special handle, if all load steps are less than interval
  # interval will be given the value of the longest step
  if (all(protocol$duration[protocol$type == "load"] < interval)) {
    interval <- max(protocol$duration[protocol$type == "load"])
    if (!quiet) {
      message(
        sprintf("for load steps, interval was set to %s seconds", interval)
      )
    }
  }

  # optionally exclude non-finished last load step
  if (exclude) {
    # get all durations of load steps
    all_durations <- protocol$duration[protocol$code > 0]
    last_num <- length(all_durations)
    # check if last step was shorter than all other steps
    if (all(all_durations[last_num] < all_durations[-last_num])) {
      data <- data[data$step != max(data$step), ] # exclude step
      if (!quiet) {
        message(
          paste0(
            "Last step was excluded from summary calculation ",
            "due to termination of the test"
          )
        )
      }
    }
  }

  out <- lapply(unique(data$step)[unique(data$step) >= 0], getstepmeans,
    data = data,
    interval = interval,
    quiet = quiet
  )
  out_df <- do.call("rbind", out)

  # write calculation interval as attribute (useful for reactive environments)
  attr(out_df, "interval") <- interval

  # assign to spiro class (for separate printing methods)
  class(out_df) <- c("spiro", "data.frame")

  out_df
}

#' Get mean data values for one load step of an exercise test
#'
#' \code{getstepmeans()} returns the average data values for a single step of an
#' exercise test.
#'
#' @noRd
getstepmeans <- function(step_number, data, interval = 30, quiet = FALSE) {
  # filter data for desired step number and delete unneeded columns
  step <- data[
    data$step == step_number,
    !colnames(data) %in% c("step", "time", "VCO2_rel", "RR", "VT")
  ]

  # get start of calculation interval
  if (nrow(step) >= interval) { # step longer than interval
    cstart <- nrow(step) - (interval - 1)
  } else { # step shorter than interval
    cstart <- 1
    if (!quiet) {
      if (step_number == 0) { # pre measures
        message(
          sprintf(
            paste0(
              "for pre-measures, interval was set to ",
              "length of measures (%s seconds)"
            ),
            nrow(step)
          )
        )
      } else if (step_number == 0.5) { # warm up
        message(
          sprintf(
            paste0(
              "for warm-up measures, ",
              "interval was set to length of warm-up (%s seconds)"
            ),
            nrow(step)
          )
        )
      } else { # load steps
        message(
          sprintf(
            "for step %s, interval was set to length of step (%s seconds)",
            step_number, nrow(step)
          )
        )
      }
    }
  }

  # filter data within calculation interval
  stepend <- step[cstart:nrow(step), ]

  # calculate mean values
  df <- data.frame(
    step_number = step_number,
    duration = nrow(step),
    t(colMeans(stepend, na.rm = TRUE))
  )

  # Replace missing values with NAs
  df[1, which(is.na(df))] <- NA

  df
}
