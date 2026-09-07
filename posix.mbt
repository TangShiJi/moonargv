///|
fn is_command_space(char : Char) -> Bool {
  char == ' ' || char == '\t' || char == '\n' || char == '\r'
}

///|
/// Split an unexpanded POSIX-style command string into arguments.
///
/// This lexer never executes substitutions or operators. Each token records
/// its character range so callers can attach diagnostics to the source text.
pub fn parse_posix(input : String) -> Result[Array[ArgToken], ParseError] {
  let chars = input.to_array()
  let tokens : Array[ArgToken] = []
  let mut index = 0
  while index < chars.length() {
    while index < chars.length() && is_command_space(chars[index]) {
      index = index + 1
    }
    if index < chars.length() {
      let start = index
      let buffer = StringBuilder()
      let mut in_single = false
      let mut in_double = false
      let mut quoted = false
      let mut quote_start = -1
      while index < chars.length() {
        let current = chars[index]
        if current == '\'' && !in_double {
          if !in_single {
            quote_start = index
          }
          in_single = !in_single
          quoted = true
          index = index + 1
        } else if current == '"' && !in_single {
          if !in_double {
            quote_start = index
          }
          in_double = !in_double
          quoted = true
          index = index + 1
        } else if is_command_space(current) && !in_single && !in_double {
          break
        } else {
          buffer.write_char(current)
          index = index + 1
        }
      }
      if in_single {
        return Err(
          parse_error(
            UnterminatedSingleQuote,
            quote_start,
            "unterminated POSIX single quote",
          ),
        )
      }
      if in_double {
        return Err(
          parse_error(
            UnterminatedDoubleQuote,
            quote_start,
            "unterminated POSIX double quote",
          ),
        )
      }
      tokens.push(arg_token(buffer.to_string(), start, index, quoted))
    }
  }
  Ok(tokens)
}
