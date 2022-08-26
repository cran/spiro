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

library(ggplot2)
ar <- arrow(length = unit(0.1, "inches"), type = "closed")
dsblue <- "#0053A4"

## ----setup--------------------------------------------------------------------
library(spiro)

# Get example data
file <- spiro_example("zan_gxt")

spiro(file)


## ----piping, eval = FALSE-----------------------------------------------------
#  # Note: The Base R pipe requires R version 4.1 or greater
#  
#  protocol <- set_protocol(
#    pt_wu(duration = 120, load = 50),
#    pt_steps(duration = 30, load = 100, increment = 20, count = 24)
#  )
#  
#  spiro(file = spiro_example("zan_ramp")) |>
#    add_bodymass(bodymass = 63.4) |>
#    add_protocol(protocol) |>
#    add_hr(hr_file = spiro_example("hr_ramp.tcx"), hr_offset = 0)

## ----import-------------------------------------------------------------------
spiro_import(file, device = NULL)

## ----attr, eval=FALSE---------------------------------------------------------
#  s <- spiro(file)
#  attr(s,"raw")

## ----protocol-----------------------------------------------------------------
s <- spiro(file)
attr(s,"protocol")

## ----set_protocol_manual------------------------------------------------------
# manually setting a test protocol
pt <- set_protocol_manual(
  duration = c(60,300,30,300,30,300,30,300,30,300,30,300,30,300,30,300,30,300),
  load = c(0,3,0,3.2,0,3.4,0,3.6,0,3.8,0,4,0,4.2,0,4.4,0,4.6)
)

# attach protocol within spiro call
s <- spiro(file, protocol = pt)

# attach protocol with `add_protocol`
t <- spiro(file)
add_protocol(t, pt)

## ----set_protocol-variables, echo=FALSE---------------------------------------
ar2 <- arrow(length = unit(0.1, "inches"), type = "closed", ends = "both")
path <- data.frame(
  x = c(0,0.1,0.1,0.3,0.3,0.32,0.32,0.42,0.42,0.44,0.44,0.54,0.54,0.56,0.56,
        0.66,0.66,0.68,0.68,0.78,0.78,0.8,0.8,0.9,0.9,0.95),
  y = c(0,0,0.2,0.2,0,0,0.4,0.4,0,0,0.5,0.5,0,0,0.6,0.6,0,0,
        0.7,0.7,0,0,0.8,0.8,0,0),
  type = factor(
    c("pre","wu","wu","wu","wu",rep("load",21)),
    levels = c("pre","wu","load")
  )
)
ggplot() +
  geom_segment(
    aes(x = 0, xend = 0.95, y = 0, yend = 0),
    colour = "grey", 
    size = 1
  ) +
  geom_path(
    aes(x = x, y = y, colour = type), 
    data = path, 
    size = 1, 
    group = TRUE, 
    show.legend = FALSE
  ) +
  annotate(
    "text", 
    x = c(0.03,0.05,0.05,0.05,0.03), y = c(0.98,0.91,0.84,0.77,0.70), 
    label = c(
      "set_protocol(",
      "pt_pre(duration),",
      "pt_wu(duration, load, rest),",
      "pt_steps(duration, load, increment, count, rest)",
      ")"
    ), 
    hjust = "left", vjust = "top",
    colour = c("black", "#d55e00", "#009e73", dsblue, "black"),
    size = 4.5
  ) +
  scale_x_continuous(
    limits = c(-0.02,1), 
    expand = expansion(0,0), 
    breaks = NULL
  ) +
  scale_y_continuous(
    limits = c(-0.15,1), 
    expand = expansion(0,0), 
    breaks = NULL
  ) +
  scale_colour_manual(values = c("#d55e00","#009e73",dsblue)) +
  labs(x = "time", y = "load") +
  theme_minimal()

## ----set_protocol-------------------------------------------------------------
set_protocol(pt_pre(60), pt_wu(300,80), pt_steps(180,100,25,6,30))

## ----add_weight---------------------------------------------------------------
# set body mass as an argument in `spiro()`
s <- spiro(file, bodymass = 68.3)

# set body mass using `add_weight()`
t <- spiro(file) 
u <- add_bodymass(t, 68.3)


## ----add_hr-------------------------------------------------------------------
# get example data file path
hpath <- spiro_example("hr_ramp.tcx")

# add heart rate data within `spiro()`
h <- spiro(file, hr_file = hpath, hr_offset = 0)

# add heart rate data with `add_hr()`
i <- spiro(file)
j <- add_hr(i, hr_file = hpath, hr_offset = 0)

