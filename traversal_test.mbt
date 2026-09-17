///|
test "checkpoint advances through unique pages" {
  let first = @moonpageflow.paginate(
    sample_rows(),
    score_sort(),
    @moonpageflow.first_page(limit=2).unwrap(),
    snapshot=Some("scan-v1"),
  ).unwrap()
  let checkpoint = @moonpageflow.advance_checkpoint(
    @moonpageflow.traversal_checkpoint(snapshot=Some("scan-v1")),
    first,
  ).unwrap()
  assert_eq(checkpoint.pages(), 1)
  assert_eq(checkpoint.items(), 2)
  assert_eq(checkpoint.seen_ids(), ["a", "b"])
  let next = @moonpageflow.paginate(
    sample_rows(),
    score_sort(),
    checkpoint.next_request(2).unwrap(),
    snapshot=Some("scan-v1"),
  ).unwrap()
  let advanced = @moonpageflow.advance_checkpoint(checkpoint, next).unwrap()
  assert_eq(advanced.pages(), 2)
  assert_eq(advanced.items(), 4)
  assert_eq(advanced.seen_ids(), ["a", "b", "c", "d"])
}

///|
test "checkpoint rejects another snapshot" {
  let page = @moonpageflow.paginate(
    sample_rows(),
    score_sort(),
    @moonpageflow.first_page(limit=1).unwrap(),
    snapshot=Some("new"),
  ).unwrap()
  guard @moonpageflow.advance_checkpoint(
      @moonpageflow.traversal_checkpoint(snapshot=Some("old")),
      page,
    )
    is Err(error) else {
    fail("expected snapshot mismatch")
  }
  assert_eq(error.kind(), @moonpageflow.SnapshotMismatch)
}

///|
test "checkpoint detects a repeated page cursor" {
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
test "restored checkpoint validates duplicate ids" {
  guard @moonpageflow.restore_checkpoint(None, None, 1, 2, ["a", "a"])
    is Err(error) else {
    fail("expected duplicate checkpoint id")
  }
  assert_eq(error.kind(), @moonpageflow.DuplicateTraversalItem)
}
