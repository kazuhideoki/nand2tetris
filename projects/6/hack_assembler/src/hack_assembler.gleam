import argv
import gleam/io
import gleam/result
import parser

pub fn main() {
  let parsed =
    parser.get_raw_string(argv.load().arguments)
    |> result.map(parser.parser)

  io.debug(parsed)

  Ok(Nil)
}
