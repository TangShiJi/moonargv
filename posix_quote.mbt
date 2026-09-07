///|
fn is_posix_safe_char(char : Char) -> Bool {
  (char >= 'a' && char <= 'z') ||
  (char >= 'A' && char <= 'Z') ||
  (char >= '0' && char <= '9') ||
  char == '_' ||
  char == '@' ||
  char == '%' ||
  char == '+' ||
  char == '=' ||
  char == ':' ||
  char == ',' ||
  char == '.' ||
  char == '/' ||
  char == '-'
}

///|
/// Quote one argument so `parse_posix` recovers the exact original value.
///
/// The result is data, not a request to execute a shell. Callers remain
/// responsible for choosing whether a shell is appropriate.
pub fn quote_posix(argument : String) -> String {
  if !argument.is_empty() && argument.all(is_posix_safe_char) {
    return argument
  }
  let output = StringBuilder()
  output.write_char('\'')
  for char in argument {
    if char == '\'' {
      output.write_string("'\"'\"'")
    } else {
      output.write_char(char)
    }
  }
  output.write_char('\'')
  output.to_string()
}

///|
/// Serialize an argv array using POSIX lexical quoting rules.
pub fn join_posix(arguments : Array[String]) -> String {
  let output = StringBuilder()
  for index, argument in arguments {
    if index > 0 {
      output.write_char(' ')
    }
    output.write_string(quote_posix(argument))
  }
  output.to_string()
}
