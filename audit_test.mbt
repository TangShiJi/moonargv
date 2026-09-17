///|
test "audit accepts a complete stable traversal" {
  let expected = sample_rows()
  let audit = @moonpageflow.audit_traversal(expected, expected, score_sort()).unwrap()
  assert_true(audit.is_clean())
  assert_eq(audit.observed_count(), 5)
  assert_eq(audit.unique_count(), 5)
  assert_true(@moonpageflow.format_audit(audit).contains("status=PASS"))
}

///|
test "audit exposes offset drift after insertion before boundary" {
  let baseline = sample_rows()
  let first = @moonpageflow.paginate_offset(baseline, score_sort(), 0, 2).unwrap()
  let changed = sample_rows()
  changed.push(
    @moonpageflow.page_row("zero", [("score", @moonpageflow.int_value(1L))]).unwrap(),
  )
  let second = @moonpageflow.paginate_offset(changed, score_sort(), 2, 3).unwrap()
  let observed = first.rows()
  observed.append(second.rows())
  let audit = @moonpageflow.audit_traversal(observed, baseline, score_sort()).unwrap()
  assert_false(audit.is_clean())
  assert_eq(audit.duplicate_ids(), ["b"])
  assert_eq(audit.missing_ids(), ["e"])
  assert_eq(audit.order_violations().length(), 1)
}

///|
test "keyset traversal remains stable after insertion before boundary" {
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
  let audit = @moonpageflow.audit_traversal(observed, baseline, score_sort()).unwrap()
  assert_true(audit.is_clean())
}

///|
test "audit distinguishes missing and unexpected records" {
  let expected = sample_rows()
  let observed = expected[:4].to_owned()
  observed.push(
    @moonpageflow.page_row("foreign", [("score", @moonpageflow.int_value(99L))]).unwrap(),
  )
  let audit = @moonpageflow.audit_traversal(observed, expected, score_sort()).unwrap()
  assert_eq(audit.missing_ids(), ["e"])
  assert_eq(audit.unexpected_ids(), ["foreign"])
}
