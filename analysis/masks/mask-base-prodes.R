library(sits)
library(restoreutils)

#
# General definitions
#
memsize    <- 100
multicores <- 35

version <- "v2"

year_to_prepare <- 2024:2008

#
# 1 Generate forest mask
#
prepare_prodes(
  region_id          = 2,
  years              = year_to_prepare,
  version            = version,
  multicores         = multicores,
  memsize            = memsize,
  nonforest_mask     = TRUE,
  nonforest_complete = TRUE,
  fix_pre_aggregation_prodes = TRUE
)
