#' Encrypt and decrypt data.
#'
#' @param .name,name Name of storage locker.
#' @param ... Name-value pairs of objects to store.
#' @param .vault,vault Name of secure vault. If \code{NULL} looks for
#'   \code{vault} or \code{inst/vault} in the current directory. If a string,
#'   looks for a secure vault in the package with that name
#' @export
#' @examples
#' \dontrun{
#' encrypt("test", x = 1, y = 2)
#' # Encrypting to same file adds fields
#' encrypt("test", z = 3)
#'
#' decrypt("test")
#' }
encrypt <- function(.name, ..., .vault = NULL) {
  vault <- find_vault(.vault)
  key <- my_key()

  values <- list(...)
  path <- locker_path(.name, vault)

  if (file.exists(path)) {
    message("Merging with existing data")
    old_values <- decrypt(basename(path), vault = vault)
    values <- modifyList(old_values, values)
  }

  ser <- serialize(values, connection = NULL)
  enc <- PKI::PKI.encrypt(ser, key, "AES-256")
  writeBin(enc, path)
}

#' @rdname encrypt
#' @export
decrypt <- function(name, vault = NULL) {
  vault <- find_vault(vault)
  key <- my_key(vault = vault)

  path <- locker_path(name, vault)
  if (!file.exists(path)) {
    stop(path, " does not exist", call. = FALSE)
  }

  enc <- readBin(path, "raw", file.info(path)$size * 1.1)
  dec <- PKI::PKI.decrypt(enc, key, "AES-256")

  unserialize(dec)
}

locker_path <- function(name, vault) {
  stopifnot(is.character(name), length(name) == 1)
  vault <- find_vault(vault)

  if (!grepl("\\.rds.enc", name)) {
    name <- paste0(name, ".rds.enc")
  }
  file.path(vault, name)
}

my_key <- function(key = local_key(), vault = NULL) {
  vault <- find_vault(vault)
  # Travis needs a slightly different strategy because we can't access the
  # private key - instead we let travis encrypt the key in an env var
  if (is_travis()) {
    return(base64enc::base64decode(Sys.getenv("SECURE_KEY")))
  }

  der <- PKI::PKI.save.key(key, "DER")
  same_key <- function(x) identical(PKI::PKI.save.key(x$public_key, "DER"), der)

  me <- Filter(same_key, load_users(vault))
  if (length(me) == 0) {
    stop("No user matches public key ", format(key), call. = FALSE)
  } else if (length(me) > 1) {
    stop("Multiple users match public key: ", paste0(names(me), collapse = ", "),
      call. = FALSE)
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
#' @param vault Name of secure vault. If \code{NULL} looks for
#'   \code{vault} or \code{inst/vault} in the current directory. If a string,
#'   looks for a secure vault in the package with that name
#' @return A boolean flag.
#' @export
has_key <- function(vault = NULL) {
  tryCatch({
    my_key(vault = vault)
    TRUE
  }, error = function(e) FALSE)
}


#' Skip tests when you can't unlock
#'
#' This is useful to place at the top of tests that rely on access to secured
#' assets. Skipped tests do not generate an error in R CMD check etc, but
#' will print a visible notification.
#'
#' @inheritParams has_key
#' @export
skip_when_missing_key <- function(vault = NULL) {

  if (!requireNamespace("testthat", quietly = TRUE)) {
    stop("testthat not installed", call. = FALSE)
  }

  if (has_key(vault)) return()
  testthat::skip("Credentials to unlock secure files not available.")
}
