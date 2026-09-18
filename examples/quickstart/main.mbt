///|
fn main {
  let rows = [
    @moonpageflow.page_row("event-2", [
      ("created_at", @moonpageflow.int_value(300L)),
    ]).unwrap(),
    @moonpageflow.page_row("event-1", [
      ("created_at", @moonpageflow.int_value(300L)),
    ]).unwrap(),
    @moonpageflow.page_row("event-0", [
      ("created_at", @moonpageflow.int_value(200L)),
    ]).unwrap(),
  ]
  let sort = [
    @moonpageflow.sort_field("created_at", direction=@moonpageflow.Descending),
  ]
  let first = @moonpageflow.paginate(
    rows,
    sort,
    @moonpageflow.first_page(limit=2).unwrap(),
    snapshot=Some("events-v1"),
  ).unwrap()
  for row in @moonpageflow.page_rows(first) {
    println(row.id())
  }
  println("has_next=" + first.info().has_next_page().to_string())
  println("cursor=" + first.info().end_cursor().unwrap())
}
