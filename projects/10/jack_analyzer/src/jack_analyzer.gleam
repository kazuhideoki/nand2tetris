import argv
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import parser
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
  io.print(xml)

  Ok(Nil)
}
