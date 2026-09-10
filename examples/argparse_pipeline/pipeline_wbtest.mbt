///|
test "MoonArgv output feeds standard argparse without losing quoted value" {
  let matches = try! parse_deploy("deploy --target 'staging cluster' --verbose")
  assert_eq(matches.values.get("target"), Some(["staging cluster"]))
  assert_eq(matches.flags.get("verbose"), Some(true))
}

///|
test "standard argparse still owns semantic option validation" {
  try parse_deploy("deploy --verbose") catch {
    error => assert_true(error.to_string().contains("target"))
  } noraise {
    _ => fail("expected argparse to reject a missing required option")
  }
}
