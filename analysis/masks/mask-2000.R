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
mask_version <- "rules-latest"

# Classification - version
classification_version <- "samples-v1-2010-eco2"

# Classification - years
classification_year <- 2000

# Hardware - Multicores
multicores <- 35

# Hardware - Memory size
memsize    <- 100

# ROI
eco_region_roi <- restoreutils::roi_amazon_regions(
  region_id  = 2,
  crs        = restoreutils::crs_bdc(),
  as_union   = TRUE,
  use_buffer = TRUE
)

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
prodes <- load_prodes_2000(multicores = multicores, memsize = memsize)

# Terraclass
terraclass_2004 <- load_terraclass_2004(multicores = multicores, memsize = memsize)

# Terraclass
terraclass_2008 <- load_terraclass_2008(multicores = multicores, memsize = memsize)

# Terraclass 2014
terraclass_2014 <- load_terraclass_2014(multicores = multicores, memsize = memsize)

# Static water mask
water_mask_static <- load_water_mask(multicores = multicores, memsize = memsize)

#
# 3. Load classification
#
eco_class <- load_restore_map_glad(
  data_dir   = classification_dir,
  multicores = multicores,
  memsize    = memsize,
  version    = classification_version,
  tiles      = "MOSAIC"
)

#
# 4. Clean data to reduce noise
#
eco_class <- sits_clean(
  cube         = eco_class,
  window_size  = 5,
  multicores   = multicores,
  memsize      = memsize,
  output_dir   = output_dir,
  version      = "step1"
)

#
# 5. Apply reclassification rules
#
eco_mask <- restoreutils::reclassify_rule1_secundary_vegetation(
  cube       = eco_class,
  mask       = prodes,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "step2"
)

eco_mask <- restoreutils::reclassify_rule0_forest(
  cube       = eco_mask,
  mask       = prodes,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "step3"
)

eco_mask <- restoreutils::reclassify_rule3_pasture_wetland(
  cube       = eco_mask,
  mask       = prodes,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "step4",
  rarg_year  = classification_year # <- rule argument: Deforestation year
)

eco_mask <- restoreutils::reclassify_rule4_silviculture(
  cube       = eco_mask,
  mask       = terraclass_2008,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "step5"
)

eco_mask <- restoreutils::reclassify_rule5_silviculture_pasture(
  cube       = eco_mask,
  mask       = terraclass_2008,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "step6"
)

eco_mask <- restoreutils::reclassify_rule6_semiperennial(
  cube       = eco_mask,
  mask       = terraclass_2008,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "step7"
)

eco_mask <- restoreutils::reclassify_rule17_semiperennial_glad(
  cube       = eco_mask,
  mask       = terraclass_2008,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "step8"
)

eco_mask <- restoreutils::reclassify_rule18_annual_agriculture_glad(
  cube       = eco_mask,
  mask       = terraclass_2004,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "step9"
)

eco_mask <- restoreutils::reclassify_rule8_annual_agriculture_v2(
  cube       = eco_mask,
  mask       = terraclass_2004,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "step10"
)

eco_mask <- restoreutils::reclassify_rule23_pasture_deforestation_in_nonforest(
  cube       = eco_mask,
  mask       = prodes,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "step11"
)

eco_mask <- restoreutils::reclassify_rule9_minning(
  cube       = eco_mask,
  mask       = terraclass_2004,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "step12"
)

eco_mask <- restoreutils::reclassify_rule10_urban_area(
  cube           = eco_mask,
  mask           = terraclass_2008,
  multicores     = multicores,
  memsize        = memsize,
  output_dir     = output_dir,
  version        = "step13"
)

eco_mask <- restoreutils::reclassify_rule21_pasture_annual_agriculture(
  cube           = eco_mask,
  mask           = terraclass_2008,
  multicores     = multicores,
  memsize        = memsize,
  output_dir     = output_dir,
  rarg_year      = classification_year,
  version        = "step14"
)

eco_mask <- restoreutils::reclassify_rule21_pasture_annual_agriculture(
  cube           = eco_mask,
  mask           = terraclass_2014,
  multicores     = multicores,
  memsize        = memsize,
  output_dir     = output_dir,
  rarg_year      = classification_year,
  version        = "step15"
)

eco_mask <- restoreutils::reclassify_rule28_secundary_vegetation_tc(
  cube           = eco_mask,
  mask           = NULL,
  multicores     = multicores,
  memsize        = memsize,
  output_dir     = output_dir,
  rarg_year      = classification_year,
  version        = "step16"
)

eco_mask <- restoreutils::reclassify_rule2_current_deforestation(
  cube       = eco_mask,
  mask       = prodes,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "step17",
  rarg_year  = classification_year # <- rule argument: Deforestation year
)

eco_mask <- restoreutils::reclassify_rule12_non_forest(
  cube       = eco_mask,
  mask       = prodes,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "step18"
)

eco_mask <- restoreutils::contextual_cleaner(
  cube         = eco_mask,
  window_size  = 15L,
  target_class = as.numeric(names(sits_labels(eco_mask)[sits_labels(eco_mask) == "2ciclos"])),
  mode_class   = as.numeric(names(sits_labels(eco_mask)[sits_labels(eco_mask) == "area_urbanizada"])),
  multicores   = multicores,
  memsize      = memsize,
  output_dir   = output_dir,
  version      = "step19"
)

eco_mask <- restoreutils::reclassify_rule16_water_glad(
  cube       = eco_mask,
  mask       = terraclass_2008,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "step20"
)

eco_mask <- restoreutils::reclassify_rule25_static_water_mask(
  cube       = eco_mask,
  mask       = water_mask_static,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "step21"
)

eco_mask <- restoreutils::reclassify_rule19_perene(
  cube       = eco_mask,
  mask       = terraclass_2008,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  rarg_year  = classification_year,
  version    = "step22"
)

eco_mask <- restoreutils::reclassify_rule26_silviculture_pasture_vs(
  cube       = eco_mask,
  mask       = terraclass_2008,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "step23"
)

# Crop
eco_mask <- sits_mosaic(
  cube       = eco_mask,
  crs        = restoreutils::crs_bdc(),
  roi        = eco_region_roi,
  multicores = multicores,
  output_dir = output_dir,
  version    = "step24"
)

#
# 6. Save cube object
#
saveRDS(eco_mask, output_dir / "mask-cube.rds")


#
# 7. COG data
#
sf::gdal_addo(eco_mask[["file_info"]][[1]][["path"]])


#
# Crop cube to tiles
#
if (length(mask_tiles)) {
  cube_files <- crop_to_roi(
    cube        = eco_mask,
    tiles       = mask_tiles,
    multicores  = multicores,
    output_dir  = output_dir,
    grid_system = "BDC_MD_V2"
  )

  saveRDS(cube_files, output_dir / "mask-cube-tiles.rds")
}
