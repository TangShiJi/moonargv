///|
/// Command-line grammar used for tokenization and serialization.
pub(all) enum Dialect {
  Posix
  Windows
} derive(Debug, Eq)

///|
/// One parsed argument and its half-open character range in the source text.
pub struct ArgToken {
  value : String
  start : Int
  end : Int
  quoted : Bool
} derive(Debug, Eq)

///|
/// A command line after lexical recovery. `program` is kept separate because
/// semantic CLI parsers such as the standard-library `argparse` expect only
/// the arguments that follow the executable name.
pub struct ParsedCommandLine {
  program : String
  arguments : Array[String]
  tokens : Array[ArgToken]
} derive(Debug, Eq)

///|
pub(all) enum ParseErrorKind {
  UnterminatedSingleQuote
  UnterminatedDoubleQuote
  DanglingEscape
  TooManyArguments
  ArgumentTooLong
  EmptyProgram
} derive(Debug, Eq)

///|
/// Structured failure with a character offset suitable for editor diagnostics.
pub struct ParseError {
  kind : ParseErrorKind
  offset : Int
  message : String
} derive(Debug, Eq)

///|
pub fn ArgToken::value(self : ArgToken) -> String {
  self.value
}

///|
pub fn ArgToken::start(self : ArgToken) -> Int {
  self.start
}

///|
pub fn ArgToken::end(self : ArgToken) -> Int {
  self.end
}

///|
pub fn ArgToken::was_quoted(self : ArgToken) -> Bool {
  self.quoted
}

///|
pub fn ParsedCommandLine::program(self : ParsedCommandLine) -> String {
  self.program
}

///|
/// Return a copy of the semantic argv tail, excluding the executable name.
pub fn ParsedCommandLine::arguments(self : ParsedCommandLine) -> Array[String] {
  self.arguments.copy()
}

///|
/// Return a copy of all source-aware tokens, including the executable name.
pub fn ParsedCommandLine::tokens(self : ParsedCommandLine) -> Array[ArgToken] {
  self.tokens.copy()
}

///|
pub fn ParseError::kind(self : ParseError) -> ParseErrorKind {
  self.kind
}

///|
pub fn ParseError::offset(self : ParseError) -> Int {
  self.offset
}

///|
pub fn ParseError::message(self : ParseError) -> String {
  self.message
}

///|
fn parse_error(
  kind : ParseErrorKind,
  offset : Int,
  message : String,
) -> ParseError {
  { kind, offset, message, }
}

///|
fn arg_token(value : String, start : Int, end : Int, quoted : Bool) -> ArgToken {
  { value, start, end, quoted, }
}

///|
pub fn values(tokens : Array[ArgToken]) -> Array[String] {
  tokens.map(token => token.value)
}
