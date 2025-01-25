//// このモジュールは、1つの . vmファイルの解析を行う。P a r s e r は、VMコードを 読み取り、コマンドをいくつかの構成要素に分解し、その構成要素にアクセスする ためのサービスを提供する。

import gleam/list
import gleam/result
import gleam/string
import simplifile

pub type CommandType {
  CArithmetic(String)
  CPush(String)
  CPop(String)
}

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

pub fn parse_line(str: String) -> CommandType {
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
