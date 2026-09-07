///|
test "command builder preserves logical argument boundaries" {
  let command = @moonargv.command_line("moon")
    .unwrap()
    .argument("test")
    .argument("--target")
    .argument("wasm-gc")
  assert_eq(command.program(), "moon")
  assert_eq(command.arguments(), ["test", "--target", "wasm-gc"])
  assert_eq(command.argv(), ["moon", "test", "--target", "wasm-gc"])
}

///|
test "command builder extends with empty and spaced values" {
  let command = @moonargv.command_line("tool")
    .unwrap()
    .extend(["", "two words", "中文"])
  assert_eq(command.argv(), ["tool", "", "two words", "中文"])
}

///|
test "command rendering round trips in POSIX mode" {
  let command = @moonargv.command_line("deploy")
    .unwrap()
    .argument("--message")
    .argument("it's ready")
  let rendered = command.render(@moonargv.Posix)
  assert_eq(
    @moonargv.values(@moonargv.parse(rendered, @moonargv.Posix).unwrap()),
    command.argv(),
  )
}

///|
test "command rendering round trips in Windows mode" {
  let command = @moonargv.command_line("C:\\Program Files\\tool.exe")
    .unwrap()
    .argument("C:\\output path\\")
    .argument("say \"ready\"")
  let rendered = command.render(@moonargv.Windows)
  assert_eq(
    @moonargv.values(@moonargv.parse(rendered, @moonargv.Windows).unwrap()),
    command.argv(),
  )
}

///|
test "command builder rejects empty program" {
  let result = @moonargv.command_line("")
  guard result is Err(error) else { fail("expected empty-program error") }
  assert_true(error.kind() is @moonargv.EmptyProgram)
  assert_eq(error.offset(), 0)
}

///|
test "arguments accessor does not expose builder storage" {
  let command = @moonargv.command_line("tool").unwrap().argument("first")
  let copy = command.arguments()
  copy.push("injected")
  assert_eq(command.arguments(), ["first"])
}
