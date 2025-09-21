library(sits)
library(restoreutils)

#
# Config: Connection timeout
#
options(timeout = max(600, getOption("timeout")))


#
# General definitions
#
memsize    <- 200
multicores <- 60

version <- "v2"

mask_years <- 2015:2022


#
# 1) Download Prodes data
#
restoreutils::prepare_prodes(
    region_id = 2
)


#
# 2) Generate forest mask
#
# Note: We start generating masks in 2023, as 2024 is the most recent data, and
#       all forest there is the current forest. So, there is no requirements for
#       extra data transformations
#
purrr::map(mask_years, function(mask_year) {
  restoreutils::prodes_generate_forest_mask(
    target_year   = mask_year,
    version       = version,
    multicores    = multicores,
    memsize       = memsize
  )
})

