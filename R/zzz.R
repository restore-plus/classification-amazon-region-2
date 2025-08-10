# On load
.onAttach <- function(lib, pkg) {
  packageStartupMessage("Restore+ Package - Classification Amazon Region 2.")
  packageStartupMessage(paste0("Using restoreutils version: ", restoreutils::version()))
}
