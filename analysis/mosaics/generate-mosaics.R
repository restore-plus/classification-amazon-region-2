set.seed(777)

library(sits)
library(restoreutils)

#
# General definitions
#
processing_context <- "eco 2"

# Local directories
base_cubes_dir <- restoreutils::project_cubes_dir()
base_mosaic_dir <- restoreutils::project_mosaics_dir()
base_classifications_dir <- restoreutils::project_classifications_dir()

# Dropbox directory
base_dropbox_dir <- restoreutils::dropbox_dir("mosaic")

# Bands
bands <- c("SWIR16", "NIR08", "BLUE")

# Processing years
regularization_years <- 2015:2024

# Hardware - Multicores
multicores <- 60


#
# 1. Load eco region 2 shape
#
eco_region_roi <- restoreutils::roi_ecoregions(region_id = 2,
                                               crs = restoreutils::crs_bdc(),
                                               as_file = TRUE)


#
# 2. Generate mosaics
#
restoreutils::notify(processing_context, "generate mosaics > initialized")

for (regularization_year in regularization_years) {
  print(regularization_year)

  # Define local directories
  cube_dir <- restoreutils::create_data_dir(base_cubes_dir, regularization_year)
  mosaic_dir <- restoreutils::create_data_dir(base_mosaic_dir, regularization_year)

  # Define dropbox directory
  dropbox_dir <- base_dropbox_dir / regularization_year

  # Create output dir
  fs::dir_create(mosaic_dir, recurse = TRUE)

  # Load cube
  cube <- sits_cube(
    source     = "BDC",
    collection = "LANDSAT-OLI-16D",
    bands      = bands,
    data_dir   = cube_dir
  )

  # Transform cube to tiles
  tryCatch({
    restoreutils::notify(processing_context,
                         paste("generate mosaics > processing", regularization_year))

    tiles <- restoreutils::cube_to_rgb_mosaic(
      cube       = cube,
      output_dir = mosaic_dir,
      roi_file   = eco_region_roi,
      bands      = bands,
      multicores = multicores
    )
  }, error = function(e) {
    restoreutils::notify(processing_context,
                         "generate mosaics > error to generate tiles!")
  })

  # Upload content to Dropbox
  tryCatch({
    restoreutils::notify(processing_context,
                         paste("generate mosaics > uploading to dropbox", regularization_year))

    tiles <- restoreutils::dropbox_upload(files = tiles, dropbox_dir = dropbox_dir)
  }, error = function(e) {
    restoreutils::notify(processing_context,
                         "generate mosaics > error to upload files to dropbox!")
  })
}
