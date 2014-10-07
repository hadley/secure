encrypt <- function(.name, ..., .pkg = ".") {
  pkg <- devtools::as.package(.pkg)
  key <- my_key()

  values <- list(...)
  path <- file.path(pkg$path, "secure", paste0(.name, ".enc-rds"))

#   if (file.exists(path)) {
#     message("Merging with existing data")
#     old_values <- decrypt(basename(path), pkg = pkg)
#     values <- modifyList(old_values, values)
#   }

  ser <- serialize(values, connection = NULL)

  enc <- PKI::PKI.encrypt(ser, key, "AES-256")
#   dec <- PKI::PKI.decrypt(enc, key, "AES-256")
#   all.equal(ser, dec)
#   unserialize(dec)

  writeBin(enc, path)
}

decrypt <- function(name, pkg = ".") {
  pkg <- devtools::as.package(pkg)
  key <- my_key()

  if (!grepl("\\.enc-rds", name))
  path <- file.path(pkg$path, "secure", paste0(name, ".enc-rds"))
  if (!file.exists(path)) {
    stop(path, " does not exist", call. = FALSE)
  }

  enc <- readBin(path, "raw", file.info(path)$size * 1.1)
  dec <- PKI::PKI.decrypt(enc, key, "AES-256")

  unserialize(dec)
}

recrypt <- function(pkg = ".", key = new_key()) {
  message("Re-encrypting all files with new key")
  pkg <- devtools::as.package(pkg)

  users <- load_users(pkg)
  users <- lapply(users, function(x) {
    x$key <- PKI::raw2hex(PKI::PKI.encrypt(key, x$public_key), sep = "")
    x
  })
  save_users(users)
}

my_key <- function(key = local_key(), pkg = ".") {
  der <- PKI::PKI.save.key(key, "DER")
  same_key <- function(x) identical(PKI::PKI.save.key(x$public_key, "DER"), der)

  me <- Filter(same_key, load_users(pkg))
  if (length(me) != 1) {
    stop("Could not uniquely identify user")
  }

  me[[1]]$key
}

new_key <- function(n = 50) {
  as.raw(sample(255, n, rep = TRUE))
}
