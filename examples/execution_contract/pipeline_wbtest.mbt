///|
test "deployment example exposes executable environment response and audit plans" {
  let prepared = prepare_deploy()
  assert_eq(prepared.executable().candidates(), [
    "/opt/deploy/bin/deploy-agent", "/usr/bin/deploy-agent",
  ])
  assert_eq(prepared.environment().audit_lines(), [
    "CI=true", "PATH=/usr/bin", "DEPLOY_TOKEN=<redacted>",
  ])
  assert_eq(prepared.invocation().argv(), [
    "deploy-agent", "@.moonargv/arguments.rsp",
  ])
  assert_false(prepared.audit_command().contains("private-value"))
}
