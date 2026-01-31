library(sits)
library(restoreutils)

#
# General definitions
#

# Base datacube directories
base_cubes_dir <- restoreutils::project_cubes_dir()

# Samples
samples_file <- "data/raw/samples/samples_amazon_landsat_2010.csv"

# Output dir
base_output_dir <- "data/derived/"

# Samples version
samples_version <- "samples_amazon_landsat_2010"

# Reference year
samples_reference_year <- 2010

# Hardware - multicores
multicores <- 40


#
# 1. Create output directories
#
samples_dir <- restoreutils::create_data_dir(base_output_dir, "timeseries")


#
# 2. Load existing samples
#
samples_raw <- readr::read_csv(samples_file)


#
# 3. Load data cube
#
cube_dir <- base_cubes_dir / samples_reference_year

cube <- sits_cube(
  source      = "OGH",
  collection  = "LANDSAT-GLAD-2M",
  data_dir    = cube_dir
)

cube_timeline <- sits_timeline(cube)


#
# 4. Extract time-series
#
samples_ts <- sits_get_data(
  cube = cube,
  samples = samples_raw,
  multicores = multicores
)


#
# 5. Save samples
#
saveRDS(samples_ts, samples_dir / paste0(samples_version, ".rds"))
