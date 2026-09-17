/// Direct P0 acceptance behavior. Names match ACCEPTANCE_CRITERIA.md.

///|
test "P0-ORDER-01 equal sort values use unique id tie-breaker" {
  let rows = @moonpageflow.sort_rows(sample_rows(), score_sort()).unwrap()
  assert_eq(rows.map(row => row.id()), ["a", "b", "c", "d", "e"])
}

///|
test "P0-CURSOR-01 composite Unicode cursor round trips" {
  let position = complex_cursor_position()
  let cursor = @moonpageflow.decode_cursor(
    @moonpageflow.encode_cursor(position, snapshot=Some("版本-1")),
  ).unwrap()
  assert_eq(cursor.position(), position)
  assert_eq(cursor.snapshot(), Some("版本-1"))
}

///|
test "P0-CURSOR-02 cursor corruption is rejected" {
  let token = @moonpageflow.encode_cursor(complex_cursor_position())
  let chars = token.to_array()
  let checksum_index = chars.length() - 1
  chars[checksum_index] = if chars[checksum_index] == '0' { '1' } else { '0' }
  let corrupted = chars.map(char => char.to_string()).join("")
  guard @moonpageflow.decode_cursor(corrupted) is Err(error) else {
    fail("expected cursor error")
  }
  assert_eq(error.kind(), @moonpageflow.CursorChecksumMismatch)
}

///|
test "P0-PAGE-01 forward and backward pages are symmetric" {
  let first = @moonpageflow.paginate(
    sample_rows(),
    score_sort(),
    @moonpageflow.first_page(limit=2).unwrap(),
  ).unwrap()
  let last = @moonpageflow.paginate(
    sample_rows(),
    score_sort(),
    @moonpageflow.last_page(limit=2).unwrap(),
  ).unwrap()
  assert_eq(@moonpageflow.page_rows(first).map(row => row.id()), ["a", "b"])
  assert_eq(@moonpageflow.page_rows(last).map(row => row.id()), ["d", "e"])
}

///|
test "P0-MUTATION-01 keyset avoids offset duplicate after insertion" {
  let baseline = sample_rows()
  let first = @moonpageflow.paginate(
    baseline,
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
    @moonpageflow.first_page(limit=3, after=first.info().end_cursor()).unwrap(),
  ).unwrap()
  let observed = @moonpageflow.page_rows(first)
  observed.append(@moonpageflow.page_rows(second))
  assert_true(
    @moonpageflow.audit_traversal(observed, baseline, score_sort())
    .unwrap()
    .is_clean(),
  )
}

///|
test "P0-SNAPSHOT-01 revision change rejects stale cursor" {
  let first = @moonpageflow.paginate(
    sample_rows(),
    score_sort(),
    @moonpageflow.first_page(limit=1).unwrap(),
    snapshot=Some("v1"),
  ).unwrap()
  guard @moonpageflow.paginate(
      sample_rows(),
      score_sort(),
      @moonpageflow.first_page(after=first.info().end_cursor()).unwrap(),
      snapshot=Some("v2"),
    )
    is Err(error) else {
    fail("expected snapshot mismatch")
  }
  assert_eq(error.kind(), @moonpageflow.SnapshotMismatch)
}

///|
test "P0-SEEK-01 database predicate has one branch per key plus id" {
  let sort = score_sort()
  let plan = @moonpageflow.build_seek_plan(
    @moonpageflow.position_for(sample_rows()[1], sort).unwrap(),
    sort,
    @moonpageflow.ForwardPage,
  ).unwrap()
  assert_eq(plan.branches().map(branch => branch.field()), ["score", "id"])
}

///|
test "P0-RESUME-01 traversal checkpoint rejects repeated page" {
  let page = @moonpageflow.paginate(
    sample_rows(),
    score_sort(),
    @moonpageflow.first_page(limit=1).unwrap(),
  ).unwrap()
  let checkpoint = @moonpageflow.restore_checkpoint(
    page.info().end_cursor(),
    None,
    1,
    1,
    [],
  ).unwrap()
  guard @moonpageflow.advance_checkpoint(checkpoint, page) is Err(error) else {
    fail("expected repeated cursor")
  }
  assert_eq(error.kind(), @moonpageflow.RepeatedCursor)
}

///|
test "P0-LIMIT-01 page size above policy is rejected" {
  let limits = @moonpageflow.page_limits(max_size=100)
  guard @moonpageflow.first_page(limit=101, limits~) is Err(error) else {
    fail("expected page limit")
  }
  assert_eq(error.kind(), @moonpageflow.InvalidPageSize)
}
