///|
/// Failure categories produced while preparing a portable process contract.
pub(all) enum ContractErrorKind {
  InvalidEnvironmentName
  DuplicateEnvironmentName
  EnvironmentLimitExceeded
  InvalidWorkingDirectory
  InvalidExecutable
  InvalidSecretSelector
  ArgumentLimitExceeded
  CandidateLimitExceeded
  ResponsePlanningFailed
} derive(Debug, Eq)

///|
/// Structured contract error. `field` identifies the invalid environment key,
/// option, or logical component rather than an operating-system error code.
pub struct ContractError {
  kind : ContractErrorKind
  field : String
  message : String
} derive(Debug, Eq)

///|
pub fn ContractError::kind(self : ContractError) -> ContractErrorKind {
  self.kind
}

///|
pub fn ContractError::field(self : ContractError) -> String {
  self.field
}

///|
pub fn ContractError::message(self : ContractError) -> String {
  self.message
}

///|
fn contract_error(
  kind : ContractErrorKind,
  field : String,
  message : String,
) -> ContractError {
  { kind, field, message }
}
