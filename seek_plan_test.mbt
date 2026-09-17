///|
test "seek plan emits lexicographic branches including id" {
  let sort = [
    @moonpageflow.sort_field("created_at", direction=@moonpageflow.Descending),
    @moonpageflow.sort_field("priority"),
  ]
  let row = @moonpageflow.page_row("ticket-9", [
    ("created_at", @moonpageflow.int_value(100L)),
    ("priority", @moonpageflow.int_value(2L)),
  ]).unwrap()
  let plan = @moonpageflow.build_seek_plan(
    @moonpageflow.position_for(row, sort).unwrap(),
    sort,
    @moonpageflow.ForwardPage,
  ).unwrap()
  let branches = plan.branches()
  assert_eq(branches.length(), 3)
  assert_eq(branches[0].field(), "created_at")
  assert_eq(branches[0].comparison(), @moonpageflow.LessThan)
  assert_eq(branches[0].equal_prefix().length(), 0)
  assert_eq(branches[1].field(), "priority")
  assert_eq(branches[1].equal_prefix().length(), 1)
  assert_eq(branches[2].field(), "id")
  assert_eq(branches[2].comparison(), @moonpageflow.GreaterThan)
  assert_eq(branches[2].equal_prefix().length(), 2)
}

///|
test "backward seek reverses comparisons and query order" {
  let sort = [@moonpageflow.sort_field("score")]
  let row = @moonpageflow.page_row("b", [
    ("score", @moonpageflow.int_value(10L)),
  ]).unwrap()
  let plan = @moonpageflow.build_seek_plan(
    @moonpageflow.position_for(row, sort).unwrap(),
    sort,
    @moonpageflow.BackwardPage,
  ).unwrap()
  assert_true(plan.reverse_query_order())
  assert_eq(plan.branches()[0].comparison(), @moonpageflow.LessThan)
  assert_eq(plan.branches()[1].comparison(), @moonpageflow.LessThan)
}
