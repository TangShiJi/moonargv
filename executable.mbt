///|
/// Path and executable-name conventions used to build lookup candidates.
pub(all) enum HostPlatform {
  PosixHost
  WindowsHost
} derive(Debug, Eq)

///|
/// Candidate paths are pure data: the host decides which candidate exists and
/// is executable. This keeps the package portable to wasm-gc.
pub struct ExecutablePlan {
  program : String
  explicit_path : Bool
  candidates : Array[String]
} derive(Debug, Eq)

///|
pub fn ExecutablePlan::program(self : ExecutablePlan) -> String {
  self.program
}

///|
pub fn ExecutablePlan::has_explicit_path(self : ExecutablePlan) -> Bool {
  self.explicit_path
}

///|
pub fn ExecutablePlan::candidates(self : ExecutablePlan) -> Array[String] {
  self.candidates.copy()
}

///|
fn platform_equal(
  left : String,
  right : String,
  platform : HostPlatform,
) -> Bool {
  match platform {
    PosixHost => left == right
    WindowsHost => left.to_lower() == right.to_lower()
  }
}

///|
fn has_explicit_path(program : String) -> Bool {
  program.contains("/") || program.contains("\\")
}

///|
fn final_path_component(path : String) -> String {
  let normalized = path.replace(old="\\", new="/")
  let parts = normalized.split("/").to_array()
  if parts.length() == 0 {
    path
  } else {
    parts[parts.length() - 1].to_owned()
  }
}

///|
fn has_filename_extension(program : String) -> Bool {
  let component = final_path_component(program)
  component.contains(".") && !component.has_suffix(".")
}

///|
fn normalize_extension(extension : String) -> String {
  if extension.is_empty() {
    ""
  } else if extension.has_prefix(".") {
    extension
  } else {
    "." + extension
  }
}

///|
fn join_search_path(
  directory : String,
  program : String,
  platform : HostPlatform,
) -> String {
  if directory.is_empty() || directory == "." {
    program
  } else {
    let separator = match platform {
      PosixHost => "/"
      WindowsHost => "\\"
    }
    if directory.has_suffix("/") || directory.has_suffix("\\") {
      directory + program
    } else {
      directory + separator + program
    }
  }
}

///|
fn push_unique_candidate(
  candidates : Array[String],
  candidate : String,
  platform : HostPlatform,
) -> Unit {
  for existing in candidates {
    if platform_equal(existing, candidate, platform) {
      return
    }
  }
  candidates.push(candidate)
}

///|
fn append_program_variants(
  candidates : Array[String],
  prefix : String,
  program : String,
  platform : HostPlatform,
  windows_extensions : Array[String],
) -> Unit {
  let base = join_search_path(prefix, program, platform)
  push_unique_candidate(candidates, base, platform)
  if platform is WindowsHost && !has_filename_extension(program) {
    for extension in windows_extensions {
      let normalized = normalize_extension(extension)
      if !normalized.is_empty() {
        push_unique_candidate(candidates, base + normalized, platform)
      }
    }
  }
}

///|
/// Build the paths a host adapter should probe, in deterministic order.
///
/// POSIX callers normally pass PATH split on `:`. Windows callers pass PATH
/// directories and PATHEXT split on `;`. No filesystem access occurs here.
pub fn executable_candidates(
  program : String,
  search_paths : Array[String],
  platform : HostPlatform,
  windows_extensions? : Array[String] = [".COM", ".EXE", ".BAT", ".CMD"],
  max_candidates? : Int = 256,
) -> Result[ExecutablePlan, ContractError] {
  if program.is_empty() || program.contains("\u{0}") {
    return Err(
      contract_error(
        InvalidExecutable,
        "program",
        "executable name must be non-empty and contain no NUL",
      ),
    )
  }
  let explicit_path = has_explicit_path(program)
  let candidates : Array[String] = []
  if explicit_path {
    append_program_variants(
      candidates, "", program, platform, windows_extensions,
    )
  } else if search_paths.length() == 0 {
    append_program_variants(
      candidates, "", program, platform, windows_extensions,
    )
  } else {
    for directory in search_paths {
      append_program_variants(
        candidates, directory, program, platform, windows_extensions,
      )
      if candidates.length() > max_candidates {
        return Err(
          contract_error(
            CandidateLimitExceeded,
            "search_paths",
            "executable candidate count exceeds configured limit",
          ),
        )
      }
    }
  }
  Ok({ program, explicit_path, candidates })
}
