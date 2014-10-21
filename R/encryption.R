#' Encrypt and decrypt data.
#'
#' @param .name,name Name of storage locker.
#' @param ... Name-value pairs of objects to store.
#' @param .pkg,pkg Path to package. Defaults to current directory.
#' @export
#' @examples
#' \dontrun{
#' encrypt("test", x = 1, y = 2)
#' # Encrypting to same file adds fields
#' encrypt("test", z = 3)
#'
#' decrypt("test")
#' }
encrypt <- function(.name, ..., .pkg = ".") {
  pkg <- devtools::as.package(.pkg)
  key <- my_key()

  values <- list(...)
  path <- locker_path(.name, pkg)

  if (file.exists(path)) {
    message("Merging with existing data")
    old_values <- decrypt(basename(path), pkg = pkg)
    values <- modifyList(old_values, values)
  }

  ser <- serialize(values, connection = NULL)
  enc <- PKI::PKI.encrypt(ser, key, "AES-256")
  writeBin(enc, path)
}

#' @rdname encrypt
#' @export
decrypt <- function(name, pkg = ".") {
  pkg <- devtools::as.package(pkg)
  key <- my_key()

  path <- locker_path(name, pkg)
  if (!file.exists(path)) {
    stop(path, " does not exist", call. = FALSE)
  }

  enc <- readBin(path, "raw", file.info(path)$size * 1.1)
  dec <- PKI::PKI.decrypt(enc, key, "AES-256")

  unserialize(dec)
}

locker_path <- function(name, pkg = ".") {
  stopifnot(is.character(name), length(name) == 1)
  pkg <- devtools::as.package(pkg)

  if (!grepl("\\.rds.enc", name)) {
    name <- paste0(name, ".rds.enc")
  }

  file.path(pkg$path, "secure", name)
}

my_key <- function(key = local_key(), pkg = ".") {
  # Travis needs a slightly different strategy because we can't access the
  # private key - instead we let travis encrypt the key in an env var
  if (is_travis()) {
    return(Sys.getenv("SECURE_KEY"))
  }

  der <- PKI::PKI.save.key(key, "DER")
  same_key <- function(x) identical(PKI::PKI.save.key(x$public_key, "DER"), der)

  me <- Filter(same_key, load_users(pkg))
  if (length(me) != 1) {
    stop("Could not uniquely identify user")
  }

  private_key <- PKI::PKI.load.key(file = "~/.ssh/id_rsa")
  PKI::PKI.decrypt(base64enc::base64decode(me[[1]]$key), private_key)
}

is_travis <- function() {
  identical(Sys.getenv("TRAVIS"), "true")
}

#' Can you unlock the secure storage?
#'
#' This ensures that we can find your private key, and you can decrypt
#' the encrypted master key.
#'
#' @return A boolean flag.
#' @export
has_key <- function() {
  tryCatch({
    my_key
    TRUE
  }, error = function(e) FALSE)
}


#' Skip tests when you can't unlock
#'
#' This is useful to place at the top of tests that rely on access to secured
#' assets. Skipped tests do not generate an error in R CMD check etc, but
#' will print a visible notification.
#'
#' @export
skip_when_missing_key <- function() {

  if (requireNamespace("testthat", quietly = TRUE)) {
    stop("testthat not installed", call. = FALSE)
  }

  if (has_key()) return()
  testthat::skip("Credentials to unlock secure files not available.")
}
