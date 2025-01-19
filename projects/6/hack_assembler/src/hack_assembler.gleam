import argv
import gleam/io
import gleam/list
import gleam/result
import parser

pub fn main() {
  let parsed =
    parser.get_raw_string(argv.load().arguments)
    |> result.map(fn(raw_string) {
      parser.to_list_and_trim(raw_string)
      |> list.map(parser.to_row)
    })

  let _ = io.debug(parsed)

  Ok(Nil)
}
