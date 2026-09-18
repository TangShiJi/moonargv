///|
fn compare_text(left : String, right : String) -> Int {
  let left_chars = left.to_array()
  let right_chars = right.to_array()
  let common = if left_chars.length() < right_chars.length() {
    left_chars.length()
  } else {
    right_chars.length()
  }
  for index = 0; index < common; index = index + 1 {
    if left_chars[index] < right_chars[index] {
      return -1
    }
    if left_chars[index] > right_chars[index] {
      return 1
    }
  }
  if left_chars.length() < right_chars.length() {
    -1
  } else if left_chars.length() > right_chars.length() {
    1
  } else {
    0
  }
}

///|
fn compare_bool(left : Bool, right : Bool) -> Int {
  if left == right {
    0
  } else if left {
    1
  } else {
    -1
  }
}

///|
fn compare_non_null_values(left : PageValue, right : PageValue) -> Int {
  match (left, right) {
    (IntValue(a), IntValue(b)) => if a < b { -1 } else if a > b { 1 } else { 0 }
    (TextValue(a), TextValue(b)) => compare_text(a, b)
    (BoolValue(a), BoolValue(b)) => compare_bool(a, b)
    (IntValue(_), _) => -1
    (TextValue(_), BoolValue(_)) => -1
    (TextValue(_), IntValue(_)) => 1
    (BoolValue(_), _) => 1
    (NullValue, NullValue) => 0
    (NullValue, _) => -1
    (_, NullValue) => 1
  }
}

///|
pub fn compare_page_values(
  left : PageValue,
  right : PageValue,
  direction : SortDirection,
  nulls : NullPlacement,
) -> Int {
  match (left, right) {
    (NullValue, NullValue) => return 0
    (NullValue, _) => return if nulls is NullsFirst { -1 } else { 1 }
    (_, NullValue) => return if nulls is NullsFirst { 1 } else { -1 }
    _ => ()
  }
  let result = compare_non_null_values(left, right)
  if direction is Descending {
    -result
  } else {
    result
  }
}

///|
pub fn validate_sort(
  sort : Array[SortField],
  limits? : PageLimits = page_limits(),
) -> Result[Unit, PageError] {
  if sort.length() > limits.max_sort_fields {
    return Err(
      page_error(
        TooManySortFields,
        "sort",
        "sort field count exceeds configured maximum",
      ),
    )
  }
  for index = 0; index < sort.length(); index = index + 1 {
    let field = sort[index]
    if field.name.is_empty() || field.name == "id" {
      return Err(
        page_error(
          EmptySortField,
          field.name,
          "sort field must be non-empty and must not replace the id tie-breaker",
        ),
      )
    }
    for previous = 0; previous < index; previous = previous + 1 {
      if sort[previous].name == field.name {
        return Err(
          page_error(
            DuplicateSortField,
            field.name,
            "sort contains a duplicate field",
          ),
        )
      }
    }
  }
  Ok(())
}

///|
fn required_value(
  row : PageRow,
  field : SortField,
) -> Result[PageValue, PageError] {
  match row.value(field.name) {
    Some(value) => Ok(value)
    None =>
      Err(
        page_error(
          MissingSortValue,
          field.name,
          "row does not contain a declared sort field",
        ),
      )
  }
}

///|
pub fn position_for(
  row : PageRow,
  sort : Array[SortField],
) -> Result[PagePosition, PageError] {
  let parts : Array[KeyPart] = []
  for field in sort {
    let value = match required_value(row, field) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    parts.push({
      field: field.name,
      value,
      direction: field.direction,
      nulls: field.nulls,
    })
  }
  Ok({ parts, tie_breaker: row.id })
}

///|
pub fn compare_rows(
  left : PageRow,
  right : PageRow,
  sort : Array[SortField],
) -> Result[Int, PageError] {
  for field in sort {
    let left_value = match required_value(left, field) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let right_value = match required_value(right, field) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let compared = compare_page_values(
      left_value,
      right_value,
      field.direction,
      field.nulls,
    )
    if compared != 0 {
      return Ok(compared)
    }
  }
  Ok(compare_text(left.id, right.id))
}

///|
fn cursor_matches_sort(
  position : PagePosition,
  sort : Array[SortField],
) -> Bool {
  if position.parts.length() != sort.length() {
    return false
  }
  for index = 0; index < sort.length(); index = index + 1 {
    let part = position.parts[index]
    let field = sort[index]
    if part.field != field.name ||
      part.direction != field.direction ||
      part.nulls != field.nulls {
      return false
    }
  }
  true
}

///|
pub fn compare_row_to_position(
  row : PageRow,
  position : PagePosition,
  sort : Array[SortField],
) -> Result[Int, PageError] {
  if !cursor_matches_sort(position, sort) {
    return Err(
      page_error(
        CursorSortMismatch,
        "cursor",
        "cursor ordering does not match the requested sort",
      ),
    )
  }
  for index = 0; index < sort.length(); index = index + 1 {
    let field = sort[index]
    let value = match required_value(row, field) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let compared = compare_page_values(
      value,
      position.parts[index].value,
      field.direction,
      field.nulls,
    )
    if compared != 0 {
      return Ok(compared)
    }
  }
  Ok(compare_text(row.id, position.tie_breaker))
}

///|
fn validate_unique_rows(rows : Array[PageRow]) -> Result[Unit, PageError] {
  for index = 0; index < rows.length(); index = index + 1 {
    for previous = 0; previous < index; previous = previous + 1 {
      if rows[previous].id == rows[index].id {
        return Err(
          page_error(
            DuplicateRowId,
            rows[index].id,
            "row ids must be unique for stable pagination",
          ),
        )
      }
    }
  }
  Ok(())
}

///|
/// Stable bottom-up merge sort keeps the reference engine deterministic while
/// avoiding quadratic behavior on larger in-memory result sets. Database
/// integrations use the same comparison contract through seek plans.
pub fn sort_rows(
  input : Array[PageRow],
  sort : Array[SortField],
  limits? : PageLimits = page_limits(),
) -> Result[Array[PageRow], PageError] {
  match validate_sort(sort, limits~) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  if input.length() > limits.max_rows {
    return Err(
      page_error(TooManyRows, "rows", "row count exceeds configured maximum"),
    )
  }
  match validate_unique_rows(input) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  for row in input {
    match position_for(row, sort) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
  }
  let mut source = input.copy()
  let mut target = input.copy()
  let mut width = 1
  while width < source.length() {
    let mut left = 0
    while left < source.length() {
      let middle = if left + width < source.length() {
        left + width
      } else {
        source.length()
      }
      let right = if left + width * 2 < source.length() {
        left + width * 2
      } else {
        source.length()
      }
      let mut first = left
      let mut second = middle
      for output = left; output < right; output = output + 1 {
        if first >= middle {
          target[output] = source[second]
          second = second + 1
        } else if second >= right {
          target[output] = source[first]
          first = first + 1
        } else {
          let compared = match
            compare_rows(source[first], source[second], sort) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          if compared <= 0 {
            target[output] = source[first]
            first = first + 1
          } else {
            target[output] = source[second]
            second = second + 1
          }
        }
      }
      left = left + width * 2
    }
    let previous = source
    source = target
    target = previous
    width = width * 2
  }
  Ok(source)
}
