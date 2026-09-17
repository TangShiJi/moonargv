///|
fn sample_rows() -> Array[@moonpageflow.PageRow] {
  [
    @moonpageflow.page_row("a", [("score", @moonpageflow.int_value(10L))]).unwrap(),
    @moonpageflow.page_row("b", [("score", @moonpageflow.int_value(10L))]).unwrap(),
    @moonpageflow.page_row("c", [("score", @moonpageflow.int_value(20L))]).unwrap(),
    @moonpageflow.page_row("d", [("score", @moonpageflow.int_value(30L))]).unwrap(),
    @moonpageflow.page_row("e", [("score", @moonpageflow.int_value(40L))]).unwrap(),
  ]
}

///|
fn score_sort() -> Array[@moonpageflow.SortField] {
  [@moonpageflow.sort_field("score")]
}

///|
test "forward pages use an exclusive stable boundary" {
  let first = @moonpageflow.paginate(
    sample_rows(),
    score_sort(),
    @moonpageflow.first_page(limit=2).unwrap(),
    snapshot=Some("v1"),
  ).unwrap()
  assert_eq(@moonpageflow.page_rows(first).map(row => row.id()), ["a", "b"])
  assert_false(first.info().has_previous_page())
  assert_true(first.info().has_next_page())
  let second = @moonpageflow.paginate(
    sample_rows(),
    score_sort(),
    @moonpageflow.first_page(limit=2, after=first.info().end_cursor()).unwrap(),
    snapshot=Some("v1"),
  ).unwrap()
  assert_eq(@moonpageflow.page_rows(second).map(row => row.id()), ["c", "d"])
  assert_true(second.info().has_previous_page())
  assert_true(second.info().has_next_page())
}

///|
test "backward page returns natural display order" {
  let last = @moonpageflow.paginate(
    sample_rows(),
    score_sort(),
    @moonpageflow.last_page(limit=2).unwrap(),
  ).unwrap()
  assert_eq(@moonpageflow.page_rows(last).map(row => row.id()), ["d", "e"])
  assert_true(last.info().has_previous_page())
  assert_false(last.info().has_next_page())
  let previous = @moonpageflow.paginate(
    sample_rows(),
    score_sort(),
    @moonpageflow.last_page(limit=2, before=last.info().start_cursor()).unwrap(),
  ).unwrap()
  assert_eq(@moonpageflow.page_rows(previous).map(row => row.id()), ["b", "c"])
}

///|
test "same sort values do not repeat across pages" {
  let first = @moonpageflow.paginate(
    sample_rows(),
    score_sort(),
    @moonpageflow.first_page(limit=1).unwrap(),
  ).unwrap()
  let second = @moonpageflow.paginate(
    sample_rows(),
    score_sort(),
    @moonpageflow.first_page(limit=1, after=first.info().end_cursor()).unwrap(),
  ).unwrap()
  assert_eq(@moonpageflow.page_rows(first)[0].id(), "a")
  assert_eq(@moonpageflow.page_rows(second)[0].id(), "b")
}

///|
test "insertion before cursor does not duplicate next page" {
  let first = @moonpageflow.paginate(
    sample_rows(),
    score_sort(),
    @moonpageflow.first_page(limit=2).unwrap(),
  ).unwrap()
  let changed = sample_rows()
  changed.push(
    @moonpageflow.page_row("zero", [("score", @moonpageflow.int_value(1L))]).unwrap(),
  )
  let second = @moonpageflow.paginate(
    changed,
    score_sort(),
    @moonpageflow.first_page(limit=2, after=first.info().end_cursor()).unwrap(),
  ).unwrap()
  assert_eq(@moonpageflow.page_rows(second).map(row => row.id()), ["c", "d"])
}

///|
test "snapshot-bound cursor rejects a changed revision" {
  let first = @moonpageflow.paginate(
    sample_rows(),
    score_sort(),
    @moonpageflow.first_page(limit=2).unwrap(),
    snapshot=Some("revision-1"),
  ).unwrap()
  guard @moonpageflow.paginate(
      sample_rows(),
      score_sort(),
      @moonpageflow.first_page(after=first.info().end_cursor()).unwrap(),
      snapshot=Some("revision-2"),
    )
    is Err(error) else {
    fail("expected snapshot mismatch")
  }
  assert_eq(error.kind(), @moonpageflow.SnapshotMismatch)
}

///|
test "cursor cannot be reused with another ordering" {
  let first = @moonpageflow.paginate(
    sample_rows(),
    score_sort(),
    @moonpageflow.first_page(limit=1).unwrap(),
  ).unwrap()
  guard @moonpageflow.paginate(
      sample_rows(),
      [@moonpageflow.sort_field("score", direction=@moonpageflow.Descending)],
      @moonpageflow.first_page(after=first.info().end_cursor()).unwrap(),
    )
    is Err(error) else {
    fail("expected cursor sort mismatch")
  }
  assert_eq(error.kind(), @moonpageflow.CursorSortMismatch)
}

///|
test "empty dataset returns empty navigation metadata" {
  let page = @moonpageflow.paginate(
    [],
    score_sort(),
    @moonpageflow.first_page().unwrap(),
  ).unwrap()
  assert_eq(page.edges().length(), 0)
  assert_eq(page.info().start_cursor(), None)
  assert_eq(page.info().end_cursor(), None)
  assert_false(page.info().has_previous_page())
  assert_false(page.info().has_next_page())
}
