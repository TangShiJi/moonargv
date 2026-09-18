///|
fn signed_payload(payload : String) -> String {
  payload + "." + payload_checksum(payload).to_string()
}

///|
test "hex decoder accepts uppercase and rejects malformed input" {
  assert_eq(hex_decode("E4B8AD", "sample"), Ok("中"))
  guard hex_decode("0", "sample") is Err(odd) else {
    fail("expected odd hex failure")
  }
  assert_eq(odd.kind(), InvalidCursor)
  guard hex_decode("gg", "sample") is Err(invalid) else {
    fail("expected invalid hex failure")
  }
  assert_eq(invalid.kind(), InvalidCursor)
}

///|
test "integer decoders cover boundaries and malformed values" {
  assert_eq(parse_int64_value("9223372036854775807"), Ok(@int64.MAX_VALUE))
  assert_eq(parse_int64_value("-9223372036854775808"), Ok(@int64.MIN_VALUE))
  for value in ["", "-", "1x", "9223372036854775808", "-9223372036854775809"] {
    guard parse_int64_value(value) is Err(error) else {
      fail("expected invalid int64")
    }
    assert_eq(error.kind(), InvalidCursor)
  }
  for value in ["", "x", "999999999999999999999999999999"] {
    guard parse_positive_int(value, "number") is Err(error) else {
      fail("expected invalid positive integer")
    }
    assert_eq(error.kind(), InvalidCursor)
  }
}

///|
test "typed value decoder rejects unknown and malformed tags" {
  assert_eq(decode_page_value("b0"), Ok(BoolValue(false)))
  for value in ["", "z1", "b2", "x1", "t0", "i-"] {
    guard decode_page_value(value) is Err(error) else {
      fail("expected invalid typed value")
    }
    assert_eq(error.kind(), InvalidCursor)
  }
}

///|
test "well checksummed malformed cursors are rejected by field" {
  let cases = [
    signed_payload("2.-.0.61"),
    signed_payload("1.0.0.61"),
    signed_payload("1.-.1.61.x.l.i1.62"),
    signed_payload("1.-.1.61.a.x.i1.62"),
    signed_payload("1.-.1..a.l.i1.62"),
    signed_payload("1.-.0."),
  ]
  for token in cases {
    guard decode_cursor(token) is Err(_) else {
      fail("expected malformed cursor rejection")
    }
  }
}
