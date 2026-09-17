///|
fn export_rows() -> Array[@moonpageflow.PageRow] {
  let rows : Array[@moonpageflow.PageRow] = []
  for index = 0; index < 6; index = index + 1 {
    rows.push(
      @moonpageflow.page_row("record-" + index.to_string(), [
        ("sequence", @moonpageflow.int_value(index.to_int64())),
      ]).unwrap(),
    )
  }
  rows
}

///|
pub fn export_first_two_batches() -> @moonpageflow.TraversalCheckpoint {
  let rows = export_rows()
  let sort = [@moonpageflow.sort_field("sequence")]
  let initial = @moonpageflow.traversal_checkpoint(snapshot=Some("export-v7"))
  let first = @moonpageflow.paginate(
    rows,
    sort,
    initial.next_request(2).unwrap(),
    snapshot=Some("export-v7"),
  ).unwrap()
  let checkpoint = @moonpageflow.advance_checkpoint(initial, first).unwrap()
  let second = @moonpageflow.paginate(
    rows,
    sort,
    checkpoint.next_request(2).unwrap(),
    snapshot=Some("export-v7"),
  ).unwrap()
  @moonpageflow.advance_checkpoint(checkpoint, second).unwrap()
}
