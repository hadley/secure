context("decrypt")

test_that("can decrypt secrets", {
  skip_when_missing_key("secure")

  test <- decrypt("test", vault = "secure")
  expect_equal(test$a, 1)
  expect_equal(test$b, 2)
})
