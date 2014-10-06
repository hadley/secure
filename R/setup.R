#' Set up a package with a secure hoard
#'
#' This creates a \code{secure/} directory and adds it to \code{.Rbuildignore}
#'
#' @param pkg Path to package. Defaults to working directory.
use_securrr <- function(pkg = ".") {
  pkg <- devtools::as.package(pkg)

  secure_path <- file.path(pkg$path, "secure")
  dir.create(secure_path, showWarnings = FALSE)

  devtools::use_build_ignore("secure", pkg = pkg)

  invisible(TRUE)
}

