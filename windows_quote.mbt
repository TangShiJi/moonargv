///|
fn write_backslashes(output : StringBuilder, count : Int) -> Unit {
  let mut written = 0
  while written < count {
    output.write_char('\\')
    written = written + 1
  }
}

///|
fn needs_windows_quotes(argument : String) -> Bool {
  argument.is_empty() ||
  argument.any(char => is_command_space(char) || char == '"')
}

///|
/// Quote one argument according to Microsoft CRT argv reconstruction rules.
pub fn quote_windows(argument : String) -> String {
  if !needs_windows_quotes(argument) {
    return argument
  }
  let output = StringBuilder()
  let chars = argument.to_array()
  let mut index = 0
  let mut slashes = 0
  output.write_char('"')
  while index < chars.length() {
    let current = chars[index]
    if current == '\\' {
      slashes = slashes + 1
    } else if current == '"' {
      write_backslashes(output, slashes * 2 + 1)
      output.write_char('"')
      slashes = 0
    } else {
      write_backslashes(output, slashes)
      slashes = 0
      output.write_char(current)
    }
    index = index + 1
  }
  write_backslashes(output, slashes * 2)
  output.write_char('"')
  output.to_string()
}

///|
/// Serialize argv using Windows CRT-compatible quoting.
pub fn join_windows(arguments : Array[String]) -> String {
  let output = StringBuilder()
  for index, argument in arguments {
    if index > 0 {
      output.write_char(' ')
    }
    output.write_string(quote_windows(argument))
  }
  output.to_string()
}
