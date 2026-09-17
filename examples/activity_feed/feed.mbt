///|
pub fn activity_rows() -> Array[@moonpageflow.PageRow] {
  [
    @moonpageflow.page_row("event-101", [
      ("created_at", @moonpageflow.int_value(300L)),
      ("kind", @moonpageflow.text_value("deploy")),
    ]).unwrap(),
    @moonpageflow.page_row("event-100", [
      ("created_at", @moonpageflow.int_value(300L)),
      ("kind", @moonpageflow.text_value("build")),
    ]).unwrap(),
    @moonpageflow.page_row("event-099", [
      ("created_at", @moonpageflow.int_value(200L)),
      ("kind", @moonpageflow.text_value("test")),
    ]).unwrap(),
    @moonpageflow.page_row("event-098", [
      ("created_at", @moonpageflow.int_value(100L)),
      ("kind", @moonpageflow.text_value("commit")),
    ]).unwrap(),
  ]
}

///|
pub fn activity_sort() -> Array[@moonpageflow.SortField] {
  [@moonpageflow.sort_field("created_at", direction=@moonpageflow.Descending)]
}

///|
pub fn first_activity_page() -> @moonpageflow.PageResult {
  @moonpageflow.paginate(
    activity_rows(),
    activity_sort(),
    @moonpageflow.first_page(limit=2).unwrap(),
    snapshot=Some("activity-revision-42"),
  ).unwrap()
}

///|
pub fn next_activity_page(after : String) -> @moonpageflow.PageResult {
  @moonpageflow.paginate(
    activity_rows(),
    activity_sort(),
    @moonpageflow.first_page(limit=2, after=Some(after)).unwrap(),
    snapshot=Some("activity-revision-42"),
  ).unwrap()
}
