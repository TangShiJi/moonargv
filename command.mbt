///|
/// A program plus its logical argv, independent of shell syntax.
pub struct CommandLine {
  program : String
  arguments : Array[String]
} derive(Debug, Eq)

///|
/// Start a command builder. An empty program is rejected before rendering.
pub fn command_line(program : String) -> Result[CommandLine, ParseError] {
  if program.is_empty() {
    Err(parse_error(EmptyProgram, 0, "program must not be empty"))
  } else {
    Ok({ program, arguments: [] })
  }
}

///|
pub fn CommandLine::program(self : CommandLine) -> String {
  self.program
}

///|
pub fn CommandLine::arguments(self : CommandLine) -> Array[String] {
  self.arguments.copy()
}

///|
/// Append one argument and return the same fluent builder.
pub fn CommandLine::argument(
  self : CommandLine,
  argument : String,
) -> CommandLine {
  self.arguments.push(argument)
  self
}

///|
/// Append multiple logical arguments without parsing or joining them.
pub fn CommandLine::append_all(
  self : CommandLine,
  arguments : Array[String],
) -> CommandLine {
  for argument in arguments {
    self.arguments.push(argument)
  }
  self
}

///|
pub fn CommandLine::argv(self : CommandLine) -> Array[String] {
  let result = [self.program]
  for argument in self.arguments {
    result.push(argument)
  }
  result
}

///|
/// Render for logging, response text, or a platform API that requires one
/// command-line string. Prefer passing `argv()` directly when the host allows.
pub fn CommandLine::render(self : CommandLine, dialect : Dialect) -> String {
  join(self.argv(), dialect)
}
