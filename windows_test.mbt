///|
test "Windows lexer splits plain arguments" {
  let tokens = @moonargv.parse_windows("moon test --target native").unwrap()
  assert_eq(@moonargv.values(tokens), ["moon", "test", "--target", "native"])
}

///|
test "Windows lexer preserves ordinary path backslashes" {
  let tokens = @moonargv.parse_windows("copy C:\\work\\in.txt D:\\out").unwrap()
  assert_eq(@moonargv.values(tokens), ["copy", "C:\\work\\in.txt", "D:\\out"])
}

///|
test "Windows lexer accepts quoted spaces and empty arguments" {
  let tokens = @moonargv.parse_windows("tool \"C:\\Program Files\\Moon\" \"\"").unwrap()
  assert_eq(@moonargv.values(tokens), ["tool", "C:\\Program Files\\Moon", ""])
  assert_true(tokens[1].was_quoted())
  assert_true(tokens[2].was_quoted())
}

///|
test "Windows lexer concatenates quoted segments" {
  let tokens = @moonargv.parse_windows("pre\"joined value\"post").unwrap()
  assert_eq(@moonargv.values(tokens), ["prejoined valuepost"])
}

///|
test "Windows lexer accepts unmatched final quote like the CRT" {
  let tokens = @moonargv.parse_windows("tool \"rest of line").unwrap()
  assert_eq(@moonargv.values(tokens), ["tool", "rest of line"])
}
