///|
test "offset compatibility page shares deterministic ordering" {
  let page = @moonpageflow.paginate_offset(sample_rows(), score_sort(), 1, 2).unwrap()
  assert_eq(page.rows().map(row => row.id()), ["b", "c"])
  assert_eq(page.info().total(), 5)
  assert_true(page.info().has_previous_page())
  assert_true(page.info().has_next_page())
}

///|
test "offset past end returns an empty page" {
  let page = @moonpageflow.paginate_offset(sample_rows(), score_sort(), 100, 10).unwrap()
  assert_eq(page.rows(), [])
  assert_eq(page.info().offset(), 5)
  assert_true(page.info().has_previous_page())
  assert_false(page.info().has_next_page())
}

///|
test "negative offset is rejected" {
  guard @moonpageflow.paginate_offset(sample_rows(), score_sort(), -1, 10)
    is Err(error) else {
    fail("expected offset error")
  }
  assert_eq(error.kind(), @moonpageflow.InvalidOffset)
}
