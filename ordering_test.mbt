///|
fn ordering_rows() -> Array[@moonpageflow.PageRow] {
  [
    @moonpageflow.page_row("b", [
      ("score", @moonpageflow.int_value(10L)),
      ("name", @moonpageflow.text_value("Beta")),
    ]).unwrap(),
    @moonpageflow.page_row("a", [
      ("score", @moonpageflow.int_value(10L)),
      ("name", @moonpageflow.text_value("Alpha")),
    ]).unwrap(),
    @moonpageflow.page_row("c", [
      ("score", @moonpageflow.int_value(20L)),
      ("name", @moonpageflow.null_value()),
    ]).unwrap(),
  ]
}

///|
test "sort uses declared keys then unique id tie-breaker" {
  let sort = [@moonpageflow.sort_field("score")]
  let rows = @moonpageflow.sort_rows(ordering_rows(), sort).unwrap()
  assert_eq(rows.map(row => row.id()), ["a", "b", "c"])
}

///|
test "descending sort and explicit null placement are deterministic" {
  let sort = [
    @moonpageflow.sort_field(
      "name",
      direction=@moonpageflow.Descending,
      nulls=@moonpageflow.NullsFirst,
    ),
  ]
  let rows = @moonpageflow.sort_rows(ordering_rows(), sort).unwrap()
  assert_eq(rows.map(row => row.id()), ["c", "b", "a"])
}

///|
test "missing sort value returns structured error" {
  let rows = [@moonpageflow.page_row("a", []).unwrap()]
  guard @moonpageflow.sort_rows(rows, [@moonpageflow.sort_field("score")])
    is Err(error) else {
    fail("expected missing value")
  }
  assert_eq(error.kind(), @moonpageflow.MissingSortValue)
  assert_eq(error.field(), "score")
}

///|
test "duplicate ids cannot form a stable ordering" {
  let rows = [
    @moonpageflow.page_row("same", []).unwrap(),
    @moonpageflow.page_row("same", []).unwrap(),
  ]
  guard @moonpageflow.sort_rows(rows, []) is Err(error) else {
    fail("expected duplicate id")
  }
  assert_eq(error.kind(), @moonpageflow.DuplicateRowId)
}

///|
test "position comparison rejects another sort contract" {
  let row = ordering_rows()[0]
  let position = @moonpageflow.position_for(row, [
    @moonpageflow.sort_field("score"),
  ]).unwrap()
  guard @moonpageflow.compare_row_to_position(row, position, [
      @moonpageflow.sort_field("name"),
    ])
    is Err(error) else {
    fail("expected sort mismatch")
  }
  assert_eq(error.kind(), @moonpageflow.CursorSortMismatch)
}
