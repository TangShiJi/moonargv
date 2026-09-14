///|
test "build adapter reconstructs exact compiler argv from planned response" {
  let plan = prepare_compile()
  assert_eq(plan.argv(), ["moonc", "@build/compile.rsp"])
  guard plan.response() is Some(response) else { fail("expected response") }
  let files : Map[String, String] = Map([])
  files[response.path()] = response.content()
  let expanded = @moonargv.expand_response_files(
    [plan.argv()[1]],
    files,
    response.dialect(),
    @moonargv.response_limits(2, 32, 256),
  ).unwrap()
  assert_eq(expanded, [
    "src/main.mbt", "generated sources/routes.mbt", "generated sources/assets.mbt",
    "--target", "wasm-gc", "--output", "build artifacts/application.wasm",
  ])
}
