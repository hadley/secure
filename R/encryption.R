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

new_key <- function() {
  charToRaw(paste(sample(c(letters, 1:10), 50, replace = TRUE), collapse = ""))
}
