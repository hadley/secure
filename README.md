# secure

[![Build Status](https://travis-ci.org/hadley/secure.png?branch=master)](https://travis-ci.org/hadley/secure)

The secure package provides a secure vault within a publicly available code repository. It allows you to store private information in a public repository so that only select people can read it. This is particularly useful for testing because you can now store private credentials in your public repo, without them being readable by the world.

Secure is built on top of asymmetric (public/private key) encryption. Secure generates a random master key and uses that to encrypt (with AES256) each file in `vault/`. The master key is not stored unencrypted anywhere; instead, an encrypted copy is stored for each user, using their own public key. Each user can than decrypt the encrypted master key using their private key, then use that to decrypt each file.

## Installation

Secure is currently only available on github. Install it with:

```R
# install.packages("devtools")
devtools::install_github("s-u/PKI") # needed for bug fixes not currently on CRAN
devtools::install_github("hadley/secure")
```

## First steps

To get started:

* Create a `vault` directory.

* Add yourself as as user with `secure::add_user("your name", secure::local_key())`. 
  This will add your name and public key to `vault/users.json`.
  (You can add other people from their `github_key()`s).

* Securely store data: 
  `secure::encrypt("google", key = "abcdasdf", secret = "asdfsad")`.
  This creates `secure/google.rds.enc`, an encrypted rds file.

* Retrieve encrypted data: `secure::decrypt("google")`. This decrypts
  the encrypted file using your private key.

## In a package

* Create `inst/vault` and add `secure` to the `Suggests` field in the 
  `DESCRIPTION` (or run `secure::use_secure()`).

* If you use travis, add the public key for your travis repo:
  `secure::add_user("travis", travis_key("user/repo"))`.

* When developing locally, you can use all functions as is. They look for
  a vault in the working directory.
  
* In tests, supply the package name to the `vault` argument. For example,
  one of the tests for the secure package looks like this:
  
    ```R
    test_that("can decrypt secrets", {
      # Skips the test if doesn't have the key to open the secure vault
      skip_when_missing_key("secure")
      
      # Decrypt a file stored in secure/inst/vault
      test <- decrypt("test", vault = "secure")
      expect_equal(test$a, 1)
      expect_equal(test$b, 2)
    })
    ```

## Caveats

* I'm not a security expert. As far as I know I've designed this package 
  according to security best practices, but I'm not sure.
  
* You still need to be careful not to accidentally expose secrets through
  log files, `.Rhistory`, etc.
