///|
test "build tool can render the same logical command for both hosts" {
  let command = @moonargv.command_line("moon")
    .unwrap()
    .append_all([
      "run", "cmd/main", "--output", "build artifacts/应用", "--define", "MESSAGE=say \"hello\"",
    ])
  for dialect in [@moonargv.Posix, @moonargv.Windows] {
    let rendered = command.render(dialect)
    let recovered = @moonargv.values(
      @moonargv.parse(rendered, dialect).unwrap(),
    )
    assert_eq(recovered, command.argv())
  }
}

///|
test "bounded parser protects response-style input" {
  let source = "compiler input.mbt --output 'build folder/app.wasm'"
  let tokens = @moonargv.parse_limited(
    source,
    @moonargv.Posix,
    @moonargv.parse_limits(8, 64),
  ).unwrap()
  assert_eq(@moonargv.values(tokens), [
    "compiler", "input.mbt", "--output", "build folder/app.wasm",
  ])
}
