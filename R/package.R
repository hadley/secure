as.package <- function(path = ".") {
  if (is.package(path)) return(path)

  check_dir(path)

  vault_path <- file.path(path, "secure")
  check_dir(vault_path)

  structure(list(path = path, vault = vault_path), class = "package")
}

is.package <- function(x) inherits(x, "package")


check_dir <- function(path) {
  if (!file.exists(path)) {
    stop(path, " does not exist", call. = FALSE)
  }
  if (!file.info(path)$isdir) {
    stop(path, " is not a directory", call. = FALSE)
  }
}
