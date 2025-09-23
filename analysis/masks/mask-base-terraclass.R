library(sits)
library(restoreutils)

#
# Config: Connection timeout
#
options(timeout = max(600, getOption("timeout")))


#
# 1) Download Terraclass data
#
restoreutils::prepare_terraclass(
    years      = c(2004, 2008, 2010, 2012, 2014, 2018, 2020, 2022),
    region_id  = 2,
    multicores = 1
)
