## ----options, include = FALSE-------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  out.width = "90%",
  fig.width = 6,
  fig.asp = 0.618,
  fig.align = "center",
  dpi = 300
)

## ----setup--------------------------------------------------------------------
library(spiro)

# import and process example data
file <- spiro_example("zan_gxt")
gxt_data <- spiro(file)
gxt_data


## ----spiro_summary------------------------------------------------------------
spiro_summary(gxt_data, interval = 120)

## ----spiro_max----------------------------------------------------------------
spiro_max(gxt_data, smooth = 30)

## ----spiro_plot, fig.width = 10, fig.height = 8, message = FALSE--------------
# load example data
data <- spiro(spiro_example("zan_ramp"), hr_file = spiro_example("hr_ramp.tcx"))

spiro_plot(data)

## ----spiro_plot-select, fig.width = 7, fig.height = 4-------------------------
# Plot only V-Slope (Panel 5) and VO2/VCO2 over time (Panel 3)
spiro_plot(data, which = c(5,3))

## ----spiro_plot-style, fig.width = 10, fig.height = 8, message = FALSE--------
# Change base size and axis label font
spiro_plot(
  data, 
  base_size = 9, 
  axis.title = ggplot2::element_text(face = "italic", colour = "blue")
)

