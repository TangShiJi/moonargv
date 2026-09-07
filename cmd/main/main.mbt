///|
fn show_tokens(label : String, tokens : Array[@moonargv.ArgToken]) -> Unit {
  println(label)
  for index, token in tokens {
    println("  [\{index}] \{token.value()}")
  }
}

///|
fn main {
  let posix_source = "deploy --message 'release candidate' --path build\\ output"
  let posix_tokens = @moonargv.parse(posix_source, @moonargv.Posix).unwrap()
  show_tokens("POSIX tokens", posix_tokens)

  let command = @moonargv.command_line("C:\\Program Files\\Moon\\tool.exe")
    .unwrap()
    .argument("--message")
    .argument("say \"ready\"")
    .argument("C:\\output path\\")
  let rendered = command.render(@moonargv.Windows)
  println("Windows command")
  println("  \{rendered}")
  let recovered = @moonargv.parse(rendered, @moonargv.Windows).unwrap()
  println("round trip: \{@moonargv.values(recovered) == command.argv()}")
}
