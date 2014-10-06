add_user <- function(name, public_key, pkg = ".") {
  pkg <- devtools::as.package(pkg)
  stopifnot(inherits(public_key, "public.key"))

  new_user <- list(name = name, public_key = public_key)

  users <- c(load_users(pkg), list(new_user))
  save_users(users)
  recrypt(pkg)
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
