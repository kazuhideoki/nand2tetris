import argv
import codes
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import parser
import simbol
import simplifile

pub fn main() {
  use parsed <- result.try(
    parser.get_raw_string(argv.load().arguments)
    |> result.map(fn(raw_string) {
      parser.parse_lines(raw_string)
      |> list.map(parser.parse_line)
    }),
  )

  let _ = io.debug(parsed)

  let simbol_table = simbol.init_simbol_table()
  let simbol_table = simbol.add_entry_to_simbol_table(parsed, simbol_table)
  io.debug(simbol_table)
  let encoded_rows = codes.encode_rows(parsed, simbol_table)
  io.debug(encoded_rows)

  let encoded_contents =
    encoded_rows |> list.map(fn(x) { x <> "\n" }) |> string.join("")
  let _ = simplifile.write(to: "output/Output.hack", contents: encoded_contents)

  Ok(Nil)
}
