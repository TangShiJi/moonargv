///|
test "public model accessors preserve declared contract" {
  let row = @moonpageflow.page_row("row-a", [
    ("score", @moonpageflow.int_value(7L)),
  ]).unwrap()
  assert_eq(row.values(), [("score", @moonpageflow.int_value(7L))])
  let field = @moonpageflow.sort_field(
    "score",
    direction=@moonpageflow.Descending,
    nulls=@moonpageflow.NullsFirst,
  )
  assert_eq(field.name(), "score")
  assert_eq(field.direction(), @moonpageflow.Descending)
  assert_eq(field.nulls(), @moonpageflow.NullsFirst)
  let position = @moonpageflow.position_for(row, [field]).unwrap()
  assert_eq(position.tie_breaker(), "row-a")
  let part = position.parts()[0]
  assert_eq(part.field(), "score")
  assert_eq(part.value(), @moonpageflow.int_value(7L))
  assert_eq(part.direction(), @moonpageflow.Descending)
  assert_eq(part.nulls(), @moonpageflow.NullsFirst)
  let page = @moonpageflow.paginate(
    [row],
    [field],
    @moonpageflow.first_page(limit=1).unwrap(),
    snapshot=Some("model-v1"),
  ).unwrap()
  let edge = page.edges()[0]
  assert_eq(edge.row().id(), "row-a")
  assert_true(edge.cursor().length() > 0)
  assert_eq(page.info().snapshot(), Some("model-v1"))
  guard @moonpageflow.page_row("", []) is Err(error) else {
    fail("expected empty row id")
  }
  assert_true(error.message().length() > 0)
}

///|
test "limit normalization and request accessors are observable" {
  let limits = @moonpageflow.page_limits(
    default_size=0,
    max_size=0,
    max_sort_fields=0,
    max_cursor_chars=1,
    max_rows=0,
  )
  assert_eq(limits.default_size(), 1)
  assert_eq(limits.max_size(), 1)
  assert_eq(limits.max_sort_fields(), 1)
  assert_eq(limits.max_cursor_chars(), 32)
  assert_eq(limits.max_rows(), 1)
  let request = @moonpageflow.last_page(limit=1, before=Some("cursor")).unwrap()
  assert_eq(request.mode(), @moonpageflow.BackwardPage)
  assert_eq(request.cursor(), Some("cursor"))
}

///|
test "sort and resource contract rejects invalid declarations" {
  guard @moonpageflow.validate_sort([@moonpageflow.sort_field("id")])
    is Err(id_error) else {
    fail("expected reserved id field")
  }
  assert_eq(id_error.kind(), @moonpageflow.EmptySortField)
  guard @moonpageflow.validate_sort([
      @moonpageflow.sort_field("score"),
      @moonpageflow.sort_field("score"),
    ])
    is Err(duplicate) else {
    fail("expected duplicate sort field")
  }
  assert_eq(duplicate.kind(), @moonpageflow.DuplicateSortField)
  let limits = @moonpageflow.page_limits(max_sort_fields=1, max_rows=1)
  guard @moonpageflow.validate_sort(
      [@moonpageflow.sort_field("a"), @moonpageflow.sort_field("b")],
      limits~,
    )
    is Err(too_many_fields) else {
    fail("expected sort field limit")
  }
  assert_eq(too_many_fields.kind(), @moonpageflow.TooManySortFields)
  guard @moonpageflow.sort_rows(sample_rows(), score_sort(), limits~)
    is Err(too_many_rows) else {
    fail("expected row limit")
  }
  assert_eq(too_many_rows.kind(), @moonpageflow.TooManyRows)
}

///|
test "adapter oracle validates bounds and short backward ranges" {
  let rows = sample_rows()
  let sort = score_sort()
  let boundary = @moonpageflow.position_for(rows[1], sort).unwrap()
  guard @moonpageflow.expected_seek_ids(
      rows,
      boundary,
      sort,
      @moonpageflow.ForwardPage,
      0,
    )
    is Err(error) else {
    fail("expected adapter limit error")
  }
  assert_eq(error.kind(), @moonpageflow.InvalidPageSize)
  let near_start = @moonpageflow.position_for(rows[1], sort).unwrap()
  assert_eq(
    @moonpageflow.expected_seek_ids(
      rows,
      near_start,
      sort,
      @moonpageflow.BackwardPage,
      10,
    ).unwrap(),
    ["a"],
  )
}

///|
test "audit and seek plans expose actionable diagnostics" {
  let rows = sample_rows()
  let observed = [rows[1], rows[0], rows[2], rows[3], rows[4]]
  let audit = @moonpageflow.audit_traversal(observed, rows, score_sort()).unwrap()
  assert_false(audit.is_clean())
  let violation = audit.order_violations()[0]
  assert_eq(violation.previous_id(), "b")
  assert_eq(violation.current_id(), "a")
  let boundary = @moonpageflow.position_for(rows[1], score_sort()).unwrap()
  let plan = @moonpageflow.build_seek_plan(
    boundary,
    score_sort(),
    @moonpageflow.ForwardPage,
  ).unwrap()
  let branch = plan.branches()[1]
  assert_eq(branch.value(), @moonpageflow.text_value("b"))
  assert_eq(branch.nulls(), @moonpageflow.NullsLast)
  let prefix = branch.equal_prefix()[0]
  assert_eq(prefix.field(), "score")
  assert_eq(prefix.value(), @moonpageflow.int_value(10L))
  assert_eq(prefix.nulls(), @moonpageflow.NullsLast)
}

///|
test "checkpoint and snapshot failures cannot be silently ignored" {
  guard @moonpageflow.restore_checkpoint(None, None, -1, 0, [])
    is Err(counter_error) else {
    fail("expected negative checkpoint counter")
  }
  assert_eq(counter_error.kind(), @moonpageflow.InvalidOffset)
  let first = @moonpageflow.paginate(
    sample_rows(),
    score_sort(),
    @moonpageflow.first_page(limit=1).unwrap(),
  ).unwrap()
  let checkpoint = @moonpageflow.restore_checkpoint(None, None, 0, 1, ["a"]).unwrap()
  guard @moonpageflow.advance_checkpoint(checkpoint, first) is Err(repeated) else {
    fail("expected repeated traversal item")
  }
  assert_eq(repeated.kind(), @moonpageflow.DuplicateTraversalItem)
  let last = @moonpageflow.paginate(
    sample_rows(),
    score_sort(),
    @moonpageflow.last_page(limit=1).unwrap(),
  ).unwrap()
  assert_true(@moonpageflow.traversal_complete(last))
  let versioned = @moonpageflow.paginate(
    sample_rows(),
    score_sort(),
    @moonpageflow.first_page(limit=1).unwrap(),
    snapshot=Some("v1"),
  ).unwrap()
  guard @moonpageflow.paginate(
      sample_rows(),
      score_sort(),
      @moonpageflow.first_page(after=versioned.info().end_cursor()).unwrap(),
    )
    is Err(snapshot_error) else {
    fail("expected required snapshot")
  }
  assert_eq(snapshot_error.kind(), @moonpageflow.SnapshotMismatch)
}

///|
test "offset compatibility rejects oversized requests" {
  let limits = @moonpageflow.page_limits(max_size=2)
  guard @moonpageflow.paginate_offset(
      sample_rows(),
      score_sort(),
      0,
      3,
      limits~,
    )
    is Err(error) else {
    fail("expected offset page size error")
  }
  assert_eq(error.kind(), @moonpageflow.InvalidPageSize)
}
