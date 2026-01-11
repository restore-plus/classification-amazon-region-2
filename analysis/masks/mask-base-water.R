library(sits)
library(restoreutils)

#
# General definitions
#
multicores <- 100

#
# 1) Prepare water mask
#
restoreutils::prepare_water_mask(
  region_id        = 2,
  multicores       = multicores
)
