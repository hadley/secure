#' Set up a package with a secure enclave.
#'
#' This creates a \code{secure/} directory, adds it to \code{.Rbuildignore},
#' and adds secure to \code{Suggests}. Use \code{\link{add_user}()} to add a
#' new user, then \code{\link{encrypt}()} to encrypt data.
#'
#' @param pkg Path to package. Defaults to working directory.
#' @export
use_secure <- function(pkg = ".") {
  if (!requireNamespace("devtools", quietly = TRUE)) {
    stop("Please install devtools", call. = FALSE)
  }

  pkg <- devtools::as.package(pkg)

  secure_path <- file.path(pkg$path, "vault")
  dir.create(secure_path, showWarnings = FALSE)

  devtools::use_build_ignore("vault", pkg = pkg)
  devtools::use_package("secure", "Suggests", pkg = pkg)

  invisible(TRUE)
}

