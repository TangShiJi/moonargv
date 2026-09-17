///|
test "activity feed uses id to separate equal timestamps" {
  let first = first_activity_page()
  assert_eq(@moonpageflow.page_rows(first).map(row => row.id()), [
    "event-100", "event-101",
  ])
  guard first.info().end_cursor() is Some(cursor) else {
    fail("missing cursor")
  }
  let second = next_activity_page(cursor)
  assert_eq(@moonpageflow.page_rows(second).map(row => row.id()), [
    "event-099", "event-098",
  ])
  assert_false(second.info().has_next_page())
}
