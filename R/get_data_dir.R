#' Get the Directory path for Cubes
#'
#' This function retrieves the directory path where cube is stored.
#'
#' It first checks for an environment variable (`RESTORE_PLUS_REG2_DIR`)
#' and falls back to a default directory (`data/derived/cubes`) if the
#' environment variable is not set. The function uses `fs::path()` to
#' ensure proper path construction across different operating systems.
#'
#' @return A character string representing the directory path, constructed
#' using `fs::path()`.
#' @export
get_cubes_dir <- function() {
  default_dir <- "data/derived/cube"

  fs::path(Sys.getenv("RESTORE_PLUS_REG2_DIR", default_dir))
}
