///|
fn main {
  let prepared = @execution_contract.prepare_deploy()
  println(prepared.audit_command())
  for candidate in prepared.executable().candidates() {
    println(candidate)
  }
  for entry in prepared.environment().audit_lines() {
    println(entry)
  }
  for argument in prepared.invocation().argv() {
    println(argument)
  }
}
