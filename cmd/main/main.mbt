///|
fn main {
  let first = @activity_feed.first_activity_page()
  println("activity page:")
  for row in @moonpageflow.page_rows(first) {
    println(row.id())
  }
  println("seek branches:")
  for branch in @database_seek.next_ticket_seek().branches() {
    println(branch.field())
  }
  let checkpoint = @batch_export.export_first_two_batches()
  println(
    "export checkpoint pages=" +
    checkpoint.pages().to_string() +
    " items=" +
    checkpoint.items().to_string(),
  )
}
