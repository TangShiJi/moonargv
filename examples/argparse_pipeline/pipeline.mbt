///|
/// Parse quoting and escaping with MoonArgv, then interpret CLI options with
/// the MoonBit standard library. Each library owns one distinct layer.
pub fn parse_deploy(source : String) -> @argparse.Matches raise {
  let lexical = @moonargv.parse_command_line(source, @moonargv.Posix).unwrap()
  let command = @argparse.Command(
    lexical.program(),
    flags=[@argparse.FlagArg("verbose")],
    options=[@argparse.OptionArg("target", required=true)],
  )
  command.parse(argv=lexical.arguments(), env=Map([]))
}
