# secure

The secure pacakge provides a secure enclave within a publicly available code repository. It uses public key encryption to allow you to share a file with a select list of collaborators. This is particularly useful for testing web APIS: you can encrypt credentials so that you can both use them locally and on travis.

## Installation

Secure is currently only available on github. Install it with:

```R
# install.packages("devtools")
devtools::install_github("s-u/PKI") # needed for bug fixes
devtools::install_github("hadley/secure")
```

## Basic principles

To get started, run `secure::use_secure()` in a package working directory. This will:

* Create a `secure/` directory.
* Add it to `.Rbuildignore`.
* Add secure to the `Suggests` field in `DESCRIPTION`.

Next, add yourself as as user with `secure::add_user("your name", local_key())`. This will add your name and public key to `secure/.users.json`.  (Add other people using their `github_key()`s, and add travis using `travis_key()`.)

Now you can start adding encrypted data:

```R
secure::encrypt("google", key = "abcdasdf", secret = "asdfsad")
secure::decrypt("google")
```

This creates `secure/google.rds.enc`, an encrypted rds file.

## How it works

Each file is encrypted (using AES256) with the same master key. The master key is not stored unencrypted anywhere, instead it's encrypted once for each user, using their public key. 

When you add a new user (or remove an old user), a new master key is generated and all files are rencrypted.

## Caveats

* I'm not a security expert. As far as I know I've designed this package 
  according to security best practices, but I'm not sure.
  
* You still need to be careful not to accidentally expose secrets through
  log files, `.Rhistory`, etc.
