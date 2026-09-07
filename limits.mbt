///|
/// Resource bounds for tokenizing untrusted command or response-file text.
pub struct ParseLimits {
  max_arguments : Int
  max_argument_chars : Int
} derive(Debug, Eq)

///|
pub fn parse_limits(
  max_arguments : Int,
  max_argument_chars : Int,
) -> ParseLimits {
  {
    max_arguments: if max_arguments < 1 {
      1
    } else {
      max_arguments
    },
    max_argument_chars: if max_argument_chars < 1 {
      1
    } else {
      max_argument_chars
    },
  }
}

///|
pub fn ParseLimits::max_arguments(self : ParseLimits) -> Int {
  self.max_arguments
}

///|
pub fn ParseLimits::max_argument_chars(self : ParseLimits) -> Int {
  self.max_argument_chars
}

///|
/// Parse with explicit resource limits after applying the selected grammar.
pub fn parse_limited(
  input : String,
  dialect : Dialect,
  limits : ParseLimits,
) -> Result[Array[ArgToken], ParseError] {
  match parse(input, dialect) {
    Err(error) => Err(error)
    Ok(tokens) => {
      if tokens.length() > limits.max_arguments {
        let offending = tokens[limits.max_arguments]
        return Err(
          parse_error(
            TooManyArguments,
            offending.start,
            "argument count exceeds configured limit",
          ),
        )
      }
      for token in tokens {
        if token.value.to_array().length() > limits.max_argument_chars {
          return Err(
            parse_error(
              ArgumentTooLong,
              token.start,
              "argument length exceeds configured limit",
            ),
          )
        }
      }
      Ok(tokens)
    }
  }
}
