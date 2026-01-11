library(sits)
library(restoreutils)

#
# General definitions
#

# Local directories
base_masks_dir <- restoreutils::project_masks_dir()

# Mask - version
mask_version <- "rules-latest"

# Hardware - Multicores
multicores <- 35

# Hardware - Memory size
memsize    <- 100

#
# 1. Generate directories
#
output_dir <- create_data_dir(base_masks_dir / mask_version, "results")


#
# 2. Get masks files
#
files <- restoreutils::get_restore_rds_files(mask_version)

#
# 3. Apply water consistency rule
#

# Define output dir
water_year <- 2019
water_version <- "temporal-mask-1"
water_output_dir <- output_dir / water_version / water_year

# Define years to apply
water_mask_years <- c(2018, 2019, 2020)

# Filter years to apply
files_water <- files[files[["year"]] %in% water_mask_years,]

# Reclassify water
water_outfile <- restoreutils::reclassify_rule24_temporal_water_consistency(
  files          = files_water[["path"]],
  water_class_id = 3,
  year           = water_year,
  version        = water_version,
  multicores     = multicores,
  memsize        = memsize,
  output_dir     = water_output_dir
)

# Update water file
files[files[["year"]] == water_year, "path"] <- water_outfile

#
# 4. Apply perene mask
#

# Define years to apply
perene_mask_years <- c(2009, 2011, 2013, 2019, 2021)
perene_version <- "temporal-mask-2"
perene_label <- "Perene"

# Apply perene rules
perene_outfiles <- lapply(perene_mask_years, function(year) {
  # Define output dir
  perene_output_dir <- output_dir / perene_version / year

  # Load after terraclass
  tc_after <- get(paste0("load_terraclass_", year + 1))
  tc_after <- tc_after(multicores = multicores, memsize = memsize)
  tc_after <- tc_after[["file_info"]][[1]][["path"]]

  # Load before terraclass
  tc_before <- get(paste0("load_terraclass_", year - 1))
  tc_before <- tc_before(multicores = multicores, memsize = memsize)
  tc_before <- tc_before[["file_info"]][[1]][["path"]]

  # Filter current year
  year_file <- files[files[["year"]] == year, "path"][["path"]]

  # Filter label value
  class_value <- files[files[["year"]] == year, "labels"][[1]][[1]]
  class_value <- as.numeric(names(class_value[class_value == perene_label]))

  # Apply rule perene trajectory rule
  restoreutils::reclassify_rule27_temporal_trajectory_perene_mask(
    files                = year_file,
    files_mask           = c(tc_before, tc_after),
    year                 = year,
    perene_class_id      = class_value,
    perene_mask_class_id = 12, # 12 means Perene in terraclass maps
    version              = perene_version,
    multicores           = multicores,
    memsize              = memsize,
    output_dir           = perene_output_dir
  )
})

# Update perene files
files[files[["year"]] %in% perene_mask_years, "path"] <- unlist(perene_outfiles)


#
# 5. Apply vs-pasture rule
#

# Define years to apply
vs_pasture_years <- seq.int(from = 2001, to = 2021, by = 1)
vs_version <- "temporal-mask-3"

vs_class_name <- "vegetacao_secundaria"
vs_pasture_names <- c("past_arbustiva", "past_herbacea")

# Apply perene rules
vs_pasture_outfiles <- lapply(vs_pasture_years, function(year) {
  # Define output dir
  vs_output_dir <- output_dir / vs_version / year

  # Filter years to apply
  vs_pasture_files <- files[files[["year"]] %in% c(year - 1, year, year + 1), "path"][["path"]]

  # Filter current year
  year_file <- files[files[["year"]] == year, "path"][["path"]]

  # Get VS class ID
  class_value_current <- files[files[["year"]] == year, "labels"][[1]][[1]]
  vs_class_id <- as.numeric(names(class_value_current[class_value_current %in% vs_class_name]))

  # Get pasture class ID
  class_value_before <- files[files[["year"]] == (year - 1), "labels"][[1]][[1]]
  class_value_after <- files[files[["year"]] == (year + 1), "labels"][[1]][[1]]

  pasture_class_id <- list(
    unique(c(
      as.numeric(names(class_value_before[class_value_before %in% vs_pasture_names])),
      as.numeric(names(class_value_after[class_value_after %in% vs_pasture_names]))
    ))
  )

  # Apply rule perene trajectory rule
  restoreutils::reclassify_rule29_temporal_trajectory_vs_pasture(
    files                = vs_pasture_files,
    year                 = year,
    vs_class_id          = vs_class_id,
    pasture_class_id     = pasture_class_id,
    version              = perene_version,
    multicores           = multicores,
    memsize              = memsize,
    output_dir           = vs_output_dir
  )
})

# Update perene files
files[files[["year"]] %in% vs_pasture_years, "path"] <- unlist(vs_pasture_outfiles)


#
# 6. Reclassify agriculture neighbor
#

# Definitions
agri_version <- "temporal-mask-4"
agri_output_dir <- output_dir / agri_version
agri_value <- 1L

# Arrange files
files <- dplyr::arrange(files, .data[["year"]])

# Apply agriculture temporal rule
file_brick <- restoreutils::reclassify_rule22_temporal_annual_agriculture(
  files                       = files[["path"]],
  annual_agriculture_class_id = agri_value, # agriculture value for the classified maps
  version                     = agri_version,
  multicores                  = multicores,
  memsize                     = memsize,
  output_dir                  = agri_output_dir
)

# Split raster brick in multiple files
agri_files <- restoreutils::reclassify_temporal_results_to_maps(
  years = files[["year"]],
  output_dir = agri_output_dir,
  file_brick = file_brick,
  version = agri_version
)
