///|
/// Environment-key comparison follows the target process convention.
pub(all) enum EnvironmentPlatform {
  PosixEnvironment
  WindowsEnvironment
} derive(Debug, Eq)

///|
/// A materialized environment entry. Sensitive values remain available to the
/// host adapter while audit renderers replace them with a fixed marker.
pub struct EnvironmentEntry {
  name : String
  value : String
  sensitive : Bool
} derive(Debug, Eq)

///|
/// One declarative change applied over a captured host environment.
pub(all) enum EnvironmentChange {
  SetEnvironment(String, String, Bool)
  RemoveEnvironment(String)
} derive(Debug, Eq)

///|
/// Bounded environment configuration for untrusted task descriptions.
pub struct EnvironmentLimits {
  max_entries : Int
  max_name_chars : Int
  max_value_chars : Int
} derive(Debug, Eq)

///|
/// Result of applying an overlay. Entries are sorted by the target platform's
/// comparison key so logs, cache keys, and tests remain deterministic.
pub struct EnvironmentPlan {
  entries : Array[EnvironmentEntry]
  removed : Array[String]
} derive(Debug, Eq)

///|
pub fn environment_entry(
  name : String,
  value : String,
  sensitive? : Bool = false,
) -> EnvironmentEntry {
  { name, value, sensitive }
}

///|
pub fn set_environment(
  name : String,
  value : String,
  sensitive? : Bool = false,
) -> EnvironmentChange {
  SetEnvironment(name, value, sensitive)
}

///|
pub fn remove_environment(name : String) -> EnvironmentChange {
  RemoveEnvironment(name)
}

///|
pub fn environment_limits(
  max_entries? : Int = 512,
  max_name_chars? : Int = 256,
  max_value_chars? : Int = 32768,
) -> EnvironmentLimits {
  {
    max_entries: if max_entries < 1 {
      1
    } else {
      max_entries
    },
    max_name_chars: if max_name_chars < 1 {
      1
    } else {
      max_name_chars
    },
    max_value_chars: if max_value_chars < 1 {
      1
    } else {
      max_value_chars
    },
  }
}

///|
pub fn EnvironmentEntry::name(self : EnvironmentEntry) -> String {
  self.name
}

///|
pub fn EnvironmentEntry::value(self : EnvironmentEntry) -> String {
  self.value
}

///|
pub fn EnvironmentEntry::is_sensitive(self : EnvironmentEntry) -> Bool {
  self.sensitive
}

///|
pub fn EnvironmentPlan::entries(
  self : EnvironmentPlan,
) -> Array[EnvironmentEntry] {
  self.entries.copy()
}

///|
pub fn EnvironmentPlan::removed(self : EnvironmentPlan) -> Array[String] {
  self.removed.copy()
}

///|
pub fn EnvironmentPlan::audit_lines(
  self : EnvironmentPlan,
  marker? : String = "<redacted>",
) -> Array[String] {
  self.entries.map(fn(entry) {
    let shown = if entry.sensitive { marker } else { entry.value }
    entry.name + "=" + shown
  })
}

///|
fn environment_key(name : String, platform : EnvironmentPlatform) -> String {
  match platform {
    PosixEnvironment => name
    WindowsEnvironment => name.to_lower()
  }
}

///|
fn valid_environment_name(name : String) -> Bool {
  !name.is_empty() && !name.contains("=") && !name.contains("\u{0}")
}

///|
fn find_environment_entry(
  entries : Array[EnvironmentEntry],
  name : String,
  platform : EnvironmentPlatform,
) -> Int {
  let wanted = environment_key(name, platform)
  for index = 0; index < entries.length(); index = index + 1 {
    if environment_key(entries[index].name, platform) == wanted {
      return index
    }
  }
  -1
}

///|
fn validate_environment_entry(
  entry : EnvironmentEntry,
  limits : EnvironmentLimits,
) -> Result[Unit, ContractError] {
  if !valid_environment_name(entry.name) {
    return Err(
      contract_error(
        InvalidEnvironmentName,
        entry.name,
        "environment name must be non-empty and contain neither '=' nor NUL",
      ),
    )
  }
  if entry.name.to_array().length() > limits.max_name_chars {
    return Err(
      contract_error(
        EnvironmentLimitExceeded,
        entry.name,
        "environment name exceeds configured character limit",
      ),
    )
  }
  if entry.value.to_array().length() > limits.max_value_chars {
    return Err(
      contract_error(
        EnvironmentLimitExceeded,
        entry.name,
        "environment value exceeds configured character limit",
      ),
    )
  }
  Ok(())
}

///|
fn sort_environment_entries(
  entries : Array[EnvironmentEntry],
  platform : EnvironmentPlatform,
) -> Unit {
  for index = 1; index < entries.length(); index = index + 1 {
    let mut cursor = index
    while cursor > 0 &&
          environment_key(entries[cursor].name, platform) <
          environment_key(entries[cursor - 1].name, platform) {
      let previous = entries[cursor - 1]
      entries[cursor - 1] = entries[cursor]
      entries[cursor] = previous
      cursor = cursor - 1
    }
  }
}

///|
/// Apply a sequence of changes in order. Repeated sets intentionally use
/// last-write-wins semantics; a remove followed by set recreates the key.
pub fn apply_environment(
  base : Array[EnvironmentEntry],
  changes : Array[EnvironmentChange],
  platform : EnvironmentPlatform,
  limits? : EnvironmentLimits = environment_limits(),
) -> Result[EnvironmentPlan, ContractError] {
  let entries : Array[EnvironmentEntry] = []
  for entry in base {
    match validate_environment_entry(entry, limits) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
    if find_environment_entry(entries, entry.name, platform) >= 0 {
      return Err(
        contract_error(
          DuplicateEnvironmentName,
          entry.name,
          "base environment contains duplicate names for target platform",
        ),
      )
    }
    entries.push(entry)
  }
  let removed : Array[String] = []
  for change in changes {
    match change {
      SetEnvironment(name, value, sensitive) => {
        let entry = environment_entry(name, value, sensitive~)
        match validate_environment_entry(entry, limits) {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
        let index = find_environment_entry(entries, name, platform)
        if index >= 0 {
          entries[index] = entry
        } else {
          entries.push(entry)
        }
      }
      RemoveEnvironment(name) => {
        if !valid_environment_name(name) {
          return Err(
            contract_error(
              InvalidEnvironmentName,
              name,
              "removed environment name is invalid",
            ),
          )
        }
        let index = find_environment_entry(entries, name, platform)
        if index >= 0 {
          ignore(entries.remove(index))
        }
        if find_environment_entry(
            removed.map(item => environment_entry(item, "")),
            name,
            platform,
          ) <
          0 {
          removed.push(name)
        }
      }
    }
    if entries.length() > limits.max_entries {
      return Err(
        contract_error(
          EnvironmentLimitExceeded,
          "environment",
          "environment entry count exceeds configured limit",
        ),
      )
    }
  }
  sort_environment_entries(entries, platform)
  Ok({ entries, removed })
}
