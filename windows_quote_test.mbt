///|
test "Windows quoting keeps simple paths unquoted" {
  assert_eq(@moonargv.quote_windows("C:\\work\\moon.exe"), "C:\\work\\moon.exe")
}

///|
test "Windows quoting represents empty and spaced arguments" {
  assert_eq(@moonargv.quote_windows(""), "\"\"")
  assert_eq(
    @moonargv.quote_windows("C:\\Program Files\\Moon"),
    "\"C:\\Program Files\\Moon\"",
  )
}

///|
test "Windows quoting preserves embedded quotes" {
  let argument = "say \"hello\""
  let rendered = @moonargv.quote_windows(argument)
  assert_eq(@moonargv.values(@moonargv.parse_windows(rendered).unwrap()), [
    argument,
  ])
}

///|
test "Windows quoting doubles trailing backslashes before closing quote" {
  let argument = "C:\\Program Files\\Moon\\"
  let rendered = @moonargv.quote_windows(argument)
  assert_eq(@moonargv.values(@moonargv.parse_windows(rendered).unwrap()), [
    argument,
  ])
}

///|
test "Windows join round trips mixed argv" {
  let arguments = [
    "tool.exe", "", "中文 文件", "C:\\tmp\\", "a\\\\\"b", "--flag=value",
  ]
  let rendered = @moonargv.join_windows(arguments)
  assert_eq(
    @moonargv.values(@moonargv.parse_windows(rendered).unwrap()),
    arguments,
  )
}

///|
test "Windows join handles an empty argv" {
  assert_eq(@moonargv.join_windows([]), "")
}
