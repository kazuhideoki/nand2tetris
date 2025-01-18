//// Parser 入力を解析して一連の命令の行にして、さらに各行をフィールドに分解する

import gleam/list
import gleam/string
import types.{type Row, Comment, Instruction, Label}

pub fn parser(raw_string: String) {
  raw_string
  |> to_list_and_trim
  |> list.map(fn(row) { to_row(row) })
}

fn to_list_and_trim(raw_string: String) -> List(String) {
  raw_string
  |> string.split("\n")
  |> list.map(fn(row) { string.trim(row) })
  |> list.filter(fn(row) { row != "" })
}

fn to_row(str: String) -> Row {
  case str {
    "//" <> _ -> Comment(str)
    "(" <> _ -> Label(str)
    _ -> Instruction(str)
  }
}
