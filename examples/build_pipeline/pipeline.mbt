///|
/// Prepare a compiler process without manually concatenating shell text.
/// The deliberately low threshold makes the example exercise response files.
pub fn prepare_compile() -> @moonargv.InvocationPlan {
  let command = @moonargv.command_line("moonc")
    .unwrap()
    .append_all([
      "src/main.mbt", "generated sources/routes.mbt", "generated sources/assets.mbt",
      "--target", "wasm-gc", "--output", "build artifacts/application.wasm",
    ])
  @moonargv.plan_invocation(command, @moonargv.Posix, 48, "build/compile.rsp").unwrap()
}
