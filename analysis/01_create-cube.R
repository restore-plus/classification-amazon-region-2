set.seed(777)

library(sf)
library(fs)
library(sits)
library(dplyr)
library(classificationamazonregion2)

#
# Cube definitions
#

# Cube dates
cube_years <- c(2022:2014, 1996)

# Bands
cube_bands <- c("BLUE", "GREEN", "RED", "NIR08" , "SWIR16", "SWIR22", "CLOUD")

# Cube directory
cube_base_dir <- get_cubes_dir()

# Region
cube_region_file <- "data/raw/region/amazon-regions-bdc-md.gpkg"

#
# Hardware definitions
#

# Multicores
multicores <- 64

# Memory size
memsize    <- 220

#
# 1. Create cube directory
#
fs::dir_create(cube_base_dir, recurse = TRUE)

#
# 2. Load region file
#
region <- st_read(cube_region_file)

#
# 3. Filter region for region number 2
#
region <- filter(region, layer == "eco_2")

region <- st_union(st_convex_hull(region))

#
# 4. Generate cubes
#
for (cube_year in cube_years) {
  print(paste0("Processing: ", cube_year))

  #
  # 4.1. Define cube dates
  #
  start_date <- paste0(cube_year, "-01-01")
  end_date   <- paste0(cube_year, "-12-31")

  #
  # 4.2. Define regularization timeline (P3M)
  #
  regularization_timeline <- c(
    paste0(cube_year, "-01-01"),
    paste0(cube_year, "-04-01"),
    paste0(cube_year, "-07-01"),
    paste0(cube_year, "-10-01")
  )

  regularization_timeline <- as.Date(regularization_timeline)

  #
  # 4.3. Define platform
  #
  platform <- NULL

  if (cube_year >= 2014) {
    platform <- "LANDSAT-8"
  }

  #
  # 4.4. Create a directory for the current year
  #
  cube_dir_year <- path(cube_base_dir) / cube_year

  fs::dir_create(cube_dir_year, recurse = TRUE)

  #
  # 4.5. Load cube
  #
  cube_year <- sits_cube(
    source     = "MPC",
    platform   = platform,
    collection = "LANDSAT-C2-L2",
    roi        = region,
    start_date = start_date,
    end_date   = end_date,
    bands      = cube_bands
  )

  #
  # 4.6. Regularize
  #
  reg_cube <- sits_regularize(
    cube        = cube_year,
    period      = "P3M",
    res         = 30,
    multicores  = multicores,
    output_dir  = cube_dir_year,
    grid_system = "BDC_MD_V2",
    timeline    = regularization_timeline
  )
}
