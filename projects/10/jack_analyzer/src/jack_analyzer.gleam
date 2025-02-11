import argv
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import parser
import simplifile
import tokenizer

pub fn main() {
  use raw_string <- result.try(
    argv.load().arguments
    |> parser.get_raw_string,
  )

  let tokens = tokenizer.tokenize(raw_string)

  let xml =
    tokens
    |> list.map(tokenizer.add_xml)
    |> string.join("\n")
    |> fn(s) { "<tokens>\n" <> s <> "\n</tokens>" }

  // output/Output.xml に書き込み
  let _ = simplifile.write("output/Output.xml", xml)

  Ok(Nil)
}
