///|
test "short process invocation stays as direct argv" {
  let command = @moonargv.command_line("moon")
    .unwrap()
    .append_all(["test", "--target", "native"])
  let plan = @moonargv.plan_invocation(
    command,
    @moonargv.Posix,
    1024,
    "build/moon.rsp",
  ).unwrap()
  assert_eq(plan.argv(), ["moon", "test", "--target", "native"])
  assert_eq(plan.response(), None)
}

///|
test "long build invocation spills a reversible POSIX response file" {
  let command = @moonargv.command_line("moonc")
    .unwrap()
    .append_all([
      "src/main.mbt", "folder/source file.mbt", "--output", "build/app.wasm",
    ])
  let plan = @moonargv.plan_invocation(
    command,
    @moonargv.Posix,
    20,
    "build/compile.rsp",
  ).unwrap()
  assert_eq(plan.argv(), ["moonc", "@build/compile.rsp"])
  guard plan.response() is Some(response) else { fail("expected response") }
  assert_eq(response.path(), "build/compile.rsp")
  assert_eq(
    @moonargv.values(
      @moonargv.parse(response.content(), response.dialect()).unwrap(),
    ),
    command.arguments(),
  )
}

///|
test "Windows process plan preserves paths through response round trip" {
  let command = @moonargv.command_line("link.exe")
    .unwrap()
    .append_all(["build folder\\main.obj", "/OUT:release folder\\app.exe"])
  let plan = @moonargv.plan_invocation(
    command,
    @moonargv.Windows,
    8,
    "build\\link.rsp",
  ).unwrap()
  guard plan.response() is Some(response) else { fail("expected response") }
  assert_eq(
    @moonargv.values(@moonargv.parse_windows(response.content()).unwrap()),
    command.arguments(),
  )
}

///|
test "spilling rejects an empty response path" {
  let command = @moonargv.command_line("tool")
    .unwrap()
    .argument("long argument")
  let result = @moonargv.plan_invocation(command, @moonargv.Posix, 1, "")
  guard result is Err(error) else { fail("expected invalid path") }
  assert_eq(error.kind(), @moonargv.InvalidResponsePath)
}
