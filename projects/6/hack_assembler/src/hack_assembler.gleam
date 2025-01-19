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
      parser.parse_lines(raw_string)
      |> list.map(parser.parse_line)
    }),
  )

  let _ = io.debug(parsed)

  let encoded_rows = codes.encode_rows(parsed)
  io.debug(encoded_rows)

  let encoded_contents =
    encoded_rows |> list.map(fn(x) { x <> "\n" }) |> string.join("")
  let _ = simplifile.write(to: "output/Output.hack", contents: encoded_contents)

  Ok(Nil)
}
