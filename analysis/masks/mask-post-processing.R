library(sits)
library(restoreutils)

# ---- Configurations ----
base_data_dir <- fs::path("data/derived/")

labels <- restoreutils::labels_amazon_mcti()
labels_inverse <- setNames(names(labels), labels)

# Resources used to apply reclassification with sits
memsize <- 400
multicores <- 80

# Resources used to apply multi-temporal rules
memsize_temporal <- 200
multicores_temporal <- 30

years <- 2000:2022

# Eco-specific parameters
source_classes <- c(6, 10)
target_classes <- c(6, 10)

# ---- Step 1: Water fix 2018 (Rule 24) ----
cli::cli_alert_info("> Step 1: Water fix 2018")

step1_dir <- base_data_dir / "mosaics"

water_year <- 2018
water_version <- "mosaics-post-step1"
water_output_dir <- step1_dir / water_year
water_mask_years <- c(2017, 2018, 2019)

files_water_year <- fs::dir_ls(water_output_dir, glob = "*class_v1.tif")

files_water <- fs::dir_ls(step1_dir / water_mask_years, glob = "*class_v1.tif")
files_water <- tibble::tibble(path = files_water) |>
    dplyr::mutate(
        year   = stringr::str_extract(.data[["path"]], "\\d{4}") |>
            as.numeric(),
        labels = list(labels)
    )

valid_years_for_conversion <- which(files_water[["year"]] %in% c(2018, 2020, 2022))
target_class_map_post2015 <- tibble::tibble(
    source = as.character(labels),
    target = as.character(labels),
    indices = list(valid_years_for_conversion)
) |>
    dplyr::mutate(source = as.numeric(labels_inverse[as.character(.data[["source"]])]),
                  target = as.numeric(labels_inverse[as.character(.data[["target"]])]))

# Apply rule 24
water_outfile <- restoreutils::reclassify_rule24_temporal_water_consistency(
    files            = files_water[["path"]],
    water_class_id   = 3,
    excluded_values  = c(11, 12, 14),
    target_class_map = target_class_map_post2015,
    year             = water_year,
    version          = water_version,
    multicores       = multicores,
    memsize          = memsize,
    output_dir       = water_output_dir
)

# ---- Step 2: Cropland/Pasture + Deforestation fix (Rules 31 + 32) ----
cli::cli_alert_info("> Step 2: Cropland/Pasture + Deforestation fix")

step2_input_dir <- step1_dir
step2_output_dir <- base_data_dir / "mosaics-post-step2"

step2_files <- fs::dir_ls(step2_input_dir, glob = "*class_v1.tif", recurse = TRUE)

# 2a) Agriculture (Rule 31)
output_dir_agriculture_rule <- fs::dir_create(step2_output_dir / "agriculture-rule")
output_dir_agriculture_rule_blocks <- fs::dir_create(output_dir_agriculture_rule / "blocks")

cropland_pasture_file <- restoreutils::reclassify_rule31_cropand_pasture(
    files                       = step2_files,
    annual_agriculture_class_id = 1,
    target_class                = 10,
    version                     = "v1",
    multicores                  = multicores,
    memsize                     = memsize,
    output_dir                  = output_dir_agriculture_rule_blocks
)

cropland_pasture_files <- restoreutils::reclassify_temporal_results_to_maps(
    years      = years,
    output_dir = output_dir_agriculture_rule,
    file_brick = cropland_pasture_file,
    version    = "v1"
)

# 2b) Deforestation (Rule 32)
output_dir_deforestation_rule <- fs::dir_create(step2_output_dir / "deforestation-rule")
output_dir_deforestation_rule_blocks <- fs::dir_create(output_dir_deforestation_rule / "blocks")

deforestation_file <- restoreutils::reclassify_rule32_deforestation_consistency(
    files                       = cropland_pasture_files,
    deforestation_id            = 12,
    target_class                = 4,
    version                     = "v1",
    multicores                  = multicores,
    memsize                     = memsize,
    output_dir                  = output_dir_deforestation_rule_blocks
)

deforestation_files <- restoreutils::reclassify_temporal_results_to_maps(
    years      = years,
    output_dir = output_dir_deforestation_rule,
    file_brick = deforestation_file,
    version    = "v1"
)

# ---- Step 3: Forest consistency fix (Rule 33) ----
cli::cli_alert_info("> Step 3: Forest consistency fix")

step3_input_dir <- step2_output_dir / "deforestation-rule"
step3_output_dir <- base_data_dir / "mosaics-post-step3"

step3_output_dir_brick <- fs::dir_create(step3_output_dir, "_bricks")
step3_output_dir_files <- fs::dir_create(step3_output_dir, "_files")
step3_output_dir_organized <- fs::dir_create(step3_output_dir, "organized")

step3_files <- fs::dir_ls(step3_input_dir, glob = "*class_v1.tif", recurse = TRUE)

forest_brick <- restoreutils::reclassify_rule33_forest_consistency(
    files      = step3_files,
    forest_id  = 4,
    version    = "v1",
    multicores = multicores,
    memsize    = memsize,
    output_dir = step3_output_dir_brick
)

forest_files <- restoreutils::reclassify_temporal_results_to_maps(
    years      = years,
    output_dir = step3_output_dir_files,
    file_brick = forest_brick,
    version    = "v1"
)

# Organize output files
forest_files |>
    purrr::map(function(mosaic_file) {
        file_year <- sub("^.*?(\\d{4}).*$", "\\1", mosaic_file)

        mosaic_dir_year <- fs::dir_create(step3_output_dir_organized, file_year)
        mosaic_file_target <- mosaic_dir_year / fs::path_file(mosaic_file)

        if (fs::file_exists(mosaic_file_target)) {
            return(NULL);
        }

        fs::file_copy(mosaic_file, mosaic_file_target, overwrite = TRUE)
    })

# ---- Step 4: Cropland fix (Rules 34 + 35) ----
cli::cli_alert_info("> Step 4: Cropland fix")

step4_input_dir <- step3_output_dir_organized
step4_output_dir <- base_data_dir / "mosaics-post-step4"

step4_output_dir_input <- fs::dir_create(step4_output_dir, "_input")
step4_output_dir_cubes <- fs::dir_create(step4_output_dir, "_cubes")
step4_output_dir_bricks <- fs::dir_create(step4_output_dir, "_bricks")
step4_output_dir_organized <- fs::dir_create(step4_output_dir, "organized")

step4_years <- c(2008, 2010, 2012, 2014, 2016)
step4_years_intermediate <- c(2009, 2011, 2013, 2015)

# Copy files
cli::cli_alert_info("> Copy files")

files <- fs::dir_ls(step4_input_dir, glob = "*class_v1.tif", recurse = TRUE) |>
    purrr::map_chr(function(file) {
        target_file <- step4_output_dir_input / fs::path_file(file)

        if (fs::file_exists(target_file)) {
            return(target_file)
        }

        fs::file_copy(file, target_file)
        fs::path(target_file)
    })

files <- tibble::tibble(file = unname(files)) |>
         dplyr::mutate(
             year = stringr::str_extract(.data[["file"]], "\\d{4}") |> as.numeric()
         )

# Fix cropland (Rule 34)
cli::cli_alert_info("> Fix cropland")

log_ <- slider::slide(step4_years, function(year) {
    # Create directory
    output_dir_year <- fs::dir_create(step4_output_dir_cubes, year)

    # Load cube
    cube_year <- restoreutils::load_restore_mosaic(
        data_dir   = step4_input_dir / year,
        multicores = multicores,
        memsize    = memsize,
        labels     = labels
    )

    # Load Terraclass
    tc_year <- get(paste0("load_terraclass_", year))
    tc_year <- tc_year(
        multicores = multicores,
        memsize = memsize
    )

    # Reclassify
    result_year <- restoreutils::reclassify_rule34_cropland_consistency_tc(
        cube       = cube_year,
        mask       = tc_year,
        roi        = NULL,
        multicores = multicores,
        memsize    = memsize,
        output_dir = output_dir_year,
        version    = "v1",
        rarg_year  = year
    )

    current_year_file <- files[files["year"] == year, "file"][["file"]]
    fs::file_move(result_year[["file_info"]][[1]][["path"]], current_year_file)
})

# Fix cropland transitions (Rule 35)
cli::cli_alert_info("> Fix cropland transitions")

log_ <- purrr::map(step4_years_intermediate, function(year_intermediate) {
    # Apply rule 35 (Cropland transitions)
    # years_intermediate = c(2015, 2017, 2019, 2021)
    # 2014 | 2015 | 2016
    # 2016 | 2017 | 2018
    # 2018 | 2019 | 2020
    # 2020 | 2021 | 2022

    files_row <- c(year_intermediate - 1, year_intermediate, year_intermediate + 1)
    files_row <- files[files[["year"]] %in% files_row, "file"][["file"]]

    cropland_current_year <- reclassify_rule35_cropland_transitions(
        files           = files_row,
        cropland_id     = 1,
        pasture_id      = 10,
        source_classes  = source_classes,
        target_classes  = target_classes,
        version         = "v1",
        multicores      = multicores_temporal,
        memsize         = memsize_temporal,
        output_dir      = step4_output_dir_bricks
    )

    current_year_file <- files[files["year"] == year_intermediate, "file"][["file"]]
    fs::file_move(cropland_current_year, current_year_file)
})

# Organize output files
cli::cli_alert_info("> Organize output files")

log_ <- files[["file"]] |>
    purrr::map(function(mosaic_file) {
        file_year <- sub("^.*?(\\d{4}).*$", "\\1", mosaic_file)

        mosaic_dir_year <- fs::dir_create(step4_output_dir_organized, file_year)
        mosaic_file_target <- mosaic_dir_year / fs::path_file(mosaic_file)

        if (fs::file_exists(mosaic_file_target)) {
            return(NULL);
        }

        fs::file_move(mosaic_file, mosaic_file_target)
    })
