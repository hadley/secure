#' Retrieve public keys.
#'
#' @name keys
#' @examples
#' travis_key("hadley/dplyr")
#' github_key("hadley")
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
