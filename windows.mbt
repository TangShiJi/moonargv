///|
/// Split a Windows command line using Microsoft CRT-style quote boundaries.
///
/// Backslash-before-quote handling is added by the dedicated CRT rules layer;
/// ordinary backslashes are always preserved as path characters.
pub fn parse_windows(input : String) -> Result[Array[ArgToken], ParseError] {
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
      let mut in_quotes = false
      let mut quoted = false
      while index < chars.length() {
        let current = chars[index]
        if current == '"' {
          in_quotes = !in_quotes
          quoted = true
          index = index + 1
        } else if is_command_space(current) && !in_quotes {
          break
        } else {
          buffer.write_char(current)
          index = index + 1
        }
      }
      tokens.push(arg_token(buffer.to_string(), start, index, quoted))
    }
  }
  Ok(tokens)
}
