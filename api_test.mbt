///|
test "unified API selects POSIX behavior" {
  let tokens = @moonargv.parse("echo path\\ with\\ spaces", @moonargv.Posix).unwrap()
  assert_eq(@moonargv.values(tokens), ["echo", "path with spaces"])
}

///|
test "unified API selects Windows behavior" {
  let tokens = @moonargv.parse("copy C:\\work\\file.txt", @moonargv.Windows).unwrap()
  assert_eq(@moonargv.values(tokens), ["copy", "C:\\work\\file.txt"])
}

///|
test "unified join round trips both dialects" {
  let arguments = ["program", "", "two words", "a\"b", "中文"]
  for dialect in [@moonargv.Posix, @moonargv.Windows] {
    let command = @moonargv.join(arguments, dialect)
    assert_eq(
      @moonargv.values(@moonargv.parse(command, dialect).unwrap()),
      arguments,
    )
  }
}

///|
test "unified quote exposes deliberate dialect differences" {
  assert_eq(
    @moonargv.quote_argument("two words", @moonargv.Posix),
    "'two words'",
  )
  assert_eq(
    @moonargv.quote_argument("two words", @moonargv.Windows),
    "\"two words\"",
  )
}
