///|
pub struct OffsetPageInfo {
  offset : Int
  limit : Int
  total : Int
  has_previous_page : Bool
  has_next_page : Bool
} derive(Debug, Eq)

///|
pub struct OffsetPage {
  rows : Array[PageRow]
  info : OffsetPageInfo
} derive(Debug, Eq)

///|
pub fn OffsetPage::rows(self : OffsetPage) -> Array[PageRow] {
  self.rows.copy()
}

///|
pub fn OffsetPage::info(self : OffsetPage) -> OffsetPageInfo {
  self.info
}

///|
pub fn OffsetPageInfo::offset(self : OffsetPageInfo) -> Int {
  self.offset
}

///|
pub fn OffsetPageInfo::limit(self : OffsetPageInfo) -> Int {
  self.limit
}

///|
pub fn OffsetPageInfo::total(self : OffsetPageInfo) -> Int {
  self.total
}

///|
pub fn OffsetPageInfo::has_previous_page(self : OffsetPageInfo) -> Bool {
  self.has_previous_page
}

///|
pub fn OffsetPageInfo::has_next_page(self : OffsetPageInfo) -> Bool {
  self.has_next_page
}

///|
/// Compatibility mode for APIs that expose numeric pages. It shares sort and
/// limit validation but cannot guarantee mutation stability like keyset mode.
pub fn paginate_offset(
  input : Array[PageRow],
  sort : Array[SortField],
  offset : Int,
  limit : Int,
  limits? : PageLimits = page_limits(),
) -> Result[OffsetPage, PageError] {
  if offset < 0 {
    return Err(
      page_error(InvalidOffset, "offset", "offset must not be negative"),
    )
  }
  if limit < 1 || limit > limits.max_size {
    return Err(
      page_error(
        InvalidPageSize,
        "limit",
        "offset page size exceeds configured bounds",
      ),
    )
  }
  let sorted = match sort_rows(input, sort, limits~) {
    Ok(rows) => rows
    Err(error) => return Err(error)
  }
  let start = if offset > sorted.length() { sorted.length() } else { offset }
  let end = if start + limit > sorted.length() {
    sorted.length()
  } else {
    start + limit
  }
  Ok({
    rows: sorted[start:end].to_owned(),
    info: {
      offset: start,
      limit,
      total: sorted.length(),
      has_previous_page: start > 0,
      has_next_page: end < sorted.length(),
    },
  })
}
