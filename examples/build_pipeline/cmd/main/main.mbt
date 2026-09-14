///|
fn main {
  let plan = @build_pipeline.prepare_compile()
  for argument in plan.argv() {
    println(argument)
  }
  guard plan.response() is Some(response) else { return }
  println(response.path())
  println(response.content())
}
