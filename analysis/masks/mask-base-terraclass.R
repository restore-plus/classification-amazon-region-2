library(sits)
library(restoreutils)

#
# General definitions
#
memsize    <- 100
multicores <- 35

year_to_prepare <- c(2004, 2008, 2010, 2012, 2014, 2018, 2020, 2022)

#
# 1) Download Terraclass data
#
restoreutils::prepare_terraclass(
    years            = year_to_prepare,
    region_id        = 2,
    multicores       = multicores,
    memsize          = memsize,
    fix_other_uses   = TRUE,
    fix_urban_area   = TRUE,
    fix_non_forest   = TRUE,
    fix_non_observed = TRUE
)
