import argv
import gleam/io
import gleam/result
import parser

pub fn main() {
  use parsed <- result.try(
    argv.load().arguments
    |> parser.get_raw_string,
  )

  io.print(parsed)

  Ok(Nil)
}
