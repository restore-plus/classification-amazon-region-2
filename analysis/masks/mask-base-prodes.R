library(sits)
library(restoreutils)

#
# General definitions
#
memsize    <- 100
multicores <- 35

version <- "v2"

years_to_prepare <- c(2000:2007, 2024)
years_to_mask <- c(2000:2024)

#
# 1) Download Prodes data
#
restoreutils::prepare_prodes(
  region_id = 2,
  years     = years_to_prepare
)


#
# 2) Generate forest mask
#
purrr::map(years_to_mask, function(mask_year) {
  restoreutils::prodes_generate_mask(
    target_year    = mask_year,
    version        = version,
    multicores     = multicores,
    memsize        = memsize,
    nonforest_mask = TRUE
  )
})
