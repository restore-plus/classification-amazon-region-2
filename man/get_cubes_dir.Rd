% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/get_data_dir.R
\name{get_cubes_dir}
\alias{get_cubes_dir}
\title{Get the Directory path for Cubes}
\usage{
get_cubes_dir()
}
\value{
A character string representing the directory path, constructed
using \code{fs::path()}.
}
\description{
This function retrieves the directory path where cube is stored.
}
\details{
It first checks for an environment variable (\code{RESTORE_PLUS_REG1_DIR})
and falls back to a default directory (\code{data/derived/cubes}) if the
environment variable is not set. The function uses \code{fs::path()} to
ensure proper path construction across different operating systems.
}
