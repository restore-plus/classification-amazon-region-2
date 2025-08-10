set.seed(777)

library(sits)
library(restoreutils)

#
# General definitions
#
processing_context <- "eco 2"

# Output dir
cubes_dir <- restoreutils::project_cubes_dir()

# Bands
cube_bands <- c("BLUE", "GREEN", "RED", "NIR08", "SWIR16", "SWIR22", "CLOUD")

# Processing years
regularization_years <- 2015:2024

# Hardware - Multicores
multicores <- 60

# Hardware - Memory size
memsize <- 220


#
# 1. Load eco region roi
#
eco_region_roi <- restoreutils::roi_ecoregions(
  region_id = 2,
  crs = restoreutils::crs_bdc()
)


#
# 2. Get BDC tiles intersecting eco 2
#
bdc_tiles <- sits_roi_to_tiles(
  eco_region_roi,
  crs = restoreutils::crs_bdc(),
  grid_system = "BDC_MD_V2"
)


#
# 3. Process cubes
#
restoreutils::notify(processing_context, "generate cubes > initialized")

for (regularization_year in regularization_years) {
  restoreutils::notify(
    processing_context, paste("generate cubes > processing", regularization_year)
  )

  # Define cube dir
  cube_year_dir <- restoreutils::create_data_dir(cubes_dir, regularization_year)

  # Define cube ``start date`` and ``end date``
  cube_start_date <- paste0(regularization_year, "-01-01")
  cube_end_date   <- paste0(regularization_year, "-12-31")

  # Create cube timeline (P1M)
  cube_timeline <- tibble::tibble(month = 1:12) |>
    dplyr::mutate(date = as.Date(paste0(
      regularization_year, "-", sprintf("%02d", month), "-01"
    ))) |>
    dplyr::pull()

  # Regularize tile by tile
  purrr::map(bdc_tiles[["tile_id"]], function(tile) {
    print(tile)

    # Load cube
    cube_year <- sits_cube(
      source      = "BDC",
      collection  = "LANDSAT-OLI-16D",
      tiles       = tile,
      grid_system = "BDC_MD_V2",
      start_date  = cube_start_date,
      end_date    = cube_end_date,
      bands       = cube_bands
    )

    if (nrow(cube_year) == 0) {
      return(NULL)
    }

    # Regularize
    cube_year_reg <- sits_regularize(
      cube        = cube_year,
      period      = "P1M",
      res         = 300,
      multicores  = multicores,
      output_dir  = cube_year_dir,
      timeline    = cube_timeline
    )

    if (nrow(cube_year_reg) == 0) {
      return(NULL)
    }

    # Generate indices
    cube_year_reg <- restoreutils::cube_generate_indices(
      cube = cube_year_reg,
      output_dir = cube_year_dir,
      multicores = multicores,
      memsize = memsize
    )
  })

  restoreutils::notify(
    processing_context, paste("generate cubes > finalizing", regularization_year)
  )
}
