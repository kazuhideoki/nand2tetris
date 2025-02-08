import argv
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import old_tokenizer
import parser

pub fn main() {
  use raw_string <- result.try(
    argv.load().arguments
    |> parser.get_raw_string,
  )

  let tokens = old_tokenizer.parse(raw_string)

  let xml =
    tokens
    |> list.map(old_tokenizer.add_xml)
    |> string.join("\n")
    |> fn(s) { "<tokens>\n" <> s <> "</tokens>" }
  io.print(xml)

  Ok(Nil)
}
