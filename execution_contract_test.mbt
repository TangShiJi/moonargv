///|
test "prepare POSIX execution produces complete host contract" {
  let command = @moonargv.command_line("deploy")
    .unwrap()
    .append_all(["--token", "private", "--region", "cn-shanghai"])
  let spec = @moonargv.execution_spec(command)
    .in_directory("/workspace/app")
    .set_environment("CI", "true")
    .set_environment("DEPLOY_TOKEN", "private", sensitive=true)
    .redact(@moonargv.secret_after_flag("--token"))
    .stdin(@moonargv.ClosedInput)
  let prepared = @moonargv.prepare_execution(
    spec,
    [@moonargv.environment_entry("PATH", "/usr/bin")],
    ["/opt/tools", "/usr/bin"],
    @moonargv.PosixTarget,
  ).unwrap()
  assert_eq(prepared.invocation().argv(), [
    "deploy", "--token", "private", "--region", "cn-shanghai",
  ])
  assert_eq(prepared.executable().candidates(), [
    "/opt/tools/deploy", "/usr/bin/deploy",
  ])
  assert_eq(prepared.environment().audit_lines(), [
    "CI=true", "PATH=/usr/bin", "DEPLOY_TOKEN=<redacted>",
  ])
  assert_eq(
    @moonargv.values(@moonargv.parse_posix(prepared.audit_command()).unwrap()),
    ["deploy", "--token", "<redacted>", "--region", "cn-shanghai"],
  )
  assert_eq(prepared.working_directory(), Some("/workspace/app"))
  assert_eq(prepared.standard_input(), @moonargv.ClosedInput)
}

///|
test "prepare Windows execution creates reversible response artifact" {
  let command = @moonargv.command_line("link")
    .unwrap()
    .append_all(["build folder\\main.obj", "/OUT:release folder\\app.exe"])
  let prepared = @moonargv.prepare_execution(
    @moonargv.execution_spec(command),
    [],
    ["C:\\BuildTools"],
    @moonargv.WindowsTarget,
    response_path="build\\link.rsp",
    windows_extensions=[".EXE"],
    limits=@moonargv.execution_limits(max_command_chars=12),
  ).unwrap()
  assert_eq(prepared.executable().candidates(), [
    "C:\\BuildTools\\link", "C:\\BuildTools\\link.EXE",
  ])
  assert_eq(prepared.invocation().argv(), ["link", "@build\\link.rsp"])
  guard prepared.invocation().response() is Some(response) else {
    fail("expected response artifact")
  }
  assert_eq(
    @moonargv.values(@moonargv.parse_windows(response.content()).unwrap()),
    ["build folder\\main.obj", "/OUT:release folder\\app.exe"],
  )
}

///|
test "execution contract rejects invalid working directory" {
  let spec = @moonargv.execution_spec(@moonargv.command_line("tool").unwrap()).in_directory(
    "",
  )
  let result = @moonargv.prepare_execution(spec, [], [], @moonargv.PosixTarget)
  guard result is Err(error) else { fail("expected directory error") }
  assert_eq(error.kind(), @moonargv.InvalidWorkingDirectory)
}

///|
test "execution contract bounds logical argv before planning" {
  let command = @moonargv.command_line("tool")
    .unwrap()
    .append_all(["one", "two"])
  let result = @moonargv.prepare_execution(
    @moonargv.execution_spec(command),
    [],
    [],
    @moonargv.PosixTarget,
    limits=@moonargv.execution_limits(max_arguments=2),
  )
  guard result is Err(error) else { fail("expected argument limit") }
  assert_eq(error.kind(), @moonargv.ArgumentLimitExceeded)
}

///|
test "execution contract reports unusable response path" {
  let command = @moonargv.command_line("tool")
    .unwrap()
    .argument("a very long argument")
  let result = @moonargv.prepare_execution(
    @moonargv.execution_spec(command),
    [],
    [],
    @moonargv.PosixTarget,
    response_path="",
    limits=@moonargv.execution_limits(max_command_chars=1),
  )
  guard result is Err(error) else { fail("expected response planning error") }
  assert_eq(error.kind(), @moonargv.ResponsePlanningFailed)
}
