///|
test "database adapter receives three typed OR branches" {
  let plan = next_ticket_seek()
  let branches = plan.branches()
  assert_eq(branches.length(), 3)
  assert_eq(branches.map(branch => branch.field()), [
    "created_at", "priority", "id",
  ])
  assert_eq(branches[0].comparison(), @moonpageflow.LessThan)
  assert_eq(branches[1].comparison(), @moonpageflow.GreaterThan)
  assert_eq(branches[2].comparison(), @moonpageflow.GreaterThan)
}
