///|
/// Parse a command string without executing expansions, redirections, pipes,
/// environment variables, or command substitutions.
pub fn parse(
  input : String,
  dialect : Dialect,
) -> Result[Array[ArgToken], ParseError] {
  match dialect {
    Posix => parse_posix(input)
    Windows => parse_windows(input)
  }
}

///|
/// Recover one executable name and its argv tail from a command string.
///
/// This is the adapter point for semantic CLI parsers: pass `arguments()` to
/// `moonbitlang/core/argparse`, which intentionally accepts an already split
/// argv rather than interpreting POSIX or Windows quoting itself.
pub fn parse_command_line(
  input : String,
  dialect : Dialect,
) -> Result[ParsedCommandLine, ParseError] {
  match parse(input, dialect) {
    Err(error) => Err(error)
    Ok(tokens) =>
      if tokens.length() == 0 {
        Err(parse_error(EmptyProgram, 0, "command line has no program"))
      } else {
        let arguments : Array[String] = []
        for index = 1; index < tokens.length(); index = index + 1 {
          arguments.push(tokens[index].value())
        }
        Ok({ program: tokens[0].value(), arguments, tokens, })
      }
  }
}

///|
/// Quote one argv element for the selected lexical dialect.
pub fn quote_argument(argument : String, dialect : Dialect) -> String {
  match dialect {
    Posix => quote_posix(argument)
    Windows => quote_windows(argument)
  }
}

///|
/// Render argv so parsing it with the same dialect returns the same values.
pub fn join(arguments : Array[String], dialect : Dialect) -> String {
  match dialect {
    Posix => join_posix(arguments)
    Windows => join_windows(arguments)
  }
}
