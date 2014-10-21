# secure

[![Build Status](https://travis-ci.org/hadley/secure.png?branch=master)](https://travis-ci.org/hadley/secure)

The secure pacakge provides a secure enclave within a publicly available code repository. It uses public key encryption to allow you to share a file with a select list of collaborators. This is particularly useful for testing web APIS: you can encrypt credentials so that you can both use them locally and on travis.

## Installation

Secure is currently only available on github. Install it with:

```R
# install.packages("devtools")
devtools::install_github("s-u/PKI") # needed for bug fixes
devtools::install_github("hadley/secure")
```

## Basic principles

To get started:

* Create a `vault` directory.

* Add yourself as as user with `secure::add_user("your name", local_key())`. 
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

* When developing locally, you can use all functions as is. They work using
  the current working directory.
  
* In tests, supply the package name in the vault argument. For example,
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

## How it works

Each file is encrypted (using AES256) with the same master key. The master key is not stored unencrypted anywhere, instead it's encrypted once for each user, using their public key. 

When you add a new user (or remove an old user), a new master key is generated and all files are re-encrypted.

## Caveats

* I'm not a security expert. As far as I know I've designed this package 
  according to security best practices, but I'm not sure.
  
* You still need to be careful not to accidentally expose secrets through
  log files, `.Rhistory`, etc.
