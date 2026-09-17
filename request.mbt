///|
/// Validated page request. `cursor` is interpreted as an exclusive boundary.
pub struct PageRequest {
  mode : PageMode
  limit : Int
  cursor : String?
} derive(Debug, Eq)

///|
/// Limits applied before decoding cursors or sorting untrusted input.
pub struct PageLimits {
  default_size : Int
  max_size : Int
  max_sort_fields : Int
  max_cursor_chars : Int
  max_rows : Int
} derive(Debug, Eq)

///|
pub fn page_limits(
  default_size? : Int = 20,
  max_size? : Int = 100,
  max_sort_fields? : Int = 8,
  max_cursor_chars? : Int = 4096,
  max_rows? : Int = 100000,
) -> PageLimits {
  let safe_max = if max_size < 1 { 1 } else { max_size }
  {
    default_size: if default_size < 1 {
      1
    } else if default_size > safe_max {
      safe_max
    } else {
      default_size
    },
    max_size: safe_max,
    max_sort_fields: if max_sort_fields < 1 {
      1
    } else {
      max_sort_fields
    },
    max_cursor_chars: if max_cursor_chars < 32 {
      32
    } else {
      max_cursor_chars
    },
    max_rows: if max_rows < 1 {
      1
    } else {
      max_rows
    },
  }
}

///|
pub fn first_page(
  limit? : Int = 0,
  after? : String? = None,
  limits? : PageLimits = page_limits(),
) -> Result[PageRequest, PageError] {
  make_page_request(ForwardPage, limit, after, limits)
}

///|
pub fn last_page(
  limit? : Int = 0,
  before? : String? = None,
  limits? : PageLimits = page_limits(),
) -> Result[PageRequest, PageError] {
  make_page_request(BackwardPage, limit, before, limits)
}

///|
fn make_page_request(
  mode : PageMode,
  requested : Int,
  cursor : String?,
  limits : PageLimits,
) -> Result[PageRequest, PageError] {
  let limit = if requested == 0 { limits.default_size } else { requested }
  if limit < 1 || limit > limits.max_size {
    return Err(
      page_error(
        InvalidPageSize,
        "limit",
        "page size must be positive and not exceed configured maximum",
      ),
    )
  }
  match cursor {
    Some(value) =>
      if value.to_array().length() > limits.max_cursor_chars {
        return Err(
          page_error(
            CursorTooLong,
            "cursor",
            "cursor exceeds configured character limit",
          ),
        )
      }
    None => ()
  }
  Ok({ mode, limit, cursor })
}

///|
pub fn PageRequest::mode(self : PageRequest) -> PageMode {
  self.mode
}

///|
pub fn PageRequest::limit(self : PageRequest) -> Int {
  self.limit
}

///|
pub fn PageRequest::cursor(self : PageRequest) -> String? {
  self.cursor
}

///|
pub fn PageLimits::default_size(self : PageLimits) -> Int {
  self.default_size
}

///|
pub fn PageLimits::max_size(self : PageLimits) -> Int {
  self.max_size
}

///|
pub fn PageLimits::max_sort_fields(self : PageLimits) -> Int {
  self.max_sort_fields
}

///|
pub fn PageLimits::max_cursor_chars(self : PageLimits) -> Int {
  self.max_cursor_chars
}

///|
pub fn PageLimits::max_rows(self : PageLimits) -> Int {
  self.max_rows
}
