///|
fn complex_cursor_position() -> @moonpageflow.PagePosition {
  let row = @moonpageflow.page_row("项目.42", [
    ("score", @moonpageflow.int_value(-42L)),
    ("title", @moonpageflow.text_value("月亮.分页")),
    ("active", @moonpageflow.bool_value(true)),
    ("deleted", @moonpageflow.null_value()),
  ]).unwrap()
  @moonpageflow.position_for(row, [
    @moonpageflow.sort_field("score", direction=@moonpageflow.Descending),
    @moonpageflow.sort_field("title"),
    @moonpageflow.sort_field("active"),
    @moonpageflow.sort_field("deleted", nulls=@moonpageflow.NullsFirst),
  ]).unwrap()
}

///|
test "cursor round trip preserves composite typed position" {
  let position = complex_cursor_position()
  let token = @moonpageflow.encode_cursor(
    position,
    snapshot=Some("revision.中文"),
  )
  let decoded = match @moonpageflow.decode_cursor(token) {
    Ok(value) => value
    Err(error) => fail(error.message())
  }
  assert_eq(decoded.version(), 1)
  assert_eq(decoded.snapshot(), Some("revision.中文"))
  assert_eq(decoded.position(), position)
}

///|
test "cursor token is URL-safe ASCII" {
  let token = @moonpageflow.encode_cursor(complex_cursor_position())
  for char in token.to_array() {
    assert_true(
      (char >= 'a' && char <= 'z') ||
      (char >= '0' && char <= '9') ||
      char == '.' ||
      char == '-',
    )
  }
}

///|
test "cursor checksum detects tampering" {
  let token = @moonpageflow.encode_cursor(complex_cursor_position())
  let chars = token.to_array()
  chars[2] = if chars[2] == '0' { '1' } else { '0' }
  let tampered = chars.map(char => char.to_string()).join("")
  guard @moonpageflow.decode_cursor(tampered) is Err(error) else {
    fail("expected checksum mismatch")
  }
  assert_eq(error.kind(), @moonpageflow.CursorChecksumMismatch)
}

///|
test "cursor decoder rejects malformed structure" {
  guard @moonpageflow.decode_cursor("1.-.0.deadbeef.1") is Err(error) else {
    fail("expected invalid cursor")
  }
  assert_true(
    error.kind() is @moonpageflow.CursorChecksumMismatch ||
    error.kind() is @moonpageflow.InvalidCursor,
  )
}

///|
test "cursor decoder enforces configured length" {
  let token = @moonpageflow.encode_cursor(complex_cursor_position())
  let limits = @moonpageflow.page_limits(max_cursor_chars=32)
  guard @moonpageflow.decode_cursor(token, limits~) is Err(error) else {
    fail("expected cursor limit")
  }
  assert_eq(error.kind(), @moonpageflow.CursorTooLong)
}

///|
test "decoded cursor rejects a changed sort contract" {
  let decoded = match
    @moonpageflow.decode_cursor(
      @moonpageflow.encode_cursor(complex_cursor_position()),
    ) {
    Ok(value) => value
    Err(error) => fail(error.message())
  }
  let row = @moonpageflow.page_row("项目.43", [
    ("title", @moonpageflow.text_value("next")),
  ]).unwrap()
  guard @moonpageflow.compare_row_to_position(row, decoded.position(), [
      @moonpageflow.sort_field("title"),
    ])
    is Err(error) else {
    fail("expected sort mismatch")
  }
  assert_eq(error.kind(), @moonpageflow.CursorSortMismatch)
}
