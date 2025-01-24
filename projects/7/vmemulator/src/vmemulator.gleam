import argv
import gleam/io
import gleam/list
import gleam/result
import parser

pub fn main() {
  use parsed <- result.try(
    argv.load().arguments
    |> parser.get_raw_string
    |> result.map(fn(raw_string) {
      raw_string
      |> parser.parse_lines
      |> list.map(parser.parse_line)
    }),
  )

  io.debug(parsed)

  Ok(Nil)
}
