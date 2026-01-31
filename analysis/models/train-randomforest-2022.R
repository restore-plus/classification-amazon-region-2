set.seed(777)

library(sits)
library(restoreutils)

#
# General definitions
#

# Samples
samples_file <- "data/derived/timeseries/rf-samples_amazon_landsat_2022.rds"

# Output dir
base_output_dir <- "data/derived/"

# Model version
model_version <- "rf-samples_amazon_landsat_2022"


#
# 1. Create output directories
#
model_dir <- restoreutils::create_data_dir(base_output_dir, "models")


#
# 2. Load samples
#
samples_ts <- readRDS(samples_file)


#
# 3. Train model
#
model <- sits_train(
  samples = samples_ts,
  ml_method = sits_rfor()
)


#
# 4. Save model
#
saveRDS(model, model_dir / paste0(model_version, ".rds"))
