///|
test "POSIX lexer splits plain arguments" {
  let tokens = @moonargv.parse_posix("moon test --target native").unwrap()
  assert_eq(@moonargv.values(tokens), ["moon", "test", "--target", "native"])
}

///|
test "POSIX lexer accepts mixed whitespace" {
  let tokens = @moonargv.parse_posix("  alpha\tbeta\n gamma  ").unwrap()
  assert_eq(@moonargv.values(tokens), ["alpha", "beta", "gamma"])
  assert_eq(tokens[0].start(), 2)
  assert_eq(tokens[0].end(), 7)
}

///|
test "POSIX lexer returns no arguments for blank input" {
  assert_eq(@moonargv.parse_posix(" \t\r\n").unwrap(), [])
}
