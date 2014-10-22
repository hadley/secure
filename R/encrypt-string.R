#' Encrypt and decrypt simple strings.
#'
#' This is useful if you want to email secrets to your collaborators. It's
#' only suitable for short-term communication because there's no way
#' to re-encrypt the strings if the master key changes (i.e. when you
#' add or remove users).
#'
#' @export
#' @examples
#' \dontrun{
#' enc <- encrypt_string("This string is encrypted")
#' enc
#' decrypt_string(enc)
#' }
encrypt_string <- function(x, vault = NULL) {
  vault <- find_vault(vault)

  enc <- PKI::PKI.encrypt(charToRaw(x), my_key(vault), "AES-256")
  base64enc::base64encode(enc)
}

#' @rdname encrypt_string
#' @export
decrypt_string <- function(x, vault = NULL) {
  vault <- find_vault(vault)

  enc <- base64enc::base64decode(x)
  rawToChar(PKI::PKI.decrypt(enc, my_key(vault), "AES-256"))
}

