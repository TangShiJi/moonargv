///|
/// Standard-input intent carried to a native, JS, or wasm host adapter.
pub(all) enum StandardInput {
  InheritInput
  ClosedInput
  TextInput(String)
} derive(Debug, Eq)

///|
/// Platform contract selects a coherent set of path, environment, and command
/// rendering rules. It prevents accidental POSIX/Windows dialect mixing.
pub(all) enum ExecutionTarget {
  PosixTarget
  WindowsTarget
} derive(Debug, Eq)

///|
/// Declarative process request. It contains no operating-system handles and
/// can therefore be prepared and tested on every MoonBit backend.
pub struct ExecutionSpec {
  command : CommandLine
  working_directory : String?
  environment_changes : Array[EnvironmentChange]
  secret_selectors : Array[SecretSelector]
  standard_input : StandardInput
} derive(Debug, Eq)

///|
/// Resource limits applied before a host receives the execution request.
pub struct ExecutionLimits {
  max_arguments : Int
  max_environment_entries : Int
  max_environment_name_chars : Int
  max_environment_value_chars : Int
  max_executable_candidates : Int
  max_command_chars : Int
} derive(Debug, Eq)

///|
/// Pure, validated output ready for a thin platform-specific process adapter.
pub struct PreparedExecution {
  target : ExecutionTarget
  invocation : InvocationPlan
  environment : EnvironmentPlan
  executable : ExecutablePlan
  working_directory : String?
  standard_input : StandardInput
  audit_command : String
} derive(Debug, Eq)

///|
pub fn execution_spec(command : CommandLine) -> ExecutionSpec {
  {
    command,
    working_directory: None,
    environment_changes: [],
    secret_selectors: [],
    standard_input: InheritInput,
  }
}

///|
pub fn execution_limits(
  max_arguments? : Int = 4096,
  max_environment_entries? : Int = 512,
  max_environment_name_chars? : Int = 256,
  max_environment_value_chars? : Int = 32768,
  max_executable_candidates? : Int = 256,
  max_command_chars? : Int = 32767,
) -> ExecutionLimits {
  {
    max_arguments: if max_arguments < 1 {
      1
    } else {
      max_arguments
    },
    max_environment_entries: if max_environment_entries < 1 {
      1
    } else {
      max_environment_entries
    },
    max_environment_name_chars: if max_environment_name_chars < 1 {
      1
    } else {
      max_environment_name_chars
    },
    max_environment_value_chars: if max_environment_value_chars < 1 {
      1
    } else {
      max_environment_value_chars
    },
    max_executable_candidates: if max_executable_candidates < 1 {
      1
    } else {
      max_executable_candidates
    },
    max_command_chars: if max_command_chars < 1 {
      1
    } else {
      max_command_chars
    },
  }
}

///|
pub fn ExecutionSpec::in_directory(
  self : ExecutionSpec,
  directory : String,
) -> ExecutionSpec {
  { ..self, working_directory: Some(directory) }
}

///|
pub fn ExecutionSpec::set_environment(
  self : ExecutionSpec,
  name : String,
  value : String,
  sensitive? : Bool = false,
) -> ExecutionSpec {
  self.environment_changes.push(set_environment(name, value, sensitive~))
  self
}

///|
pub fn ExecutionSpec::remove_environment(
  self : ExecutionSpec,
  name : String,
) -> ExecutionSpec {
  self.environment_changes.push(remove_environment(name))
  self
}

///|
pub fn ExecutionSpec::redact(
  self : ExecutionSpec,
  selector : SecretSelector,
) -> ExecutionSpec {
  self.secret_selectors.push(selector)
  self
}

///|
pub fn ExecutionSpec::stdin(
  self : ExecutionSpec,
  standard_input : StandardInput,
) -> ExecutionSpec {
  { ..self, standard_input, }
}

///|
pub fn ExecutionSpec::command(self : ExecutionSpec) -> CommandLine {
  self.command
}

///|
pub fn ExecutionSpec::working_directory(self : ExecutionSpec) -> String? {
  self.working_directory
}

///|
pub fn ExecutionSpec::environment_changes(
  self : ExecutionSpec,
) -> Array[EnvironmentChange] {
  self.environment_changes.copy()
}

///|
pub fn ExecutionSpec::secret_selectors(
  self : ExecutionSpec,
) -> Array[SecretSelector] {
  self.secret_selectors.copy()
}

///|
pub fn ExecutionSpec::standard_input(self : ExecutionSpec) -> StandardInput {
  self.standard_input
}

///|
pub fn PreparedExecution::target(self : PreparedExecution) -> ExecutionTarget {
  self.target
}

///|
pub fn PreparedExecution::invocation(
  self : PreparedExecution,
) -> InvocationPlan {
  self.invocation
}

///|
pub fn PreparedExecution::environment(
  self : PreparedExecution,
) -> EnvironmentPlan {
  self.environment
}

///|
pub fn PreparedExecution::executable(
  self : PreparedExecution,
) -> ExecutablePlan {
  self.executable
}

///|
pub fn PreparedExecution::working_directory(
  self : PreparedExecution,
) -> String? {
  self.working_directory
}

///|
pub fn PreparedExecution::standard_input(
  self : PreparedExecution,
) -> StandardInput {
  self.standard_input
}

///|
pub fn PreparedExecution::audit_command(self : PreparedExecution) -> String {
  self.audit_command
}

///|
fn target_dialect(target : ExecutionTarget) -> Dialect {
  match target {
    PosixTarget => Posix
    WindowsTarget => Windows
  }
}

///|
fn target_environment(target : ExecutionTarget) -> EnvironmentPlatform {
  match target {
    PosixTarget => PosixEnvironment
    WindowsTarget => WindowsEnvironment
  }
}

///|
fn target_host(target : ExecutionTarget) -> HostPlatform {
  match target {
    PosixTarget => PosixHost
    WindowsTarget => WindowsHost
  }
}

///|
fn validate_execution_spec(
  spec : ExecutionSpec,
  limits : ExecutionLimits,
) -> Result[Unit, ContractError] {
  let argv = spec.command.argv()
  if argv.length() > limits.max_arguments {
    return Err(
      contract_error(
        ArgumentLimitExceeded,
        "arguments",
        "logical argv exceeds configured argument count",
      ),
    )
  }
  match spec.working_directory {
    Some(directory) =>
      if directory.is_empty() || directory.contains("\u{0}") {
        return Err(
          contract_error(
            InvalidWorkingDirectory,
            "working_directory",
            "working directory must be non-empty and contain no NUL",
          ),
        )
      }
    None => ()
  }
  match spec.standard_input {
    TextInput(text) =>
      if text.to_array().length() > limits.max_environment_value_chars {
        return Err(
          contract_error(
            ArgumentLimitExceeded,
            "stdin",
            "standard input text exceeds configured resource limit",
          ),
        )
      }
    _ => ()
  }
  Ok(())
}

///|
/// Compile a process request into deterministic artifacts. The returned plan
/// still performs no filesystem access and starts no process.
pub fn prepare_execution(
  spec : ExecutionSpec,
  base_environment : Array[EnvironmentEntry],
  search_paths : Array[String],
  target : ExecutionTarget,
  response_path? : String = ".moonargv/arguments.rsp",
  windows_extensions? : Array[String] = [".COM", ".EXE", ".BAT", ".CMD"],
  limits? : ExecutionLimits = execution_limits(),
) -> Result[PreparedExecution, ContractError] {
  match validate_execution_spec(spec, limits) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let environment = match
    apply_environment(
      base_environment,
      spec.environment_changes,
      target_environment(target),
      limits=environment_limits(
        max_entries=limits.max_environment_entries,
        max_name_chars=limits.max_environment_name_chars,
        max_value_chars=limits.max_environment_value_chars,
      ),
    ) {
    Err(error) => return Err(error)
    Ok(plan) => plan
  }
  let executable = match
    executable_candidates(
      spec.command.program(),
      search_paths,
      target_host(target),
      windows_extensions~,
      max_candidates=limits.max_executable_candidates,
    ) {
    Err(error) => return Err(error)
    Ok(plan) => plan
  }
  let dialect = target_dialect(target)
  let invocation = match
    plan_invocation(
      spec.command,
      dialect,
      limits.max_command_chars,
      response_path,
    ) {
    Err(error) =>
      return Err(
        contract_error(ResponsePlanningFailed, "response_path", error.message()),
      )
    Ok(plan) => plan
  }
  let audit_command = match
    render_redacted(spec.command.argv(), dialect, spec.secret_selectors) {
    Err(error) => return Err(error)
    Ok(rendered) => rendered
  }
  Ok({
    target,
    invocation,
    environment,
    executable,
    working_directory: spec.working_directory,
    standard_input: spec.standard_input,
    audit_command,
  })
}
