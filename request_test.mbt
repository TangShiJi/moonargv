///|
test "page request uses bounded default size" {
  let limits = @moonpageflow.page_limits(default_size=25, max_size=50)
  assert_eq(@moonpageflow.first_page(limits~).unwrap().limit(), 25)
  assert_eq(@moonpageflow.last_page(limit=10, limits~).unwrap().limit(), 10)
}

///|
test "page request rejects invalid and oversized limits" {
  let limits = @moonpageflow.page_limits(max_size=50)
  guard @moonpageflow.first_page(limit=-1, limits~) is Err(first_error) else {
    fail("expected invalid size")
  }
  assert_eq(first_error.kind(), @moonpageflow.InvalidPageSize)
  guard @moonpageflow.last_page(limit=51, limits~) is Err(last_error) else {
    fail("expected maximum size")
  }
  assert_eq(last_error.kind(), @moonpageflow.InvalidPageSize)
}

///|
test "page request rejects cursor beyond resource limit" {
  let limits = @moonpageflow.page_limits(max_cursor_chars=32)
  let long = "x".repeat(33)
  guard @moonpageflow.first_page(after=Some(long), limits~) is Err(error) else {
    fail("expected cursor limit")
  }
  assert_eq(error.kind(), @moonpageflow.CursorTooLong)
}
