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
