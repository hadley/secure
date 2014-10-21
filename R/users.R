#' Add and remove users user.
#'
#' Adding or removing users will re-generate the master key and re-encrypt all
#' secured files.
#'
#' @param name Name of user. Currently only used to help you remember who
#'   owns the public key
#' @param public_key Users public key.
#' @inheritParams has_key
#' @export
#' @examples
#' \dontrun{
#' # Add a github user:
#' add_user("hadley", github_key("hadley"))
#' remove_user("hadley")
#'
#' # Add yourself:
#' add_user("hadley", local_key())
#' remove_user("hadley")
#'
#' # Add travis user
#' add_user("travis", travis_key("hadley/secure"))
#' remove_user("travis")
#' }
add_user <- function(name, public_key, vault = NULL) {
  vault <- find_vault(vault)
  stopifnot(inherits(public_key, "public.key"))

  new_user <- list(name = name, public_key = public_key)
  users <- c(load_users(vault), list(new_user))
  save_users(users, vault = vault)

  recrypt(vault)
}

#' @rdname add_user
#' @export
remove_user <- function(name, vault = ".") {
  vault <- find_vault(vault)
  users <- load_users(vault)

  matching <- vapply(users, function(x) identical(x$name, name), logical(1))
  if (!any(matching)) {
    stop("Could not find user called ", name, call. = FALSE)
  }

  save_users(users[!matching], vault = vault)
  recrypt(vault)
}

recrypt <- function(vault, key = new_key()) {
  message("Re-encrypting all files with new key")
  vault <- find_vault(vault)
  old_key <- my_key(vault = vault)

  # Encrypt new password for each user
  users <- load_users(vault)
  users <- lapply(users, recrypt_user, key = key)
  save_users(users, vault = vault)

  # Decrypt & reencrypt each file
  files <- dir(vault, "\\.rds\\.enc$", full.names = TRUE)
  lapply(files, recrypt_file, old_key = old_key, new_key = key)

  invisible(TRUE)
}

recrypt_user <- function(x, key) {
  x$key <- base64enc::base64encode(PKI::PKI.encrypt(key, x$public_key))
  if (identical(x$name, "travis")) {
    envvar <- charToRaw(paste0("SECURE_KEY=", base64enc::base64encode(key)))
    secure <- base64enc::base64encode(PKI::PKI.encrypt(envvar, x$public_key))

    message(
      "Please add/replace the following yaml in .travis.yaml:\n",
      "env: \n",
      "  - secure: ", secure, "\n"
    )
  }

  x
}

recrypt_file <- function(path, old_key, new_key) {
  enc <- readBin(path, "raw", file.info(path)$size)

  dec <- PKI::PKI.decrypt(enc, old_key, "AES-256")
  enc <- PKI::PKI.encrypt(dec, new_key, "AES-256")
  writeBin(enc, path)
}

load_users <- function(vault) {
  vault <- find_vault(vault)

  path <- file.path(vault, "users.json")
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

save_users <- function(users, vault) {
  vault <- find_vault(vault)
  users <- lapply(users, function(x) {
    x$name <- jsonlite::unbox(x$name)
    x$public_key <- PKI::PKI.save.key(x$public_key, "PEM")
    x
  })

  path <- file.path(vault, "users.json")
  writeLines(jsonlite::toJSON(users, pretty = TRUE), path)
  invisible(TRUE)
}

