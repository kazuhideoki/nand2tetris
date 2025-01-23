import argv
import codes
import gleam/list
import gleam/result
import gleam/string
import parser
import simbol
import simplifile

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

  let simbol_table = simbol.init_simbol_table() |> simbol.add_labels(parsed)

  let encoded_rows = codes.encode_rows(parsed, simbol_table)
  let encoded_contents =
    encoded_rows |> list.map(fn(x) { x <> "\n" }) |> string.join("")

  let _ = simplifile.write(to: "output/Output.hack", contents: encoded_contents)

  Ok(Nil)
}
