///|
fn generated_rows(count : Int) -> Array[@moonpageflow.PageRow] {
  let rows : Array[@moonpageflow.PageRow] = []
  for index = 0; index < count; index = index + 1 {
    rows.push(
      @moonpageflow.page_row("row-" + index.to_string(), [
        ("bucket", @moonpageflow.int_value((index % 7).to_int64())),
        ("active", @moonpageflow.bool_value(index % 2 == 0)),
      ]).unwrap(),
    )
  }
  rows
}

///|
fn collect_forward_ids(
  rows : Array[@moonpageflow.PageRow],
  sort : Array[@moonpageflow.SortField],
  limit : Int,
) -> Array[String] {
  let ids : Array[String] = []
  let mut cursor : String? = None
  for attempts = 0; ids.length() < rows.length(); attempts = attempts + 1 {
    let page = @moonpageflow.paginate(
      rows,
      sort,
      @moonpageflow.first_page(limit~, after=cursor).unwrap(),
      snapshot=Some("property-v1"),
    ).unwrap()
    for row in @moonpageflow.page_rows(page) {
      ids.push(row.id())
    }
    if !page.info().has_next_page() {
      break
    }
    cursor = page.info().end_cursor()
  }
  ids
}

///|
test "paged traversal equals reference order across page sizes" {
  let rows = generated_rows(73)
  let sort = [
    @moonpageflow.sort_field("bucket", direction=@moonpageflow.Descending),
    @moonpageflow.sort_field("active", nulls=@moonpageflow.NullsFirst),
  ]
  let expected = @moonpageflow.sort_rows(rows, sort)
    .unwrap()
    .map(row => row.id())
  for limit in [1, 2, 7, 16, 50] {
    assert_eq(collect_forward_ids(rows, sort, limit), expected)
  }
}

///|
test "every generated cursor round trips its exact position" {
  let rows = generated_rows(73)
  let sort = [
    @moonpageflow.sort_field("bucket"),
    @moonpageflow.sort_field("active", direction=@moonpageflow.Descending),
  ]
  for row in rows {
    let position = @moonpageflow.position_for(row, sort).unwrap()
    let cursor = @moonpageflow.decode_cursor(
      @moonpageflow.encode_cursor(position, snapshot=Some("批次-九月")),
    ).unwrap()
    assert_eq(cursor.position(), position)
    assert_eq(cursor.snapshot(), Some("批次-九月"))
  }
}

///|
test "reference comparator is antisymmetric for generated rows" {
  let rows = generated_rows(31)
  let sort = [
    @moonpageflow.sort_field("bucket"),
    @moonpageflow.sort_field("active"),
  ]
  for left in rows {
    for right in rows {
      let forward = @moonpageflow.compare_rows(left, right, sort).unwrap()
      let reverse = @moonpageflow.compare_rows(right, left, sort).unwrap()
      assert_eq(forward, -reverse)
    }
  }
}

///|
test "merge sorter handles a large reverse-ordered input" {
  let rows : Array[@moonpageflow.PageRow] = []
  for index = 2047; index >= 0; index = index - 1 {
    rows.push(
      @moonpageflow.page_row("id-" + index.to_string(), [
        ("sequence", @moonpageflow.int_value(index.to_int64())),
      ]).unwrap(),
    )
  }
  let sorted = @moonpageflow.sort_rows(rows, [
    @moonpageflow.sort_field("sequence"),
  ]).unwrap()
  assert_eq(sorted.length(), 2048)
  assert_eq(sorted[0].value("sequence"), Some(@moonpageflow.int_value(0L)))
  assert_eq(
    sorted[2047].value("sequence"),
    Some(@moonpageflow.int_value(2047L)),
  )
}
