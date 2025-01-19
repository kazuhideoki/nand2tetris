import argv
import codes
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import parser
import simplifile

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
  io.debug(result)

  let _ =
    simplifile.write(
      to: "output/Output.hack",
      contents: result |> list.map(fn(x) { x <> "\n" }) |> string.join(""),
    )

  Ok(Nil)
}
