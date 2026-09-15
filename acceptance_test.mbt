/// Stable P0 acceptance contracts. Test names match ACCEPTANCE_CRITERIA.md.

///|
test "P0-POSIX-01 quotes escapes and empty arguments" {
  let parsed = @moonargv.parse("tool '' \"a b\" c\\ d", @moonargv.Posix).unwrap()
  assert_eq(@moonargv.values(parsed), ["tool", "", "a b", "c d"])
}

///|
test "P0-POSIX-02 malformed input returns a source offset" {
  let parsed = @moonargv.parse("tool 'open", @moonargv.Posix)
  guard parsed is Err(error) else { fail("expected quote error") }
  assert_eq(error.kind(), @moonargv.UnterminatedSingleQuote)
  assert_eq(error.offset(), 5)
}

///|
test "P0-WIN-01 Microsoft CRT backslash quote behavior" {
  let parsed = @moonargv.parse("a\\\\\\\"b c d", @moonargv.Windows).unwrap()
  assert_eq(@moonargv.values(parsed), ["a\\\"b", "c", "d"])
}

///|
test "P0-WIN-02 quoted path with trailing slash round trips" {
  let argv = ["tool.exe", "C:\\Program Files\\Moon\\", "", "say \"ready\""]
  let rendered = @moonargv.join(argv, @moonargv.Windows)
  assert_eq(
    @moonargv.values(@moonargv.parse(rendered, @moonargv.Windows).unwrap()),
    argv,
  )
}

///|
test "P0-RSP-01 nested response files preserve ordering" {
  let files = {
    "compile.rsp": "@sources.rsp --output 'build app.wasm'",
    "sources.rsp": "a.mbt 'src/b file.mbt'",
  }
  let expanded = @moonargv.expand_response_files(
    ["@compile.rsp"],
    files,
    @moonargv.Posix,
    @moonargv.response_limits(4, 16, 128),
  ).unwrap()
  assert_eq(expanded, ["a.mbt", "src/b file.mbt", "--output", "build app.wasm"])
}

///|
test "P0-RSP-02 response cycles fail without partial success" {
  let expanded = @moonargv.expand_response_files(
    ["@a.rsp"],
    { "a.rsp": "@b.rsp", "b.rsp": "@a.rsp" },
    @moonargv.Posix,
    @moonargv.response_limits(4, 16, 128),
  )
  guard expanded is Err(error) else { fail("expected response cycle") }
  assert_eq(error.kind(), @moonargv.ResponseFileCycle)
}

///|
test "P0-PROC-01 spilled process plan reconstructs original arguments" {
  let command = @moonargv.command_line("moonc")
    .unwrap()
    .append_all([
      "src/a.mbt", "generated source/b.mbt", "--output", "build app.wasm",
    ])
  let plan = @moonargv.plan_invocation(
    command,
    @moonargv.Posix,
    16,
    "compile.rsp",
  ).unwrap()
  assert_eq(plan.argv(), ["moonc", "@compile.rsp"])
  guard plan.response() is Some(response) else { fail("expected response") }
  let expanded = @moonargv.expand_response_files(
    ["@compile.rsp"],
    { "compile.rsp": response.content() },
    response.dialect(),
    @moonargv.response_limits(1, 16, 128),
  ).unwrap()
  assert_eq(expanded, command.arguments())
}

///|
test "P0-BRIDGE-01 command text yields argparse-ready argv tail" {
  let command = @moonargv.parse_command_line(
    "deploy --target 'staging cluster' --verbose",
    @moonargv.Posix,
  ).unwrap()
  assert_eq(command.program(), "deploy")
  assert_eq(command.arguments(), ["--target", "staging cluster", "--verbose"])
}

///|
test "P0-LIMIT-01 expanded argv obeys final count limit" {
  let expanded = @moonargv.expand_response_files(
    ["first", "@more.rsp"],
    { "more.rsp": "second third" },
    @moonargv.Posix,
    @moonargv.response_limits(2, 2, 64),
  )
  guard expanded is Err(error) else { fail("expected argument limit") }
  assert_eq(error.kind(), @moonargv.TooManyArguments)
}

///|
test "P0-ENV-01 Windows overlay is case-insensitive and redacts secrets" {
  let plan = @moonargv.apply_environment(
    [@moonargv.environment_entry("Path", "C:\\Windows")],
    [
      @moonargv.set_environment("PATH", "C:\\Moon\\bin"),
      @moonargv.set_environment("TOKEN", "private", sensitive=true),
    ],
    @moonargv.WindowsEnvironment,
  ).unwrap()
  assert_eq(plan.audit_lines(), ["PATH=C:\\Moon\\bin", "TOKEN=<redacted>"])
}

///|
test "P0-LOOKUP-01 Windows PATH and PATHEXT candidates are deterministic" {
  let plan = @moonargv.executable_candidates(
    "moonc",
    ["C:\\Moon\\bin"],
    @moonargv.WindowsHost,
    windows_extensions=[".EXE", ".CMD"],
  ).unwrap()
  assert_eq(plan.candidates(), [
    "C:\\Moon\\bin\\moonc", "C:\\Moon\\bin\\moonc.EXE", "C:\\Moon\\bin\\moonc.CMD",
  ])
}

///|
test "P0-AUDIT-01 secret values never enter the rendered audit command" {
  let rendered = @moonargv.render_redacted(
    ["deploy", "--token", "private", "--header=secret"],
    @moonargv.Posix,
    [
      @moonargv.secret_after_flag("--token"),
      @moonargv.secret_assignment("--header"),
    ],
  ).unwrap()
  assert_false(rendered.contains("private"))
  assert_false(rendered.contains("secret"))
  assert_eq(@moonargv.values(@moonargv.parse_posix(rendered).unwrap()), [
    "deploy", "--token", "<redacted>", "--header=<redacted>",
  ])
}

///|
test "P0-CONTRACT-01 one spec produces all host execution artifacts" {
  let spec = @moonargv.execution_spec(
      @moonargv.command_line("moonc")
      .unwrap()
      .append_all(["source path/main.mbt", "--token", "private"]),
    )
    .in_directory("/workspace")
    .set_environment("CI", "true")
    .redact(@moonargv.secret_after_flag("--token"))
  let prepared = @moonargv.prepare_execution(
    spec,
    [],
    ["/opt/moon/bin"],
    @moonargv.PosixTarget,
    limits=@moonargv.execution_limits(max_command_chars=12),
  ).unwrap()
  assert_eq(prepared.executable().candidates(), ["/opt/moon/bin/moonc"])
  assert_eq(prepared.environment().audit_lines(), ["CI=true"])
  assert_eq(prepared.invocation().argv(), ["moonc", "@.moonargv/arguments.rsp"])
  assert_false(prepared.audit_command().contains("private"))
}
