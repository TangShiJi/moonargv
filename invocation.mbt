///|
/// Response-file payload produced for an overlong process invocation.
pub struct ResponseArtifact {
  path : String
  content : String
  dialect : Dialect
} derive(Debug, Eq)

///|
/// A process-ready argv plus an optional file the host must write first.
pub struct InvocationPlan {
  argv : Array[String]
  response : ResponseArtifact?
} derive(Debug, Eq)

///|
pub fn ResponseArtifact::path(self : ResponseArtifact) -> String {
  self.path
}

///|
pub fn ResponseArtifact::content(self : ResponseArtifact) -> String {
  self.content
}

///|
pub fn ResponseArtifact::dialect(self : ResponseArtifact) -> Dialect {
  self.dialect
}

///|
pub fn InvocationPlan::argv(self : InvocationPlan) -> Array[String] {
  self.argv.copy()
}

///|
pub fn InvocationPlan::response(self : InvocationPlan) -> ResponseArtifact? {
  self.response
}

///|
/// Plan a process invocation, spilling arguments into a response file when
/// the rendered command exceeds `max_command_chars`.
///
/// This function performs no IO or process creation. Build/process adapters
/// write `response().content()` to `response().path()`, then spawn `argv()`.
pub fn plan_invocation(
  command : CommandLine,
  dialect : Dialect,
  max_command_chars : Int,
  response_path : String,
) -> Result[InvocationPlan, ParseError] {
  let argv = command.argv()
  if command.render(dialect).to_array().length() <= max_command_chars {
    return Ok({ argv, response: None })
  }
  if response_path.is_empty() {
    return Err(
      parse_error(
        InvalidResponsePath,
        0,
        "response path must not be empty when command spilling is required",
      ),
    )
  }
  Ok({
    argv: [command.program(), "@" + response_path],
    response: Some({
      path: response_path,
      content: join(command.arguments(), dialect),
      dialect,
    }),
  })
}
