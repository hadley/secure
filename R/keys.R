#' Retrieve public keys.
#'
#' @name keys
#' @examples
#' travis_key("hadley/dplyr")
#' github_key("hadley")
#' local_key()
NULL

#' @rdname keys
#' @param repo Travis repository name (x/y)
#' @export
travis_key <- function(repo) {
  url <- paste0("https://api.travis-ci.org/repos/", repo, "/key")
  r <- httr::GET(url)
  httr::stop_for_status(r)

  httr::content(r)$key[[1]]
}

#' @rdname keys
#' @param username Github username
#' @param i Key to use, if more than one
#' @export
github_key <- function(username, i = 1) {
  url <- paste0("https://api.github.com/users/", username, "/keys")
  r <- httr::GET(url)
  httr::stop_for_status(r)

  httr::content(r)[[i]]$key
}

#' @rdname keys
#' @param name Name of key. If missing, uses first file in directory,
#'   otherwise uses first file that matches \code{name}.
#' @export
local_key <- function(name) {
  public_keys <- dir("~/.ssh", pattern = "\\.pub$", full.names = TRUE)

  if (missing(name)) {
    key <- public_keys[[1]]
  } else {
    matches <- grepl(name, public_keys, fixed = TRUE)
    if (!any(matches)) stop("No key matches ", name, call. = FALSE)

    key <- public_keys[matches][[1]]
  }

  readLines(key)
}
