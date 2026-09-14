///|
/// A fixed-workload benchmark driver. The checksum keeps all parse results
/// observable; wall-clock measurement is performed by tools/benchmark.ps1.
fn main {
  let argv = [
    "moonc", "src/main.mbt", "folder/source file.mbt", "--output", "build artifacts/app.wasm",
    "say \"ready\"", "C:\\release folder\\", "中文参数",
  ]
  let mut checksum = 0
  for _iteration = 0; _iteration < 10000; _iteration = _iteration + 1 {
    for dialect in [@moonargv.Posix, @moonargv.Windows] {
      let encoded = @moonargv.join(argv, dialect)
      let decoded = @moonargv.values(@moonargv.parse(encoded, dialect).unwrap())
      checksum = checksum + encoded.length() + decoded.length()
    }
  }
  println(checksum)
}
