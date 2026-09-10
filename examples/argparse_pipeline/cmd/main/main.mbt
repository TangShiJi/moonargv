///|
fn main {
  let matches = try! @argparse_pipeline.parse_deploy(
    "deploy --target 'staging cluster' --verbose",
  )
  println(matches.values.get("target").unwrap()[0])
  println(matches.flags.get("verbose").unwrap())
}
