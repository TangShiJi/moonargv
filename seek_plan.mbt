///|
/// Abstract comparison emitted for a database or search-index adapter.
pub(all) enum SeekComparison {
  GreaterThan
  LessThan
} derive(Debug, Eq)

///|
pub struct EqualityTerm {
  field : String
  value : PageValue
  nulls : NullPlacement
} derive(Debug, Eq)

///|
/// One branch of a lexicographic keyset predicate. Branches are OR-ed; terms
/// in `equal_prefix` are AND-ed before the branch comparison.
pub struct SeekBranch {
  equal_prefix : Array[EqualityTerm]
  field : String
  value : PageValue
  comparison : SeekComparison
  nulls : NullPlacement
} derive(Debug, Eq)

///|
pub struct SeekPlan {
  branches : Array[SeekBranch]
  reverse_query_order : Bool
} derive(Debug, Eq)

///|
pub fn EqualityTerm::field(self : EqualityTerm) -> String {
  self.field
}

///|
pub fn EqualityTerm::value(self : EqualityTerm) -> PageValue {
  self.value
}

///|
pub fn EqualityTerm::nulls(self : EqualityTerm) -> NullPlacement {
  self.nulls
}

///|
pub fn SeekBranch::equal_prefix(self : SeekBranch) -> Array[EqualityTerm] {
  self.equal_prefix.copy()
}

///|
pub fn SeekBranch::field(self : SeekBranch) -> String {
  self.field
}

///|
pub fn SeekBranch::value(self : SeekBranch) -> PageValue {
  self.value
}

///|
pub fn SeekBranch::comparison(self : SeekBranch) -> SeekComparison {
  self.comparison
}

///|
pub fn SeekBranch::nulls(self : SeekBranch) -> NullPlacement {
  self.nulls
}

///|
pub fn SeekPlan::branches(self : SeekPlan) -> Array[SeekBranch] {
  self.branches.copy()
}

///|
pub fn SeekPlan::reverse_query_order(self : SeekPlan) -> Bool {
  self.reverse_query_order
}

///|
fn seek_comparison(
  direction : SortDirection,
  mode : PageMode,
) -> SeekComparison {
  match (direction, mode) {
    (Ascending, ForwardPage) | (Descending, BackwardPage) => GreaterThan
    (Descending, ForwardPage) | (Ascending, BackwardPage) => LessThan
  }
}

///|
/// Build `(k1 op v1) OR (k1=v1 AND k2 op v2) ...` without generating SQL.
/// The host maps fields and operators to its typed query API, avoiding string
/// interpolation and keeping this package storage-engine neutral.
pub fn build_seek_plan(
  position : PagePosition,
  sort : Array[SortField],
  mode : PageMode,
) -> Result[SeekPlan, PageError] {
  if !cursor_matches_sort(position, sort) {
    return Err(
      page_error(
        CursorSortMismatch,
        "cursor",
        "cursor ordering does not match seek plan sort",
      ),
    )
  }
  let branches : Array[SeekBranch] = []
  let prefix : Array[EqualityTerm] = []
  for index = 0; index < sort.length(); index = index + 1 {
    let field = sort[index]
    let part = position.parts[index]
    branches.push({
      equal_prefix: prefix.copy(),
      field: field.name,
      value: part.value,
      comparison: seek_comparison(field.direction, mode),
      nulls: field.nulls,
    })
    prefix.push({ field: field.name, value: part.value, nulls: field.nulls })
  }
  branches.push({
    equal_prefix: prefix,
    field: "id",
    value: TextValue(position.tie_breaker),
    comparison: seek_comparison(Ascending, mode),
    nulls: NullsLast,
  })
  Ok({ branches, reverse_query_order: mode is BackwardPage })
}
