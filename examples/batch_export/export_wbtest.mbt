///|
test "batch export checkpoint can be persisted after two pages" {
  let checkpoint = export_first_two_batches()
  assert_eq(checkpoint.pages(), 2)
  assert_eq(checkpoint.items(), 4)
  assert_eq(checkpoint.seen_ids(), [
    "record-0", "record-1", "record-2", "record-3",
  ])
  assert_eq(checkpoint.snapshot(), Some("export-v7"))
  assert_true(checkpoint.cursor() is Some(_))
}
