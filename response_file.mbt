///|
/// Configuration for bounded, recursive response-file expansion.
pub struct ResponseLimits {
  max_depth : Int
  parse_limits : ParseLimits
} derive(Debug, Eq)

///|
pub fn response_limits(
  max_depth : Int,
  max_arguments : Int,
  max_argument_chars : Int,
) -> ResponseLimits {
  {
    max_depth: if max_depth < 0 {
      0
    } else {
      max_depth
    },
    parse_limits: parse_limits(max_arguments, max_argument_chars),
  }
}

///|
pub fn ResponseLimits::max_depth(self : ResponseLimits) -> Int {
  self.max_depth
}

///|
fn stack_contains(stack : Array[String], path : String) -> Bool {
  for active in stack {
    if active == path {
      return true
    }
  }
  false
}

///|
fn push_expanded_argument(
  output : Array[String],
  argument : String,
  limits : ParseLimits,
) -> Result[Unit, ParseError] {
  if output.length() >= limits.max_arguments {
    return Err(
      parse_error(
        TooManyArguments,
        0,
        "expanded argument count exceeds configured limit",
      ),
    )
  }
  if argument.to_array().length() > limits.max_argument_chars {
    return Err(
      parse_error(
        ArgumentTooLong,
        0,
        "expanded argument length exceeds configured limit",
      ),
    )
  }
  output.push(argument)
  Ok(())
}

///|
fn expand_response_argument(
  argument : String,
  files : Map[String, String],
  dialect : Dialect,
  limits : ResponseLimits,
  depth : Int,
  stack : Array[String],
  output : Array[String],
) -> Result[Unit, ParseError] {
  if argument.has_prefix("@@") {
    return push_expanded_argument(
      output,
      argument[1:].to_owned(),
      limits.parse_limits,
    )
  }
  if !argument.has_prefix("@") || argument.length() == 1 {
    return push_expanded_argument(output, argument, limits.parse_limits)
  }
  let path = argument[1:].to_owned()
  if depth >= limits.max_depth {
    return Err(
      parse_error(
        ResponseFileDepthExceeded,
        0,
        "response-file nesting exceeds configured limit at '{path}'",
      ),
    )
  }
  if stack_contains(stack, path) {
    return Err(
      parse_error(
        ResponseFileCycle,
        0,
        "response-file cycle detected at '{path}'",
      ),
    )
  }
  guard files.get(path) is Some(content) else {
    return Err(
      parse_error(
        ResponseFileNotFound,
        0,
        "response file '{path}' was not supplied by the host",
      ),
    )
  }
  let tokens = match parse_limited(content, dialect, limits.parse_limits) {
    Ok(tokens) => tokens
    Err(error) =>
      return Err(
        parse_error(
          error.kind,
          error.offset,
          "response file '{path}': {error.message}",
        ),
      )
  }
  let child_stack = stack.copy()
  child_stack.push(path)
  for token in tokens {
    match
      expand_response_argument(
        token.value,
        files,
        dialect,
        limits,
        depth + 1,
        child_stack,
        output,
      ) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
  }
  Ok(())
}

///|
/// Expand `@path` arguments from host-supplied response-file contents.
///
/// The core stays IO-free and cross-backend: a process or build integration
/// reads files using its own filesystem API, then supplies their text in
/// `files`. Nested files are supported; `@@name` escapes a literal `@name`.
pub fn expand_response_files(
  arguments : Array[String],
  files : Map[String, String],
  dialect : Dialect,
  limits : ResponseLimits,
) -> Result[Array[String], ParseError] {
  let output : Array[String] = []
  for argument in arguments {
    match
      expand_response_argument(argument, files, dialect, limits, 0, [], output) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
  }
  Ok(output)
}
