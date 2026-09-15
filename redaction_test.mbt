///|
test "redaction handles separate and assigned secrets" {
  let argv = [
    "deploy", "--token", "abc123", "--header=private", "--region", "cn",
  ]
  let result = @moonargv.redact_arguments(argv, [
    @moonargv.secret_after_flag("--token"),
    @moonargv.secret_assignment("--header"),
  ]).unwrap()
  assert_eq(result.arguments(), [
    "deploy", "--token", "<redacted>", "--header=<redacted>", "--region", "cn",
  ])
  assert_eq(result.redacted_indices(), [2, 3])
  assert_eq(argv[2], "abc123")
}

///|
test "literal and position redaction cover repeated values" {
  let result = @moonargv.redact_arguments(
    ["tool", "secret", "visible", "secret"],
    [@moonargv.secret_literal("secret"), @moonargv.secret_argument(2)],
    replacement="***",
  ).unwrap()
  assert_eq(result.arguments(), ["tool", "***", "***", "***"])
  assert_eq(result.redacted_indices(), [1, 3, 2])
}

///|
test "redacted rendering remains valid for the selected dialect" {
  let rendered = @moonargv.render_redacted(
    ["deploy tool", "--token", "a b"],
    @moonargv.Windows,
    [@moonargv.secret_after_flag("--token")],
  ).unwrap()
  assert_eq(@moonargv.values(@moonargv.parse_windows(rendered).unwrap()), [
    "deploy tool", "--token", "<redacted>",
  ])
}

///|
test "invalid secret selectors fail before logging" {
  let result = @moonargv.redact_arguments(["tool"], [
    @moonargv.secret_argument(4),
  ])
  guard result is Err(error) else { fail("expected selector error") }
  assert_eq(error.kind(), @moonargv.InvalidSecretSelector)
}
