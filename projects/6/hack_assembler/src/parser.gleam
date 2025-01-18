import gleam/list
import gleam/string

pub fn parser(raw_string: String) {
  extract_rows(raw_string)
}

fn extract_rows(raw_string: String) {
  raw_string
  |> string.split("\n")
  |> list.map(fn(row) { string.trim(row) })
  |> list.filter(fn(row) { !string.starts_with(row, "//") })
  |> list.filter(fn(row) { row != "" })
}
