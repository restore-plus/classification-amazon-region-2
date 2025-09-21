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
regularization_years <- 2020:2024 # 2015:2019

# Hardware - Multicores
multicores <- 35

# Hardware - Memory size
memsize <- 320


#
# 1. Load eco region roi
#
eco_region_roi <- restoreutils::roi_ecoregions(
  region_id = 2,
  crs       = restoreutils::crs_bdc(),
  as_convex = TRUE
)


#
# 2. Get BDC tiles intersecting eco 2
#
bdc_tiles <- sits_roi_to_tiles(
  eco_region_roi,
  crs = restoreutils::crs_bdc(),
  grid_system = "BDC_MD_V2"
)

bdc_tiles_bbox <- sf::st_union(bdc_tiles) |>
  sf::st_bbox()


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

  # Define year tiles
  current_year_tiles <- bdc_tiles

  # Loading existing cube
  existing_cube <- tryCatch(
    {
      sits_cube(
        source      = "BDC",
        collection  = "LANDSAT-OLI-16D",
        data_dir    = cube_year_dir,
        progress    = FALSE
      )
    },
    error = function(e) {
      return(NULL)
    }
  )

  # Inform user about the current number of tiles
  print(paste0('Total number of tiles: ', nrow(current_year_tiles)))

  if (!is.null(existing_cube)) {
    # Getting tiles
    existing_tiles <- unique(existing_cube[["tile"]])

    # Removing all existing tiles
    current_year_tiles <- dplyr::filter(current_year_tiles, !(.data[["tile_id"]] %in% existing_tiles))

    # Inform user
    print(paste0('Existing tiles: ', length(existing_tiles)))
  }

  # Inform user about the current number of tiles to be processed
  # (some can be removed thanks to the existing data)
  print(paste0('Tiles to process: ', nrow(current_year_tiles)))

  # Regularize tile by tile
  purrr::map(current_year_tiles[["tile_id"]], function(tile) {
    print(tile)

    # Load cube with tryCatch error handling
    cube_year <- tryCatch(
      {
        sits_cube(
          source      = "BDC",
          collection  = "LANDSAT-OLI-16D",
          tiles       = tile,
          start_date  = cube_start_date,
          end_date    = cube_end_date,
          bands       = cube_bands
        )
      },
      error = function(e) {
        return(NULL)
      }
    )

    if (is.null(cube_year) || nrow(cube_year) == 0) {
      return(NULL)
    }

    # Regularize
    cube_year_reg <- sits_regularize(
      cube        = cube_year,
      period      = "P1M",
      res         = 30,
      multicores  = multicores,
      output_dir  = cube_year_dir,
      timeline    = cube_timeline
    )

    if (nrow(cube_year_reg) == 0) {
      return(NULL)
    }

    # Generate indices
    cube_year_reg <- restoreutils::cube_generate_indices_bdc(
      cube       = cube_year_reg,
      output_dir = cube_year_dir,
      multicores = multicores,
      memsize    = memsize
    )
  })

  restoreutils::notify(
    processing_context, paste("generate cubes > finalizing", regularization_year)
  )
}
