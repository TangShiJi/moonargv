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
      while index < chars.length() && !is_command_space(chars[index]) {
        buffer.write_char(chars[index])
        index = index + 1
      }
      tokens.push(arg_token(buffer.to_string(), start, index, false))
    }
  }
  Ok(tokens)
}
