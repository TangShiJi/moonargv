///|
/// Small deterministic generator: reproducible in native and wasm-gc CI.
fn fuzz_next(seed : Int) -> Int {
  (seed * 75 + 74) % 65521
}

///|
fn fuzz_argument(seed : Int) -> (Int, String) {
  let alphabet = [
    'a', 'Z', '0', '-', '=', '/', '\\', '"', '\'', ' ', '\t', '中',
  ]
  let mut state = fuzz_next(seed)
  let length = state % 24
  let text = StringBuilder()
  for index = 0; index < length; index = index + 1 {
    state = fuzz_next(state)
    text.write_char(alphabet[state % alphabet.length()])
  }
  (state, text.to_string())
}

///|
/// Property-style fuzzing of the central round-trip invariant.
test "1500 deterministic fuzz cases round trip in both dialects" {
  let mut seed = 20260914
  for _case = 0; _case < 1500; _case = _case + 1 {
    seed = fuzz_next(seed)
    let count = seed % 8
    let argv : Array[String] = []
    for _index = 0; _index < count; _index = _index + 1 {
      let (next, argument) = fuzz_argument(seed)
      seed = next
      argv.push(argument)
    }
    for dialect in [@moonargv.Posix, @moonargv.Windows] {
      let encoded = @moonargv.join(argv, dialect)
      let decoded = @moonargv.values(@moonargv.parse(encoded, dialect).unwrap())
      assert_eq(decoded, argv)
    }
  }
}
