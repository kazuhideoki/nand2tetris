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

  let tokens = tokenizer.parse(raw_string)
  // io.debug(tokens)

  // let xml = tokenizer.add_xml(tokens)
  let xml =
    tokens
    |> list.map(tokenizer.add_xml)
    |> string.join("\n")
    |> fn(s) { "<tokens>" <> s <> "</tokens>" }
  io.debug(xml)

  Ok(Nil)
}
