import argv
import codes
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import parser

pub fn main() {
  use parsed <- result.try(
    parser.get_raw_string(argv.load().arguments)
    |> result.map(fn(raw_string) {
      parser.to_list_and_trim(raw_string)
      |> list.map(parser.to_row)
    }),
  )

  let _ = io.debug(parsed)

  let result = codes.convert_into_bynaries(parsed, [])
  // io.debug(result |> list.map(fn(x) { x <> "\n" }) |> string.join(""))
  io.debug(result)

  Ok(Nil)
}
