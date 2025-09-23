set.seed(777)

library(sits)
library(restoreutils)

#
# General definitions
#
processing_context <- "eco 2"

# Local directories
base_masks_dir <- restoreutils::project_masks_dir()
base_classifications_dir <- restoreutils::project_classifications_dir()

# Mask - tiles (works as a roi)
mask_tiles <- c()

# Mask - version
mask_version <- "v1"

# Classification - version
classification_version <- "samples-v1-2010-eco2"

# Classification - years
classification_year <- 2010

# Hardware - Multicores
multicores <- 35

# Hardware - Memory size
memsize <- 160

#
# 1. Define output directory
#
output_dir <- restoreutils::create_data_dir(
  base_masks_dir / mask_version, classification_year
)

classification_dir <- (
  base_classifications_dir / classification_version / classification_year
)

#
# 2. Load base masks
#

# PRODES data
prodes <- load_prodes_2010(multicores = multicores, memsize = memsize)

# Terraclass
terraclass_2022 <- load_terraclass_2022(multicores = multicores, memsize = memsize)

# Terraclass
terraclass_2010 <- load_terraclass_2010(multicores = multicores, memsize = memsize)

#
# 3. Load classification
#
eco3_class <- load_restore_map_glad(
  data_dir   = classification_dir,
  multicores = multicores,
  memsize    = memsize,
  version    = classification_version,
  tiles      = "MOSAIC"
)

#
# 4. Clean data to reduce noise
#
eco3_class <- sits_clean(
  cube         = eco3_class,
  window_size  = 5,
  multicores   = multicores,
  memsize      = memsize,
  output_dir   = output_dir,
  version      = "mask-clean-step1"
)


#
# 5. Apply reclassification rules
#
# Rule 1
eco3_mask <- restoreutils::reclassify_rule1_secundary_vegetation(
  cube       = eco3_class,
  mask       = prodes,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "mask-prodes-step2"
)

# Rule 2
eco3_mask <- restoreutils::reclassify_rule2_current_deforestation(
  cube       = eco3_mask,
  mask       = prodes,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "mask-prodes-step3",
  rarg_year  = classification_year # <- rule argument: Deforestation year
)

# Rule 3
eco3_mask <- restoreutils::reclassify_rule3_pasture_wetland(
  cube       = eco3_mask,
  mask       = prodes,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "mask-prodes-step4",
  rarg_year  = classification_year # <- rule argument: Deforestation year
)

# Rule 4
eco3_mask <- restoreutils::reclassify_rule4_silviculture(
  cube       = eco3_mask,
  mask       = terraclass_2010,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "mask-prodes-step5"
)

# Rule 5
eco3_mask <- restoreutils::reclassify_rule5_silviculture_pasture(
  cube       = eco3_mask,
  mask       = terraclass_2010,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "mask-prodes-step6"
)

# Rule 6
eco3_mask <- restoreutils::reclassify_rule6_semiperennial(
  cube       = eco3_mask,
  mask       = terraclass_2010,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "mask-prodes-step7"
)

# Rule 7
eco3_mask <- restoreutils::reclassify_rule17_semiperennial_glad(
  cube       = eco3_mask,
  mask       = terraclass_2010,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "mask-prodes-step8"
)

# Rule 8
eco3_mask <- restoreutils::reclassify_rule18_annual_agriculture_glad(
  cube       = eco3_mask,
  mask       = terraclass_2010,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "mask-prodes-step9"
)

# Rule 9
eco3_mask <- restoreutils::reclassify_rule9_minning(
  cube       = eco3_mask,
  mask       = terraclass_2010,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "mask-prodes-step10"
)

# Rule 15
eco3_mask <- restoreutils::reclassify_rule15_urban_area_glad(
  cube           = eco3_mask,
  mask           = terraclass_2010,
  reference_mask = terraclass_2022,
  multicores     = multicores,
  memsize        = memsize,
  output_dir     = output_dir,
  version        = "mask-prodes-step11"
)

# Rule 11
eco3_mask <- restoreutils::reclassify_rule16_water_glad(
  cube       = eco3_mask,
  mask       = terraclass_2010,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "mask-prodes-step12"
)

# Rule 12
eco3_mask <- restoreutils::reclassify_rule12_non_forest(
  cube       = eco3_mask,
  mask       = terraclass_2022,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "mask-prodes-step13"
)


#
# 6. Save cube object
#
saveRDS(eco3_mask, output_dir / "mask-cube.rds")


#
# 7. COG data
#
sf::gdal_addo(eco3_mask[["file_info"]][[1]][["path"]])


#
# Crop cube to tiles
#
if (length(mask_tiles)) {
  cube_files <- crop_to_roi(
    cube        = eco3_mask,
    tiles       = mask_tiles,
    multicores  = multicores,
    output_dir  = output_dir,
    grid_system = "BDC_MD_V2"
  )

  saveRDS(cube_files, output_dir / "mask-cube-tiles.rds")
}
