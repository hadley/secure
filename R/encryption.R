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
  der <- PKI::PKI.save.key(key, "DER")
  same_key <- function(x) identical(PKI::PKI.save.key(x$public_key, "DER"), der)

  me <- Filter(same_key, load_users(pkg))
  if (length(me) != 1) {
    stop("Could not uniquely identify user")
  }

  private_key <- PKI::PKI.load.key(file = "~/.ssh/id_rsa")
  PKI::PKI.decrypt(base64enc::base64decode(me[[1]]$key), private_key)
}

hex2raw = function(h) {
  x <- strsplit(tolower(h), "")[[1L]]
  pos <- match(x, c(0L:9L, letters[1L:6L]))

  unname(pos)
}

new_key <- function(n = 87) {
  as.raw(sample(1:255, n, rep = TRUE))
}
