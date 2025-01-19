//// Parser 入力を解析して一連の命令の行にして、さらに各行をフィールドに分解する

import gleam/list
import gleam/result
import gleam/string
import simplifile
import types.{
  type Row, AInstruction, CInstruction, Comment, Comp, Jump, LInstruction,
}

// TODO 完全版
// SymbolTable はどこで保持するか？ -> 関数型なので、引数として渡す

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
}

pub fn parse_line(str: String) -> Row {
  case str {
    "//" <> _ -> Comment(str)
    "(" <> s -> {
      // TODO シンボルテーブルに登録
      let label_symbol = case s |> string.split(")") {
        [ls, _] -> ls
        _ -> panic
      }
      LInstruction(label_symbol)
    }
    "@" <> symbol -> AInstruction(symbol)
    c -> {
      let splitted_equal = string.split(c, "=")
      let splitted_semicolon = string.split(c, ";")

      case splitted_equal, splitted_semicolon {
        [dest, comp], _ -> CInstruction(Comp(dest, comp))
        _, [dest, jump] -> CInstruction(Jump(dest, jump))
        _, _ -> panic
      }
    }
  }
}
