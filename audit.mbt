///|
pub struct OrderViolation {
  previous_id : String
  current_id : String
} derive(Debug, Eq)

///|
/// Evidence produced from a completed or partial page traversal.
pub struct PaginationAudit {
  observed_count : Int
  unique_count : Int
  duplicate_ids : Array[String]
  missing_ids : Array[String]
  unexpected_ids : Array[String]
  order_violations : Array[OrderViolation]
} derive(Debug, Eq)

///|
pub fn OrderViolation::previous_id(self : OrderViolation) -> String {
  self.previous_id
}

///|
pub fn OrderViolation::current_id(self : OrderViolation) -> String {
  self.current_id
}

///|
pub fn PaginationAudit::observed_count(self : PaginationAudit) -> Int {
  self.observed_count
}

///|
pub fn PaginationAudit::unique_count(self : PaginationAudit) -> Int {
  self.unique_count
}

///|
pub fn PaginationAudit::duplicate_ids(self : PaginationAudit) -> Array[String] {
  self.duplicate_ids.copy()
}

///|
pub fn PaginationAudit::missing_ids(self : PaginationAudit) -> Array[String] {
  self.missing_ids.copy()
}

///|
pub fn PaginationAudit::unexpected_ids(self : PaginationAudit) -> Array[String] {
  self.unexpected_ids.copy()
}

///|
pub fn PaginationAudit::order_violations(
  self : PaginationAudit,
) -> Array[OrderViolation] {
  self.order_violations.copy()
}

///|
pub fn PaginationAudit::is_clean(self : PaginationAudit) -> Bool {
  self.duplicate_ids.length() == 0 &&
  self.missing_ids.length() == 0 &&
  self.unexpected_ids.length() == 0 &&
  self.order_violations.length() == 0
}

///|
fn string_in(items : Array[String], target : String) -> Bool {
  for item in items {
    if item == target {
      return true
    }
  }
  false
}

///|
fn push_unique_string(items : Array[String], value : String) -> Unit {
  if !string_in(items, value) {
    items.push(value)
  }
}

///|
/// Audit a sequence collected from multiple pages against the records expected
/// at traversal start. This makes mutation-induced offset anomalies observable
/// in tests and production export verification.
pub fn audit_traversal(
  observed : Array[PageRow],
  expected : Array[PageRow],
  sort : Array[SortField],
  limits? : PageLimits = page_limits(),
) -> Result[PaginationAudit, PageError] {
  let expected_sorted = match sort_rows(expected, sort, limits~) {
    Ok(rows) => rows
    Err(error) => return Err(error)
  }
  let expected_ids = expected_sorted.map(row => row.id)
  let observed_ids : Array[String] = []
  let duplicate_ids : Array[String] = []
  let unexpected_ids : Array[String] = []
  let order_violations : Array[OrderViolation] = []
  for index = 0; index < observed.length(); index = index + 1 {
    let row = observed[index]
    if string_in(observed_ids, row.id) {
      push_unique_string(duplicate_ids, row.id)
    } else {
      observed_ids.push(row.id)
    }
    if !string_in(expected_ids, row.id) {
      push_unique_string(unexpected_ids, row.id)
    }
    if index > 0 {
      let compared = match compare_rows(observed[index - 1], row, sort) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      if compared >= 0 {
        order_violations.push({
          previous_id: observed[index - 1].id,
          current_id: row.id,
        })
      }
    }
  }
  let missing_ids : Array[String] = []
  for id in expected_ids {
    if !string_in(observed_ids, id) {
      missing_ids.push(id)
    }
  }
  Ok({
    observed_count: observed.length(),
    unique_count: observed_ids.length(),
    duplicate_ids,
    missing_ids,
    unexpected_ids,
    order_violations,
  })
}

///|
pub fn format_audit(audit : PaginationAudit) -> String {
  let status = if audit.is_clean() { "PASS" } else { "FAIL" }
  [
    "status=" + status,
    "observed=" + audit.observed_count.to_string(),
    "unique=" + audit.unique_count.to_string(),
    "duplicates=" + audit.duplicate_ids.join(","),
    "missing=" + audit.missing_ids.join(","),
    "unexpected=" + audit.unexpected_ids.join(","),
    "order_violations=" + audit.order_violations.length().to_string(),
  ].join(" ")
}
