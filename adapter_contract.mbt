///|
/// Result of comparing a database or ORM adapter with the reference seek
/// semantics. Keeping the expected and actual ids makes CI failures actionable.
pub struct SeekConformance {
  expected_ids : Array[String]
  actual_ids : Array[String]
} derive(Debug, Eq)

///|
pub fn SeekConformance::expected_ids(self : SeekConformance) -> Array[String] {
  self.expected_ids.copy()
}

///|
pub fn SeekConformance::actual_ids(self : SeekConformance) -> Array[String] {
  self.actual_ids.copy()
}

///|
pub fn SeekConformance::matches(self : SeekConformance) -> Bool {
  self.expected_ids == self.actual_ids
}

///|
/// Return the canonical ids that a database seek query must return. This is a
/// deliberately small reference oracle for adapter tests; production adapters
/// still execute their query inside the database.
pub fn expected_seek_ids(
  input : Array[PageRow],
  boundary : PagePosition,
  sort : Array[SortField],
  mode : PageMode,
  limit : Int,
  limits? : PageLimits = page_limits(),
) -> Result[Array[String], PageError] {
  if limit < 1 || limit > limits.max_size {
    return Err(
      page_error(
        InvalidPageSize,
        "limit",
        "adapter verification limit must be within configured bounds",
      ),
    )
  }
  let rows = match sort_rows(input, sort, limits~) {
    Ok(rows) => rows
    Err(error) => return Err(error)
  }
  let eligible : Array[PageRow] = []
  for row in rows {
    let compared = match compare_row_to_position(row, boundary, sort) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let is_eligible = match mode {
      ForwardPage => compared > 0
      BackwardPage => compared < 0
    }
    if is_eligible {
      eligible.push(row)
    }
  }
  let start = match mode {
    ForwardPage => 0
    BackwardPage =>
      if eligible.length() > limit {
        eligible.length() - limit
      } else {
        0
      }
  }
  let end = if start + limit < eligible.length() {
    start + limit
  } else {
    eligible.length()
  }
  let ids : Array[String] = []
  for index = start; index < end; index = index + 1 {
    ids.push(eligible[index].id())
  }
  Ok(ids)
}

///|
/// Compare ids returned by a real adapter with the canonical reference page.
pub fn verify_seek_ids(
  actual_ids : Array[String],
  input : Array[PageRow],
  boundary : PagePosition,
  sort : Array[SortField],
  mode : PageMode,
  limit : Int,
  limits? : PageLimits = page_limits(),
) -> Result[SeekConformance, PageError] {
  let expected_ids = match
    expected_seek_ids(input, boundary, sort, mode, limit, limits~) {
    Ok(ids) => ids
    Err(error) => return Err(error)
  }
  Ok({ expected_ids, actual_ids: actual_ids.copy() })
}
