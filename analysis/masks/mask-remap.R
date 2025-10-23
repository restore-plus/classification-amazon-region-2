library(sits)
library(restoreutils)

#
# General definitions
#

# Local directories
base_masks_dir <- restoreutils::project_masks_dir()

temporal_mask_dir <- base_masks_dir / "rules-latest" / "results"

remap_dir <-  temporal_mask_dir / "remap"
release_dir <-  temporal_mask_dir / "release"

# Hardware resources
memsize    <- 100
multicores <- 35

# Mask - version
mask_version <- "rules-latest"

temporal_version <- "temporal-mask-3"

# Years
years_to_apply <- 2000:2022

# file template
file_template <- "LANDSAT_OLI_MOSAIC_%d-01-01_%d-01-31_class_%s.tif"

# Create output dir
fs::dir_create(c(remap_dir, release_dir))

# Redefine cube
cube <- purrr::map_dfr(years_to_apply, function(year) {
  year_dir <- base_masks_dir / mask_version / year

  # Define rds file
  rds_file <- year_dir / "mask-cube.rds"

  # Read rds
  cube <- readRDS(rds_file)

  # Define file year
  file_year <- sprintf(file_template, year, year, temporal_version)

  # Update cube file info
  cube[["file_info"]][[1]][["path"]] <- temporal_mask_dir / temporal_version / file_year

  # Define cube year
  cube[["date"]] <- year

  # return cube
  cube
})

purrr::map(seq_len(nrow(cube)), function(idx) {
  tile <- cube[idx, ]

  restoreutils::cube_save_area_stats(
    cube       = tile,
    multicores = multicores,
    memsize    = memsize,
    res        = 30,
    output_dir = remap_dir,
    version    = tile[["date"]]
  )
})

# Remapping for reference map
cube <- restoreutils::cube_remap(
  cube       = cube,
  output_dir = remap_dir,
  multicores = multicores,
  memsize    = memsize
)

# Remapping for release map
cube <- restoreutils::cube_remap(
  cube       = cube,
  output_dir = release_dir,
  multicores = multicores,
  memsize    = memsize,
  rules      = restoreutils::restore_mapping_release_table()
)
