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
cube_bands <- c("BLUE", "GREEN", "RED", "NIR" , "SWIR1", "SWIR2")

# Processing years
regularization_years <- c(2010)

# Hardware - Multicores (Download)
multicores <- 10

# Hardware - Multicores (Regularize)
multicores_reg <- 40

# Hardware - Memory size
memsize <- 172


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

  # Define year tiles
  current_year_tiles <- bdc_tiles

  # Loading existing cube
  existing_cube <- tryCatch(
    {
      sits_cube(
        source      = "OGH",
        collection  = "LANDSAT-GLAD-2M",
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

  # Load cube
  cube_year <- sits_cube(
    source      = "OGH",
    collection  = "LANDSAT-GLAD-2M",
    roi         = bdc_tiles_bbox,
    crs         = "EPSG:4326",
    start_date  = cube_start_date,
    end_date    = cube_end_date,
    bands       = cube_bands
  )

  if (nrow(cube_year) == 0) {
    return(NULL)
  }

  # Regularize tile by tile
  purrr::map(current_year_tiles[["tile_id"]], function(tile) {
    print(tile)

    # Regularize
    cube_year_reg <- tryCatch(
      {
        sits_regularize(
          cube        = cube_year,
          period      = "P2M",
          res         = 30,
          tiles       = tile,
          grid_system = "BDC_MD_V2",
          multicores  = multicores,
          output_dir  = cube_year_dir
        )
      },
      error = function(e) {
        return(NULL)
      }
    )

    if (is.null(cube_year_reg) || nrow(cube_year_reg) == 0) {
      return(NULL)
    }

    # Generate indices
    cube_year_reg <- restoreutils::cube_generate_indices_glad(
      cube = cube_year_reg,
      output_dir = cube_year_dir,
      multicores = multicores_reg,
      memsize = memsize
    )
  })

  restoreutils::notify(
    processing_context, paste("generate cubes > finalizing", regularization_year)
  )
}
