///|
fn response_test_limits() -> @moonargv.ResponseLimits {
  @moonargv.response_limits(4, 32, 128)
}

///|
test "response file expands quoted compiler arguments" {
  let files = {
    "compile.rsp": "src/main.mbt --output 'build artifacts/app.wasm'",
  }
  let expanded = @moonargv.expand_response_files(
    ["build", "@compile.rsp", "--release"],
    files,
    @moonargv.Posix,
    response_test_limits(),
  ).unwrap()
  assert_eq(expanded, [
    "build", "src/main.mbt", "--output", "build artifacts/app.wasm", "--release",
  ])
}

///|
test "response files expand recursively" {
  let files = {
    "outer.rsp": "@sources.rsp --target wasm-gc",
    "sources.rsp": "a.mbt 'folder/b file.mbt'",
  }
  assert_eq(
    @moonargv.expand_response_files(
      ["@outer.rsp"],
      files,
      @moonargv.Posix,
      response_test_limits(),
    ).unwrap(),
    ["a.mbt", "folder/b file.mbt", "--target", "wasm-gc"],
  )
}

///|
test "double at escapes a literal response marker" {
  assert_eq(
    @moonargv.expand_response_files(
      ["@@literal", "@"],
      Map([]),
      @moonargv.Posix,
      response_test_limits(),
    ).unwrap(),
    ["@literal", "@"],
  )
}

///|
test "Windows response file uses CRT quoting" {
  let files = { "link.rsp": "a.obj \"build folder\\app.exe\"" }
  assert_eq(
    @moonargv.expand_response_files(
      ["@link.rsp"],
      files,
      @moonargv.Windows,
      response_test_limits(),
    ).unwrap(),
    ["a.obj", "build folder\\app.exe"],
  )
}

///|
test "missing response file is structured" {
  let result = @moonargv.expand_response_files(
    ["@missing.rsp"],
    Map([]),
    @moonargv.Posix,
    response_test_limits(),
  )
  guard result is Err(error) else { fail("expected missing-file error") }
  assert_eq(error.kind(), @moonargv.ResponseFileNotFound)
}

///|
test "response cycle is rejected" {
  let result = @moonargv.expand_response_files(
    ["@a.rsp"],
    { "a.rsp": "@b.rsp", "b.rsp": "@a.rsp" },
    @moonargv.Posix,
    response_test_limits(),
  )
  guard result is Err(error) else { fail("expected cycle error") }
  assert_eq(error.kind(), @moonargv.ResponseFileCycle)
}

///|
test "response depth and final argv limits are enforced" {
  let depth_result = @moonargv.expand_response_files(
    ["@a.rsp"],
    { "a.rsp": "@b.rsp", "b.rsp": "value" },
    @moonargv.Posix,
    @moonargv.response_limits(1, 10, 20),
  )
  guard depth_result is Err(depth_error) else { fail("expected depth error") }
  assert_eq(depth_error.kind(), @moonargv.ResponseFileDepthExceeded)

  let count_result = @moonargv.expand_response_files(
    ["first", "@more.rsp"],
    { "more.rsp": "second third" },
    @moonargv.Posix,
    @moonargv.response_limits(2, 2, 20),
  )
  guard count_result is Err(count_error) else { fail("expected count error") }
  assert_eq(count_error.kind(), @moonargv.TooManyArguments)
}
