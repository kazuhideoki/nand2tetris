//// Parser 入力を解析して一連の命令の行にして、さらに各行をフィールドに分解する

import gleam/list
import gleam/result
import gleam/string
import simplifile
import types.{type Row, CArithmetic, CPop, CPush}

pub fn get_raw_string(args: List(String)) -> Result(String, Nil) {
  use path <- result.try(list.first(args))
  use file <- result.try(
    simplifile.read(path) |> result.map_error(fn(_) { Nil }),
  )

  Ok(file)
}

pub fn parse_lines(raw_string: String) -> List(String) {
  raw_string
  |> string.split("\n")
  |> list.map(fn(row) { string.trim(row) })
  |> list.filter(fn(row) { row != "" })
  |> list.filter(fn(row) { string.starts_with(row, "//") == False })
}

pub fn parse_line(str: String) -> Row {
  case str {
    "push" <> _ -> CPush(str)
    "pop" <> _ -> CPop(str)
    str
      if str == "add"
      || str == "sub"
      || str == "neg"
      || str == "eq"
      || str == "gt"
      || str == "lt"
      || str == "and"
      || str == "or"
      || str == "not"
    -> CArithmetic(str)
    _ -> panic
  }
}
