///|
/// Microsoft-documented CRT examples used as an external behavioral oracle.
/// Source: learn.microsoft.com/cpp/c-language/parsing-c-command-line-arguments
test "matches Microsoft CRT documented argument table" {
  assert_eq(
    @moonargv.values(@moonargv.parse_windows("\"a b c\" d e").unwrap()),
    ["a b c", "d", "e"],
  )
  assert_eq(
    @moonargv.values(@moonargv.parse_windows("\"ab\\\"c\" \"\\\\\" d").unwrap()),
    ["ab\"c", "\\", "d"],
  )
  assert_eq(
    @moonargv.values(@moonargv.parse_windows("a\\\\\\b d\"e f\"g h").unwrap()),
    ["a\\\\\\b", "de fg", "h"],
  )
  assert_eq(
    @moonargv.values(@moonargv.parse_windows("a\\\\\\\"b c d").unwrap()),
    ["a\\\"b", "c", "d"],
  )
  assert_eq(
    @moonargv.values(@moonargv.parse_windows("a\\\\\\\\\"b c\" d e").unwrap()),
    ["a\\\\b c", "d", "e"],
  )
}
