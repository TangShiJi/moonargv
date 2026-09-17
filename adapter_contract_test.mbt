///|
test "adapter conformance accepts canonical forward query result" {
  let rows = sample_rows()
  let sort = score_sort()
  let boundary = @moonpageflow.position_for(rows[1], sort).unwrap()
  let result = @moonpageflow.verify_seek_ids(
    ["c", "d"],
    rows,
    boundary,
    sort,
    @moonpageflow.ForwardPage,
    2,
  ).unwrap()
  assert_true(result.matches())
  assert_eq(result.expected_ids(), ["c", "d"])
}

///|
test "adapter conformance reports ordering mismatch" {
  let rows = sample_rows()
  let sort = score_sort()
  let boundary = @moonpageflow.position_for(rows[1], sort).unwrap()
  let result = @moonpageflow.verify_seek_ids(
    ["d", "c"],
    rows,
    boundary,
    sort,
    @moonpageflow.ForwardPage,
    2,
  ).unwrap()
  assert_false(result.matches())
  assert_eq(result.actual_ids(), ["d", "c"])
}

///|
test "adapter conformance keeps canonical order for backward page" {
  let rows = sample_rows()
  let sort = score_sort()
  let boundary = @moonpageflow.position_for(rows[4], sort).unwrap()
  assert_eq(
    @moonpageflow.expected_seek_ids(
      rows,
      boundary,
      sort,
      @moonpageflow.BackwardPage,
      2,
    ).unwrap(),
    ["c", "d"],
  )
}
