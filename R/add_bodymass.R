#' Calculate additional variables related to body mass for cardiopulmonary
#' exercise testing data
#'
#' \code{add_bodymass()} adds body mass-related variables to processed gas
#' exchange data.
#'
#' Based on an individual's body mass, relative oxygen uptake (VO2_rel) and
#' carbon dioxide output (VCO2_rel) are calculated. For running protocols,
#' running economy (RE) is calculated.
#'
#' @param bodymass A numeric value to manually set the participant's body mass.
#'   Defaults to NULL to use body mass data from the file's meta data. Set to NA
#'   to ignore the meta data without setting a new body mass.
#'
#' @inheritParams spiro_max
#'
#' @return A \code{data.frame} of the class \code{spiro} containing the
#'   cardiopulmonary exercise testing data including variables related to body
#'   mass.
#' @examples
#' # get example file
#' file <- spiro_example("zan_gxt")
#'
#' s <- spiro(file)
#' out <- add_bodymass(s, bodymass = 65.3)
#' head(out)
#' @export
add_bodymass <- function(data, bodymass = NULL) {
  if (!is.null(bodymass) & !anyNA(bodymass)) {
    if (!is.numeric(bodymass) | length(bodymass) != 1) {
      stop("'bodymass' must be a single numeric value")
    } else if (bodymass <= 0) {
      stop("'bodymass' must be greater than 0")
    }
  } else {
    bodymass <- attr(data, "info")$bodymass
  }

  # no body mass found
  if (is.na(bodymass)) {
    warning("No 'bodymass' data available", call. = FALSE)
  }

  # calculate data relative to body bodymass
  data$VO2_rel <- data$VO2 / bodymass
  data$VCO2_rel <- data$VCO2 / bodymass

  # calculate running economy if applicable
  # check if protocol was a running exercise
  if (!all(is.null(data$load)) && (max(data$load) < 30)) {
    data$RE <- (100 / 6) * (data$VO2_rel / data$load)
    for (i in seq_along(data$RE)) { # result NAs for rest sections
      if (is.na(data$RE[[i]])) {
        data$RE[[i]] <- NA
      } else if (data$RE[[i]] >= 1000) {
        data$RE[[i]] <- NA
      }
    }
  }

  # save possible new body mass data in the meta attribute
  attr(data, "info")$bodymass <- bodymass

  data
}
