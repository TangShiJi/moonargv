///|
/// Selects logical argv values that must not appear in audit logs.
pub(all) enum SecretSelector {
  SecretArgument(Int)
  SecretAfterFlag(String)
  SecretAssignment(String)
  SecretLiteral(String)
} derive(Debug, Eq)

///|
/// Redacted argv plus the original indices that were hidden.
pub struct RedactedArguments {
  arguments : Array[String]
  redacted_indices : Array[Int]
} derive(Debug, Eq)

///|
pub fn secret_argument(index : Int) -> SecretSelector {
  SecretArgument(index)
}

///|
pub fn secret_after_flag(flag : String) -> SecretSelector {
  SecretAfterFlag(flag)
}

///|
pub fn secret_assignment(flag : String) -> SecretSelector {
  SecretAssignment(flag)
}

///|
pub fn secret_literal(value : String) -> SecretSelector {
  SecretLiteral(value)
}

///|
pub fn RedactedArguments::arguments(self : RedactedArguments) -> Array[String] {
  self.arguments.copy()
}

///|
pub fn RedactedArguments::redacted_indices(
  self : RedactedArguments,
) -> Array[Int] {
  self.redacted_indices.copy()
}

///|
fn mark_redacted(
  arguments : Array[String],
  indices : Array[Int],
  index : Int,
  replacement : String,
) -> Unit {
  arguments[index] = replacement
  for existing in indices {
    if existing == index {
      return
    }
  }
  indices.push(index)
}

///|
fn valid_secret_text(value : String) -> Bool {
  !value.is_empty() && !value.contains("\u{0}")
}

///|
/// Produce a safe argv view without changing the executable input retained by
/// the caller. Selector order does not change the final result.
pub fn redact_arguments(
  input : Array[String],
  selectors : Array[SecretSelector],
  replacement? : String = "<redacted>",
) -> Result[RedactedArguments, ContractError] {
  if replacement.is_empty() {
    return Err(
      contract_error(
        InvalidSecretSelector,
        "replacement",
        "redaction replacement must not be empty",
      ),
    )
  }
  let arguments = input.copy()
  let redacted_indices : Array[Int] = []
  for selector in selectors {
    match selector {
      SecretArgument(index) => {
        if index < 0 || index >= arguments.length() {
          return Err(
            contract_error(
              InvalidSecretSelector,
              index.to_string(),
              "secret argument index is outside argv",
            ),
          )
        }
        mark_redacted(arguments, redacted_indices, index, replacement)
      }
      SecretAfterFlag(flag) => {
        if !valid_secret_text(flag) {
          return Err(
            contract_error(
              InvalidSecretSelector,
              flag,
              "secret flag must not be empty",
            ),
          )
        }
        for index = 0; index + 1 < input.length(); index = index + 1 {
          if input[index] == flag {
            mark_redacted(arguments, redacted_indices, index + 1, replacement)
          }
        }
      }
      SecretAssignment(flag) => {
        if !valid_secret_text(flag) {
          return Err(
            contract_error(
              InvalidSecretSelector,
              flag,
              "assignment flag must not be empty",
            ),
          )
        }
        let prefix = flag + "="
        for index = 0; index < input.length(); index = index + 1 {
          if input[index].has_prefix(prefix) {
            arguments[index] = prefix + replacement
            redacted_indices.push(index)
          }
        }
      }
      SecretLiteral(value) => {
        if !valid_secret_text(value) {
          return Err(
            contract_error(
              InvalidSecretSelector,
              "literal",
              "secret literal must not be empty",
            ),
          )
        }
        for index = 0; index < input.length(); index = index + 1 {
          if input[index] == value {
            mark_redacted(arguments, redacted_indices, index, replacement)
          }
        }
      }
    }
  }
  Ok({ arguments, redacted_indices })
}

///|
/// Render a human-readable command only after applying redaction.
pub fn render_redacted(
  input : Array[String],
  dialect : Dialect,
  selectors : Array[SecretSelector],
  replacement? : String = "<redacted>",
) -> Result[String, ContractError] {
  match redact_arguments(input, selectors, replacement~) {
    Err(error) => Err(error)
    Ok(redacted) => Ok(join(redacted.arguments, dialect))
  }
}
