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
classification_years <- c(2022:2014, 1996)

# Cube directory
cube_base_dir <- get_cubes_dir()

#
# Hardware definitions
#

# Multicores
multicores <- 64

# Memory size
memsize <- 220

#
# 1. Generate indices
#
for (classification_year in classification_years) {
  #
  # 1.1. Define cube directory
  #
  cube_dir <- path(cube_base_dir) / classification_year

  #
  # 1.2. Load cube
  #
  cube <- sits_cube(
    source     = "MPC",
    collection = "LANDSAT-C2-L2",
    data_dir   = cube_dir
  )

  #
  # 1.3. Generate NDVI
  #
  cube <- sits_apply(
      data       = cube,
      NDVI       = (NIR08 - RED) / (NIR08 + RED),
      output_dir = cube_dir,
      multicores = multicores,
      memsize    = memsize,
      progress   = TRUE
  )

  #
  # 1.4. Generate EVI (https://www.usgs.gov/landsat-missions/landsat-enhanced-vegetation-index)
  #
  cube <- sits_apply(
      data       = cube,
      EVI        = 2.5 * (( NIR08 - RED ) / (NIR08 + 6 * RED - 7.5 * BLUE + 1)),
      output_dir = cube_dir,
      multicores = multicores,
      memsize    = memsize,
      progress   = TRUE
  )

  #
  # 1.5. Generate MNDWI
  #
  cube <- sits_apply(
      data       = cube,
      MNDWI      = (GREEN - SWIR16) / (GREEN + SWIR16),
      output_dir = cube_dir,
      multicores = multicores,
      memsize    = memsize,
      progress   = TRUE
  )

  #
  # 1.6. Generate NBR (https://www.usgs.gov/landsat-missions/landsat-normalized-burn-ratio)
  #
  cube <- sits_apply(
      data       = cube,
      NBR        = ( NIR08 - SWIR22 ) / ( NIR08 + SWIR22 ),
      output_dir = cube_dir,
      multicores = multicores,
      memsize    = memsize,
      progress   = TRUE
  )
}
