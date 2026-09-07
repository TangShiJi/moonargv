///|
test "POSIX quoting keeps simple arguments readable" {
  assert_eq(@moonargv.quote_posix("src/main.mbt"), "src/main.mbt")
  assert_eq(@moonargv.quote_posix("--target=wasm-gc"), "--target=wasm-gc")
}

///|
test "POSIX quoting represents empty and spaced arguments" {
  assert_eq(@moonargv.quote_posix(""), "''")
  assert_eq(@moonargv.quote_posix("hello world"), "'hello world'")
}

///|
test "POSIX quoting escapes embedded apostrophes" {
  let quoted = @moonargv.quote_posix("don't")
  assert_eq(@moonargv.values(@moonargv.parse_posix(quoted).unwrap()), ["don't"])
}

///|
test "POSIX join round trips Unicode and control-like text" {
  let arguments = ["moon", "", "中文 文件", "$HOME", "a;b", "don't"]
  let rendered = @moonargv.join_posix(arguments)
  assert_eq(
    @moonargv.values(@moonargv.parse_posix(rendered).unwrap()),
    arguments,
  )
}

///|
test "POSIX join handles an empty argv" {
  assert_eq(@moonargv.join_posix([]), "")
}
