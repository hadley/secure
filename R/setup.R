#' Set up a package with a secure enclave.
#'
#' This creates a \code{secure/} directory, adds it to \code{.Rbuildignore},
#' and adds secure to \code{Suggests}.
#'
#' @param pkg Path to package. Defaults to working directory.
#' @export
use_secure <- function(pkg = ".") {
  pkg <- devtools::as.package(pkg)

  secure_path <- file.path(pkg$path, "secure")
  dir.create(secure_path, showWarnings = FALSE)

  devtools::use_build_ignore("secure", pkg = pkg)
  devtools::use_package("secure", "Suggests", pkg = pkg)

  invisible(TRUE)
}

