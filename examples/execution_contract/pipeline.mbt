///|
/// Model a deployment launched by a native process library or a wasm host.
pub fn prepare_deploy() -> @moonargv.PreparedExecution {
  let command = @moonargv.command_line("deploy-agent")
    .unwrap()
    .append_all([
      "--workspace", "release workspace", "--token", "private-value", "--manifest",
      "build manifest.json",
    ])
  let spec = @moonargv.execution_spec(command)
    .in_directory("/workspace/project")
    .set_environment("CI", "true")
    .set_environment("DEPLOY_TOKEN", "private-value", sensitive=true)
    .redact(@moonargv.secret_after_flag("--token"))
    .stdin(@moonargv.ClosedInput)
  @moonargv.prepare_execution(
    spec,
    [@moonargv.environment_entry("PATH", "/usr/bin")],
    ["/opt/deploy/bin", "/usr/bin"],
    @moonargv.PosixTarget,
    limits=@moonargv.execution_limits(max_command_chars=48),
  ).unwrap()
}
