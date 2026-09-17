///|
fn validate_cursor_snapshot(
  cursor : PageCursor,
  current_snapshot : String?,
) -> Result[Unit, PageError] {
  match (cursor.snapshot, current_snapshot) {
    (None, _) => Ok(())
    (Some(expected), Some(actual)) =>
      if expected == actual {
        Ok(())
      } else {
        Err(
          page_error(
            SnapshotMismatch,
            "snapshot",
            "cursor snapshot does not match current dataset revision",
          ),
        )
      }
    (Some(_), None) =>
      Err(
        page_error(
          SnapshotMismatch,
          "snapshot",
          "cursor requires a snapshot but current revision was not supplied",
        ),
      )
  }
}

///|
fn decode_request_cursor(
  request : PageRequest,
  snapshot : String?,
  limits : PageLimits,
) -> Result[PageCursor?, PageError] {
  match request.cursor {
    None => Ok(None)
    Some(token) =>
      match decode_cursor(token, limits~) {
        Err(error) => Err(error)
        Ok(cursor) =>
          match validate_cursor_snapshot(cursor, snapshot) {
            Err(error) => Err(error)
            Ok(_) => Ok(Some(cursor))
          }
      }
  }
}

///|
fn row_is_eligible(
  row : PageRow,
  cursor : PageCursor?,
  sort : Array[SortField],
  mode : PageMode,
) -> Result[Bool, PageError] {
  match cursor {
    None => Ok(true)
    Some(value) => {
      let compared = match compare_row_to_position(row, value.position, sort) {
        Ok(result) => result
        Err(error) => return Err(error)
      }
      match mode {
        ForwardPage => Ok(compared > 0)
        BackwardPage => Ok(compared < 0)
      }
    }
  }
}

///|
fn page_slice(
  eligible : Array[PageRow],
  request : PageRequest,
) -> Array[PageRow] {
  match request.mode {
    ForwardPage => {
      let end = if eligible.length() < request.limit {
        eligible.length()
      } else {
        request.limit
      }
      eligible[:end].to_owned()
    }
    BackwardPage => {
      let start = if eligible.length() > request.limit {
        eligible.length() - request.limit
      } else {
        0
      }
      eligible[start:].to_owned()
    }
  }
}

///|
fn page_has_before(
  sorted : Array[PageRow],
  first : PageRow,
  sort : Array[SortField],
) -> Result[Bool, PageError] {
  for row in sorted {
    let compared = match compare_rows(row, first, sort) {
      Ok(result) => result
      Err(error) => return Err(error)
    }
    if compared < 0 {
      return Ok(true)
    }
  }
  Ok(false)
}

///|
fn page_has_after(
  sorted : Array[PageRow],
  last : PageRow,
  sort : Array[SortField],
) -> Result[Bool, PageError] {
  for row in sorted {
    let compared = match compare_rows(row, last, sort) {
      Ok(result) => result
      Err(error) => return Err(error)
    }
    if compared > 0 {
      return Ok(true)
    }
  }
  Ok(false)
}

///|
/// Reference keyset paginator. Production database adapters can execute a seek
/// plan instead of materializing rows while retaining identical cursor rules.
pub fn paginate(
  input : Array[PageRow],
  sort : Array[SortField],
  request : PageRequest,
  snapshot? : String? = None,
  limits? : PageLimits = page_limits(),
) -> Result[PageResult, PageError] {
  let cursor = match decode_request_cursor(request, snapshot, limits) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let sorted = match sort_rows(input, sort, limits~) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let eligible : Array[PageRow] = []
  for row in sorted {
    match row_is_eligible(row, cursor, sort, request.mode) {
      Ok(true) => eligible.push(row)
      Ok(false) => ()
      Err(error) => return Err(error)
    }
  }
  let selected = page_slice(eligible, request)
  let edges : Array[PageEdge] = []
  for row in selected {
    let position = match position_for(row, sort) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    edges.push({ row, cursor: encode_cursor(position, snapshot~) })
  }
  if edges.length() == 0 {
    return Ok({
      edges,
      info: {
        has_previous_page: false,
        has_next_page: false,
        start_cursor: None,
        end_cursor: None,
        snapshot,
      },
    })
  }
  let has_previous_page = match page_has_before(sorted, edges[0].row, sort) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let has_next_page = match
    page_has_after(sorted, edges[edges.length() - 1].row, sort) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok({
    edges,
    info: {
      has_previous_page,
      has_next_page,
      start_cursor: Some(edges[0].cursor),
      end_cursor: Some(edges[edges.length() - 1].cursor),
      snapshot,
    },
  })
}

///|
pub fn page_rows(page : PageResult) -> Array[PageRow] {
  page.edges.map(edge => edge.row)
}
