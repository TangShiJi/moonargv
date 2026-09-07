///|
test "limited parser accepts input inside bounds" {
  let limits = @moonargv.parse_limits(3, 5)
  let tokens = @moonargv.parse_limited("one two 三", @moonargv.Posix, limits).unwrap()
  assert_eq(@moonargv.values(tokens), ["one", "two", "三"])
  assert_eq(limits.max_arguments(), 3)
  assert_eq(limits.max_argument_chars(), 5)
}

///|
test "limited parser reports first excess argument" {
  let result = @moonargv.parse_limited(
    "one two three",
    @moonargv.Posix,
    @moonargv.parse_limits(2, 20),
  )
  guard result is Err(error) else { fail("expected parse error") }
  assert_true(error.kind() is @moonargv.TooManyArguments)
  assert_eq(error.offset(), 8)
}

///|
test "limited parser counts Unicode characters rather than UTF-16 units" {
  let accepted = @moonargv.parse_limited(
    "\"月球\"",
    @moonargv.Windows,
    @moonargv.parse_limits(2, 2),
  )
  assert_true(accepted is Ok(_))
  let rejected = @moonargv.parse_limited(
    "\"月球站\"",
    @moonargv.Windows,
    @moonargv.parse_limits(2, 2),
  )
  guard rejected is Err(error) else { fail("expected parse error") }
  assert_true(error.kind() is @moonargv.ArgumentTooLong)
  assert_eq(error.offset(), 0)
}

///|
test "limit constructor clamps unusable values" {
  let limits = @moonargv.parse_limits(0, -8)
  assert_eq(limits.max_arguments(), 1)
  assert_eq(limits.max_argument_chars(), 1)
}
