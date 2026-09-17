///|
/// Produce a storage-neutral predicate plan for:
/// ORDER BY created_at DESC, priority ASC, id ASC.
pub fn next_ticket_seek() -> @moonpageflow.SeekPlan {
  let sort = [
    @moonpageflow.sort_field("created_at", direction=@moonpageflow.Descending),
    @moonpageflow.sort_field("priority"),
  ]
  let boundary = @moonpageflow.page_row("ticket-009", [
    ("created_at", @moonpageflow.int_value(1700000000L)),
    ("priority", @moonpageflow.int_value(2L)),
  ]).unwrap()
  @moonpageflow.build_seek_plan(
    @moonpageflow.position_for(boundary, sort).unwrap(),
    sort,
    @moonpageflow.ForwardPage,
  ).unwrap()
}
