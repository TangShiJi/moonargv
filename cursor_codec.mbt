///|
const CURSOR_VERSION : Int = 1

///|
const CHECKSUM_MODULUS : Int = 10000019

///|
fn hex_digit(value : Int) -> Char {
  "0123456789abcdef".to_array()[value]
}

///|
fn hex_value(value : Char) -> Int {
  if value >= '0' && value <= '9' {
    value.to_int() - '0'.to_int()
  } else if value >= 'a' && value <= 'f' {
    value.to_int() - 'a'.to_int() + 10
  } else if value >= 'A' && value <= 'F' {
    value.to_int() - 'A'.to_int() + 10
  } else {
    -1
  }
}

///|
fn hex_encode(value : String) -> String {
  let output = StringBuilder()
  for byte in @utf8.encode(value[:]) {
    let number = byte.to_int()
    output.write_char(hex_digit(number / 16))
    output.write_char(hex_digit(number % 16))
  }
  output.to_string()
}

///|
fn hex_decode(value : String, field : String) -> Result[String, PageError] {
  let chars = value.to_array()
  if chars.length() % 2 != 0 {
    return Err(
      page_error(
        InvalidCursor,
        field,
        "hex encoded cursor field has odd length",
      ),
    )
  }
  let bytes : Array[Byte] = []
  for index = 0; index < chars.length(); index = index + 2 {
    let high = hex_value(chars[index])
    let low = hex_value(chars[index + 1])
    if high < 0 || low < 0 {
      return Err(
        page_error(InvalidCursor, field, "cursor field contains invalid hex"),
      )
    }
    bytes.push((high * 16 + low).to_byte())
  }
  Ok(@utf8.decode_lossy(Bytes::from_array(bytes[:])[:]))
}

///|
fn payload_checksum(payload : String) -> Int {
  let mut checksum = 17
  for byte in @utf8.encode(payload[:]) {
    checksum = (checksum * 131 + byte.to_int()) % CHECKSUM_MODULUS
  }
  checksum
}

///|
fn parse_positive_int(value : String, field : String) -> Result[Int, PageError] {
  if value.is_empty() {
    return Err(page_error(InvalidCursor, field, "cursor integer is empty"))
  }
  let mut result = 0
  for char in value.to_array() {
    if char < '0' || char > '9' {
      return Err(
        page_error(InvalidCursor, field, "cursor integer contains non-digit"),
      )
    }
    let digit = char.to_int() - '0'.to_int()
    if result > (@int.MAX_VALUE - digit) / 10 {
      return Err(page_error(InvalidCursor, field, "cursor integer overflows"))
    }
    result = result * 10 + digit
  }
  Ok(result)
}

///|
fn parse_int64_value(value : String) -> Result[Int64, PageError] {
  if value.is_empty() {
    return Err(page_error(InvalidCursor, "value", "integer value is empty"))
  }
  let chars = value.to_array()
  let negative = chars[0] == '-'
  let start = if negative { 1 } else { 0 }
  if start == chars.length() {
    return Err(
      page_error(InvalidCursor, "value", "integer value has no digits"),
    )
  }
  let mut result = 0L
  for index = start; index < chars.length(); index = index + 1 {
    let char = chars[index]
    if char < '0' || char > '9' {
      return Err(page_error(InvalidCursor, "value", "invalid integer digit"))
    }
    let digit = (char.to_int() - '0'.to_int()).to_int64()
    if negative {
      if result < (@int64.MIN_VALUE + digit) / 10L {
        return Err(
          page_error(InvalidCursor, "value", "integer value overflows"),
        )
      }
      result = result * 10L - digit
    } else {
      if result > (@int64.MAX_VALUE - digit) / 10L {
        return Err(
          page_error(InvalidCursor, "value", "integer value overflows"),
        )
      }
      result = result * 10L + digit
    }
  }
  Ok(result)
}

///|
fn encode_direction(direction : SortDirection) -> String {
  if direction is Ascending {
    "a"
  } else {
    "d"
  }
}

///|
fn decode_direction(value : String) -> Result[SortDirection, PageError] {
  match value {
    "a" => Ok(Ascending)
    "d" => Ok(Descending)
    _ => Err(page_error(InvalidCursor, "direction", "unknown sort direction"))
  }
}

///|
fn encode_nulls(nulls : NullPlacement) -> String {
  if nulls is NullsFirst {
    "f"
  } else {
    "l"
  }
}

///|
fn decode_nulls(value : String) -> Result[NullPlacement, PageError] {
  match value {
    "f" => Ok(NullsFirst)
    "l" => Ok(NullsLast)
    _ => Err(page_error(InvalidCursor, "nulls", "unknown null placement"))
  }
}

///|
fn encode_page_value(value : PageValue) -> String {
  match value {
    NullValue => "z"
    IntValue(number) => "i" + number.to_string()
    TextValue(text) => "t" + hex_encode(text)
    BoolValue(flag) => if flag { "b1" } else { "b0" }
  }
}

///|
fn decode_page_value(value : String) -> Result[PageValue, PageError] {
  if value.is_empty() {
    return Err(page_error(InvalidCursor, "value", "cursor value is empty"))
  }
  match value[:1].to_owned() {
    "z" =>
      if value.length() == 1 {
        Ok(NullValue)
      } else {
        Err(page_error(InvalidCursor, "value", "null value has payload"))
      }
    "i" =>
      match parse_int64_value(value[1:].to_owned()) {
        Ok(number) => Ok(IntValue(number))
        Err(error) => Err(error)
      }
    "t" =>
      match hex_decode(value[1:].to_owned(), "value") {
        Ok(text) => Ok(TextValue(text))
        Err(error) => Err(error)
      }
    "b" =>
      match value {
        "b0" => Ok(BoolValue(false))
        "b1" => Ok(BoolValue(true))
        _ => Err(page_error(InvalidCursor, "value", "invalid boolean value"))
      }
    _ => Err(page_error(InvalidCursor, "value", "unknown cursor value type"))
  }
}

///|
/// Encode a position as an ASCII and URL-safe opaque token. The checksum is
/// for corruption detection, not cryptographic authentication.
pub fn encode_cursor(
  position : PagePosition,
  snapshot? : String? = None,
) -> String {
  let segments : Array[String] = [
    CURSOR_VERSION.to_string(),
    match snapshot {
      Some(value) => hex_encode(value)
      None => "-"
    },
    position.parts.length().to_string(),
  ]
  for part in position.parts {
    segments.push(hex_encode(part.field))
    segments.push(encode_direction(part.direction))
    segments.push(encode_nulls(part.nulls))
    segments.push(encode_page_value(part.value))
  }
  segments.push(hex_encode(position.tie_breaker))
  let payload = segments.join(".")
  payload + "." + payload_checksum(payload).to_string()
}

///|
fn cursor_segments(token : String) -> Array[String] {
  token.split(".").map(item => item.to_owned()).to_array()
}

///|
/// Decode and validate cursor syntax, version, checksum, typed values, and
/// resource limits. Sort compatibility is checked when the cursor is applied.
pub fn decode_cursor(
  token : String,
  limits? : PageLimits = page_limits(),
) -> Result[PageCursor, PageError] {
  if token.to_array().length() > limits.max_cursor_chars {
    return Err(
      page_error(CursorTooLong, "cursor", "cursor exceeds configured limit"),
    )
  }
  let segments = cursor_segments(token)
  if segments.length() < 5 {
    return Err(page_error(InvalidCursor, "cursor", "cursor is incomplete"))
  }
  let part_count = match parse_positive_int(segments[2], "part_count") {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if part_count > limits.max_sort_fields {
    return Err(
      page_error(
        TooManySortFields,
        "cursor",
        "cursor contains too many sort fields",
      ),
    )
  }
  let expected_segments = 5 + part_count * 4
  if segments.length() != expected_segments {
    return Err(
      page_error(
        InvalidCursor,
        "cursor",
        "cursor segment count is inconsistent",
      ),
    )
  }
  let checksum_index = segments.length() - 1
  let payload = segments[:checksum_index].to_owned().join(".")
  let expected_checksum = match
    parse_positive_int(segments[checksum_index], "checksum") {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if payload_checksum(payload) != expected_checksum {
    return Err(
      page_error(
        CursorChecksumMismatch,
        "cursor",
        "cursor checksum does not match payload",
      ),
    )
  }
  let version = match parse_positive_int(segments[0], "version") {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if version != CURSOR_VERSION {
    return Err(
      page_error(
        UnsupportedCursorVersion,
        "version",
        "cursor version is not supported",
      ),
    )
  }
  let snapshot = if segments[1] == "-" {
    None
  } else {
    match hex_decode(segments[1], "snapshot") {
      Ok(value) => Some(value)
      Err(error) => return Err(error)
    }
  }
  let parts : Array[KeyPart] = []
  let mut index = 3
  for part_index = 0; part_index < part_count; part_index = part_index + 1 {
    let field = match hex_decode(segments[index], "field") {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    if field.is_empty() {
      return Err(page_error(InvalidCursor, "field", "cursor field is empty"))
    }
    let direction = match decode_direction(segments[index + 1]) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let nulls = match decode_nulls(segments[index + 2]) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let value = match decode_page_value(segments[index + 3]) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    parts.push({ field, value, direction, nulls })
    index = index + 4
  }
  let tie_breaker = match hex_decode(segments[index], "tie_breaker") {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if tie_breaker.is_empty() {
    return Err(
      page_error(InvalidCursor, "tie_breaker", "cursor tie-breaker is empty"),
    )
  }
  Ok({ version, position: { parts, tie_breaker }, snapshot })
}
