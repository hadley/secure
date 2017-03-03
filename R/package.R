find_vault <- function(x = NULL) {
  if (is.filepath(x)) {
    return(x)
  }
  
  if (is.null(x)) {
    # Assume you want the current directory
    if (file.exists("vault")) {
      path <- "vault"
    } else if (file.exists("inst/vault")) {
      path <- "inst/vault"
    } else {
      stop("Can't find vault/ or inst/vault in working directory",
           call. = FALSE)
    }
    
  } else if (is.character(x)) {
    # Name of a package
    if (file.exists("vault")) {
      path <- "vault"
    } else {
      path <- system.file("vault", package = x)
    }
    if (identical(path, "")) {
      stop(x, " does not contain secure vault (inst/vault).", call. = FALSE)
    }
  } else {
    stop("Unknown input", call. = FALSE)
  }
  
  check_dir(path)
  structure(path, class = c("filepath", "character"))
}

is.filepath <- function(x) inherits(x, "filepath")
print.filepath <- function(x, ...) {
  class(x) <- "character"
  NextMethod(print, x, ...)
}


check_dir <- function(path) {
  if (!file.exists(path)) {
    stop(path, " does not exist", call. = FALSE)
  }
  if (!file.info(path)$isdir) {
    stop(path, " is not a directory", call. = FALSE)
  }
}
