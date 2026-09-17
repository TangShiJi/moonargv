///|
test "row validates identity and duplicate fields" {
  let empty = @moonpageflow.page_row("", [])
  guard empty is Err(error) else { fail("expected empty id") }
  assert_eq(error.kind(), @moonpageflow.EmptyRowId)
  let duplicate = @moonpageflow.page_row("a", [
    ("score", @moonpageflow.int_value(1L)),
    ("score", @moonpageflow.int_value(2L)),
  ])
  guard duplicate is Err(error) else { fail("expected duplicate field") }
  assert_eq(error.kind(), @moonpageflow.DuplicateSortField)
}

///|
test "row accessors preserve typed values" {
  let row = @moonpageflow.page_row("item-1", [
    ("name", @moonpageflow.text_value("Moon")),
    ("active", @moonpageflow.bool_value(true)),
  ]).unwrap()
  assert_eq(row.id(), "item-1")
  assert_eq(row.value("name"), Some(@moonpageflow.TextValue("Moon")))
  assert_eq(row.value("missing"), None)
}
