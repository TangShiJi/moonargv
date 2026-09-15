///|
test "POSIX environment overlay is case-sensitive and deterministic" {
  let plan = @moonargv.apply_environment(
    [
      @moonargv.environment_entry("PATH", "/bin"),
      @moonargv.environment_entry("home", "/home/ci"),
    ],
    [
      @moonargv.set_environment("PATH", "/tool/bin"),
      @moonargv.set_environment("TOKEN", "secret", sensitive=true),
      @moonargv.set_environment("Path", "/case-sensitive"),
    ],
    @moonargv.PosixEnvironment,
  ).unwrap()
  assert_eq(plan.audit_lines(), [
    "PATH=/tool/bin", "Path=/case-sensitive", "home=/home/ci", "TOKEN=<redacted>",
  ])
}

///|
test "Windows environment overlay matches names without case" {
  let plan = @moonargv.apply_environment(
    [@moonargv.environment_entry("Path", "C:\\Windows")],
    [@moonargv.set_environment("PATH", "C:\\Tools")],
    @moonargv.WindowsEnvironment,
  ).unwrap()
  assert_eq(plan.audit_lines(), ["PATH=C:\\Tools"])
}

///|
test "environment removal records host adapter intent" {
  let plan = @moonargv.apply_environment(
    [
      @moonargv.environment_entry("CI", "true"),
      @moonargv.environment_entry("TOKEN", "old", sensitive=true),
    ],
    [@moonargv.remove_environment("TOKEN")],
    @moonargv.PosixEnvironment,
  ).unwrap()
  assert_eq(plan.audit_lines(), ["CI=true"])
  assert_eq(plan.removed(), ["TOKEN"])
}

///|
test "environment rejects duplicate Windows names" {
  let result = @moonargv.apply_environment(
    [
      @moonargv.environment_entry("Path", "one"),
      @moonargv.environment_entry("PATH", "two"),
    ],
    [],
    @moonargv.WindowsEnvironment,
  )
  guard result is Err(error) else { fail("expected duplicate error") }
  assert_eq(error.kind(), @moonargv.DuplicateEnvironmentName)
  assert_eq(error.field(), "PATH")
}

///|
test "environment validates names and configured resource bounds" {
  let invalid = @moonargv.apply_environment(
    [],
    [@moonargv.set_environment("BAD=NAME", "value")],
    @moonargv.PosixEnvironment,
  )
  guard invalid is Err(name_error) else { fail("expected name error") }
  assert_eq(name_error.kind(), @moonargv.InvalidEnvironmentName)
  let limited = @moonargv.apply_environment(
    [],
    [@moonargv.set_environment("A", "1"), @moonargv.set_environment("B", "2")],
    @moonargv.PosixEnvironment,
    limits=@moonargv.environment_limits(max_entries=1),
  )
  guard limited is Err(limit_error) else { fail("expected limit error") }
  assert_eq(limit_error.kind(), @moonargv.EnvironmentLimitExceeded)
}
