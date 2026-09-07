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

///|
test "POSIX lexer handles single and double quoted arguments" {
  let tokens = @moonargv.parse_posix(
    "deploy 'release build' \"Moon Bit\" plain",
  ).unwrap()
  assert_eq(@moonargv.values(tokens), [
    "deploy", "release build", "Moon Bit", "plain",
  ])
  assert_true(tokens[1].was_quoted())
  assert_true(tokens[2].was_quoted())
}

///|
test "POSIX lexer concatenates quoted and unquoted segments" {
  let tokens = @moonargv.parse_posix("pre'joined value'post ''").unwrap()
  assert_eq(@moonargv.values(tokens), ["prejoined valuepost", ""])
}

///|
test "POSIX lexer reports unterminated single quote" {
  let result = @moonargv.parse_posix("echo 'broken")
  guard result is Err(error) else { fail("expected parse error") }
  assert_true(error.kind() is @moonargv.UnterminatedSingleQuote)
  assert_eq(error.offset(), 5)
}

///|
test "POSIX lexer reports unterminated double quote" {
  let result = @moonargv.parse_posix("echo \"broken")
  guard result is Err(error) else { fail("expected parse error") }
  assert_true(error.kind() is @moonargv.UnterminatedDoubleQuote)
  assert_eq(error.offset(), 5)
}

///|
test "POSIX lexer applies escapes outside quotes" {
  let tokens = @moonargv.parse_posix("copy path\\ with\\ spaces literal\\$").unwrap()
  assert_eq(@moonargv.values(tokens), ["copy", "path with spaces", "literal$"])
  assert_true(tokens[1].was_quoted())
}

///|
test "POSIX lexer applies shell escapes inside double quotes" {
  let tokens = @moonargv.parse_posix("echo \"a\\\"b\\\\c\\$d\\q\"").unwrap()
  assert_eq(@moonargv.values(tokens), ["echo", "a\"b\\c$d\\q"])
}

///|
test "POSIX lexer keeps backslashes literal inside single quotes" {
  let tokens = @moonargv.parse_posix("echo 'C:\\work\\file'").unwrap()
  assert_eq(@moonargv.values(tokens), ["echo", "C:\\work\\file"])
}

///|
test "POSIX lexer removes escaped newline" {
  let tokens = @moonargv.parse_posix("hello\\\nworld").unwrap()
  assert_eq(@moonargv.values(tokens), ["helloworld"])
}

///|
test "POSIX lexer reports dangling escape" {
  let result = @moonargv.parse_posix("echo trailing\\")
  guard result is Err(error) else { fail("expected parse error") }
  assert_true(error.kind() is @moonargv.DanglingEscape)
  assert_eq(error.offset(), 13)
}
