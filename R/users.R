#' Add a new user.
#'
#' Adding a new user will re-generate the master key and re-encrypt all
#' secured files.
#'
#' @param name Name of user. Currently only used to help you remember who
#'   owns the public key
#' @param public_key Users public key.
#' @param pkg Path to package. Defaults to working directory
#' @export
add_user <- function(name, public_key, pkg = ".") {
  pkg <- devtools::as.package(pkg)
  stopifnot(inherits(public_key, "public.key"))

  new_user <- list(name = name, public_key = public_key)
  users <- c(load_users(pkg), list(new_user))
  save_users(users)

  recrypt_all(pkg)
}

recrypt_all <- function(pkg = ".", key = new_key()) {
  message("Re-encrypting all files with new key")
  pkg <- devtools::as.package(pkg)

  # Encrypt new password for each user
  users <- load_users(pkg)
  users <- lapply(users, function(x) {
    x$key <- base64enc::base64encode(PKI::PKI.encrypt(key, x$public_key))
    x
  })
  save_users(users)

  # Decrypt & reencrypt each file
  files <- dir(file.path(pkg$path, "secure"), "\\.rds\\.enc$",
    full.names = TRUE)
  lapply(files, recrypt, old_key = my_key(), new_key = key)

  invisible(TRUE)
}

recrypt <- function(path, old_key, new_key) {
  enc <- readBin(path, "raw", file.info(path)$size)
  dec <- PKI::PKI.decrypt(enc, old_key, "AES-256")
  enc <- PKI::PKI.encrypt(dec, new_key, "AES-256")
  writeBin(enc, path)
}

load_users <- function(pkg = ".") {
  pkg <- devtools::as.package(pkg)

  path <- file.path(pkg$path, "secure", ".users.json")
  if (!file.exists(path)) {
    users <- list()
  } else {
    users <- jsonlite::fromJSON(path, simplifyDataFrame = FALSE)
  }

  lapply(users, function(x) {
    x$public_key <- PKI::PKI.load.key(x$public_key)
    x
  })
}

save_users <- function(users, pkg = ".") {
  pkg <- devtools::as.package(pkg)
  users <- lapply(users, function(x) {
    x$name <- jsonlite::unbox(x$name)
    x$public_key <- PKI::PKI.save.key(x$public_key, "PEM")
    x
  })

  path <- file.path(pkg$path, "secure", ".users.json")
  writeLines(jsonlite::toJSON(users, pretty = TRUE), path)
  invisible(TRUE)
}

