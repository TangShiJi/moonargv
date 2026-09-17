///|
/// Values that may participate in a portable ordering key.
pub(all) enum PageValue {
  NullValue
  IntValue(Int64)
  TextValue(String)
  BoolValue(Bool)
} derive(Debug, Eq)

///|
/// Sort direction for one key component.
pub(all) enum SortDirection {
  Ascending
  Descending
} derive(Debug, Eq)

///|
/// Explicit null placement avoids database-dependent default ordering.
pub(all) enum NullPlacement {
  NullsFirst
  NullsLast
} derive(Debug, Eq)

///|
/// Direction in which a page is requested from a cursor boundary.
pub(all) enum PageMode {
  ForwardPage
  BackwardPage
} derive(Debug, Eq)

///|
/// One named sort key. Record id is always appended as the final unique
/// tie-breaker and therefore must not appear here.
pub struct SortField {
  name : String
  direction : SortDirection
  nulls : NullPlacement
} derive(Debug, Eq)

///|
/// Format-neutral record used by the reference paginator. Database adapters
/// may use the same ordering and cursor APIs without materializing all rows.
pub struct PageRow {
  id : String
  values : Array[(String, PageValue)]
} derive(Debug, Eq)

///|
/// A typed key component captured inside a cursor.
pub struct KeyPart {
  field : String
  value : PageValue
  direction : SortDirection
  nulls : NullPlacement
} derive(Debug, Eq)

///|
/// Stable position consists of declared sort values and a unique record id.
pub struct PagePosition {
  parts : Array[KeyPart]
  tie_breaker : String
} derive(Debug, Eq)

///|
/// Decoded cursor data. Snapshot is supplied by the host, for example a
/// database revision, event offset, or content hash.
pub struct PageCursor {
  version : Int
  position : PagePosition
  snapshot : String?
} derive(Debug, Eq)

///|
/// One result edge with a cursor that resumes after or before this row.
pub struct PageEdge {
  row : PageRow
  cursor : String
} derive(Debug, Eq)

///|
/// Navigation metadata follows the common connection model while remaining
/// independent of GraphQL or any web framework.
pub struct PageInfo {
  has_previous_page : Bool
  has_next_page : Bool
  start_cursor : String?
  end_cursor : String?
  snapshot : String?
} derive(Debug, Eq)

///|
/// Complete page returned by the in-memory reference engine.
pub struct PageResult {
  edges : Array[PageEdge]
  info : PageInfo
} derive(Debug, Eq)

///|
pub(all) enum PageErrorKind {
  EmptyRowId
  DuplicateRowId
  EmptySortField
  DuplicateSortField
  MissingSortValue
  InvalidPageSize
  TooManySortFields
  TooManyRows
  InvalidCursor
  UnsupportedCursorVersion
  CursorChecksumMismatch
  CursorSortMismatch
  CursorTooLong
  SnapshotMismatch
  RepeatedCursor
  DuplicateTraversalItem
  InvalidOffset
} derive(Debug, Eq)

///|
/// Structured failure suitable for API error mapping and test assertions.
pub struct PageError {
  kind : PageErrorKind
  field : String
  message : String
} derive(Debug, Eq)

///|
pub fn int_value(value : Int64) -> PageValue {
  IntValue(value)
}

///|
pub fn text_value(value : String) -> PageValue {
  TextValue(value)
}

///|
pub fn bool_value(value : Bool) -> PageValue {
  BoolValue(value)
}

///|
pub fn null_value() -> PageValue {
  NullValue
}

///|
pub fn sort_field(
  name : String,
  direction? : SortDirection = Ascending,
  nulls? : NullPlacement = NullsLast,
) -> SortField {
  { name, direction, nulls }
}

///|
pub fn page_row(
  id : String,
  values : Array[(String, PageValue)],
) -> Result[PageRow, PageError] {
  if id.is_empty() {
    return Err(page_error(EmptyRowId, "id", "row id must not be empty"))
  }
  for index = 0; index < values.length(); index = index + 1 {
    if values[index].0.is_empty() {
      return Err(
        page_error(EmptySortField, "values", "row field name must not be empty"),
      )
    }
    for previous = 0; previous < index; previous = previous + 1 {
      if values[previous].0 == values[index].0 {
        return Err(
          page_error(
            DuplicateSortField,
            values[index].0,
            "row contains a duplicate field name",
          ),
        )
      }
    }
  }
  Ok({ id, values })
}

///|
pub fn PageRow::id(self : PageRow) -> String {
  self.id
}

///|
pub fn PageRow::values(self : PageRow) -> Array[(String, PageValue)] {
  self.values.copy()
}

///|
pub fn PageRow::value(self : PageRow, name : String) -> PageValue? {
  for item in self.values {
    if item.0 == name {
      return Some(item.1)
    }
  }
  None
}

///|
pub fn SortField::name(self : SortField) -> String {
  self.name
}

///|
pub fn SortField::direction(self : SortField) -> SortDirection {
  self.direction
}

///|
pub fn SortField::nulls(self : SortField) -> NullPlacement {
  self.nulls
}

///|
pub fn KeyPart::field(self : KeyPart) -> String {
  self.field
}

///|
pub fn KeyPart::value(self : KeyPart) -> PageValue {
  self.value
}

///|
pub fn KeyPart::direction(self : KeyPart) -> SortDirection {
  self.direction
}

///|
pub fn KeyPart::nulls(self : KeyPart) -> NullPlacement {
  self.nulls
}

///|
pub fn PagePosition::parts(self : PagePosition) -> Array[KeyPart] {
  self.parts.copy()
}

///|
pub fn PagePosition::tie_breaker(self : PagePosition) -> String {
  self.tie_breaker
}

///|
pub fn PageCursor::version(self : PageCursor) -> Int {
  self.version
}

///|
pub fn PageCursor::position(self : PageCursor) -> PagePosition {
  self.position
}

///|
pub fn PageCursor::snapshot(self : PageCursor) -> String? {
  self.snapshot
}

///|
pub fn PageEdge::row(self : PageEdge) -> PageRow {
  self.row
}

///|
pub fn PageEdge::cursor(self : PageEdge) -> String {
  self.cursor
}

///|
pub fn PageInfo::has_previous_page(self : PageInfo) -> Bool {
  self.has_previous_page
}

///|
pub fn PageInfo::has_next_page(self : PageInfo) -> Bool {
  self.has_next_page
}

///|
pub fn PageInfo::start_cursor(self : PageInfo) -> String? {
  self.start_cursor
}

///|
pub fn PageInfo::end_cursor(self : PageInfo) -> String? {
  self.end_cursor
}

///|
pub fn PageInfo::snapshot(self : PageInfo) -> String? {
  self.snapshot
}

///|
pub fn PageResult::edges(self : PageResult) -> Array[PageEdge] {
  self.edges.copy()
}

///|
pub fn PageResult::info(self : PageResult) -> PageInfo {
  self.info
}

///|
pub fn PageError::kind(self : PageError) -> PageErrorKind {
  self.kind
}

///|
pub fn PageError::field(self : PageError) -> String {
  self.field
}

///|
pub fn PageError::message(self : PageError) -> String {
  self.message
}

///|
fn page_error(
  kind : PageErrorKind,
  field : String,
  message : String,
) -> PageError {
  { kind, field, message }
}
