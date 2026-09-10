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

///|
test "command line separates executable from argparse input" {
  let parsed = @moonargv.parse_command_line(
    "deploy --target 'staging cluster' --verbose",
    @moonargv.Posix,
  ).unwrap()
  assert_eq(parsed.program(), "deploy")
  assert_eq(parsed.arguments(), ["--target", "staging cluster", "--verbose"])
  assert_eq(@moonargv.values(parsed.tokens()), [
    "deploy", "--target", "staging cluster", "--verbose",
  ])
}

///|
test "command line adapter supports quoted Windows executable paths" {
  let parsed = @moonargv.parse_command_line(
    "\"C:\\Program Files\\tool.exe\" --output \"build folder\"",
    @moonargv.Windows,
  ).unwrap()
  assert_eq(parsed.program(), "C:\\Program Files\\tool.exe")
  assert_eq(parsed.arguments(), ["--output", "build folder"])
}

///|
test "command line adapter rejects missing executable" {
  let result = @moonargv.parse_command_line("  \t", @moonargv.Posix)
  guard result is Err(error) else { fail("expected EmptyProgram") }
  assert_eq(error.kind(), @moonargv.EmptyProgram)
  assert_eq(error.offset(), 0)
}
