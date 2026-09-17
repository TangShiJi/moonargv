///|
/// Serializable logical state for a long-running page scan. Hosts persist the
/// scalar fields in their own format; no file or network IO is performed here.
pub struct TraversalCheckpoint {
  cursor : String?
  snapshot : String?
  pages : Int
  items : Int
  seen_ids : Array[String]
} derive(Debug, Eq)

///|
pub fn traversal_checkpoint(snapshot? : String? = None) -> TraversalCheckpoint {
  { cursor: None, snapshot, pages: 0, items: 0, seen_ids: [] }
}

///|
pub fn restore_checkpoint(
  cursor : String?,
  snapshot : String?,
  pages : Int,
  items : Int,
  seen_ids : Array[String],
) -> Result[TraversalCheckpoint, PageError] {
  if pages < 0 || items < 0 {
    return Err(
      page_error(
        InvalidOffset,
        "checkpoint",
        "checkpoint counters must be non-negative",
      ),
    )
  }
  for index = 0; index < seen_ids.length(); index = index + 1 {
    for previous = 0; previous < index; previous = previous + 1 {
      if seen_ids[index] == seen_ids[previous] {
        return Err(
          page_error(
            DuplicateTraversalItem,
            seen_ids[index],
            "checkpoint contains a duplicate record id",
          ),
        )
      }
    }
  }
  Ok({ cursor, snapshot, pages, items, seen_ids: seen_ids.copy() })
}

///|
pub fn TraversalCheckpoint::cursor(self : TraversalCheckpoint) -> String? {
  self.cursor
}

///|
pub fn TraversalCheckpoint::snapshot(self : TraversalCheckpoint) -> String? {
  self.snapshot
}

///|
pub fn TraversalCheckpoint::pages(self : TraversalCheckpoint) -> Int {
  self.pages
}

///|
pub fn TraversalCheckpoint::items(self : TraversalCheckpoint) -> Int {
  self.items
}

///|
pub fn TraversalCheckpoint::seen_ids(
  self : TraversalCheckpoint,
) -> Array[String] {
  self.seen_ids.copy()
}

///|
pub fn TraversalCheckpoint::next_request(
  self : TraversalCheckpoint,
  limit : Int,
  limits? : PageLimits = page_limits(),
) -> Result[PageRequest, PageError] {
  first_page(limit~, after=self.cursor, limits~)
}

///|
fn contains_id(ids : Array[String], id : String) -> Bool {
  for existing in ids {
    if existing == id {
      return true
    }
  }
  false
}

///|
/// Advance only when the page matches the checkpoint snapshot, has a fresh end
/// cursor, and contains no record already observed by this traversal.
pub fn advance_checkpoint(
  checkpoint : TraversalCheckpoint,
  page : PageResult,
) -> Result[TraversalCheckpoint, PageError] {
  if checkpoint.snapshot != page.info.snapshot {
    return Err(
      page_error(
        SnapshotMismatch,
        "snapshot",
        "page snapshot differs from traversal checkpoint",
      ),
    )
  }
  let next_cursor = page.info.end_cursor
  match (checkpoint.cursor, next_cursor) {
    (Some(previous), Some(next)) if previous == next =>
      return Err(
        page_error(
          RepeatedCursor,
          "cursor",
          "page did not advance beyond the previous checkpoint",
        ),
      )
    _ => ()
  }
  let seen_ids = checkpoint.seen_ids.copy()
  for edge in page.edges {
    let id = edge.row.id
    if contains_id(seen_ids, id) {
      return Err(
        page_error(
          DuplicateTraversalItem,
          id,
          "page repeats a record already processed by this traversal",
        ),
      )
    }
    seen_ids.push(id)
  }
  Ok({
    cursor: next_cursor,
    snapshot: checkpoint.snapshot,
    pages: checkpoint.pages + 1,
    items: checkpoint.items + page.edges.length(),
    seen_ids,
  })
}

///|
pub fn traversal_complete(page : PageResult) -> Bool {
  !page.info.has_next_page
}
