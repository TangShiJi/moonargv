///|
test "POSIX executable candidates preserve PATH order" {
  let plan = @moonargv.executable_candidates(
    "moon",
    ["/opt/moon/bin", "/usr/local/bin", "/usr/bin"],
    @moonargv.PosixHost,
  ).unwrap()
  assert_false(plan.has_explicit_path())
  assert_eq(plan.candidates(), [
    "/opt/moon/bin/moon", "/usr/local/bin/moon", "/usr/bin/moon",
  ])
}

///|
test "Windows candidates apply PATHEXT and remove case duplicates" {
  let plan = @moonargv.executable_candidates(
    "moonc",
    ["C:\\Moon\\bin", "c:\\moon\\BIN"],
    @moonargv.WindowsHost,
    windows_extensions=["EXE", ".CMD", ".exe"],
  ).unwrap()
  assert_eq(plan.candidates(), [
    "C:\\Moon\\bin\\moonc", "C:\\Moon\\bin\\moonc.EXE", "C:\\Moon\\bin\\moonc.CMD",
  ])
}

///|
test "explicit Windows executable is not searched" {
  let plan = @moonargv.executable_candidates(
    ".\\tools\\deploy.exe",
    ["C:\\ignored"],
    @moonargv.WindowsHost,
  ).unwrap()
  assert_true(plan.has_explicit_path())
  assert_eq(plan.candidates(), [".\\tools\\deploy.exe"])
}

///|
test "candidate generation is bounded" {
  let result = @moonargv.executable_candidates(
    "tool",
    ["one", "two"],
    @moonargv.WindowsHost,
    windows_extensions=[".EXE", ".CMD"],
    max_candidates=3,
  )
  guard result is Err(error) else { fail("expected candidate limit") }
  assert_eq(error.kind(), @moonargv.CandidateLimitExceeded)
}
