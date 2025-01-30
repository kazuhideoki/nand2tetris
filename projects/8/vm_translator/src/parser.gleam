//// このモジュールは、1つの . vmファイルの解析を行う。P a r s e r は、VMコードを 読み取り、コマンドをいくつかの構成要素に分解し、その構成要素にアクセスする ためのサービスを提供する。

import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub type CommandType {
  CArithmetic(String)
  // push segment index
  CPush(Segment, Int)
  // pop segment index
  CPop(Segment, Int)
  CLabel(String)
  CIfGoto(String)
}

pub type Segment {
  Local
  Argument
  This
  That
  Pointer
  Temp
  Constant
  Static
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
  // `//` を分離して、後ろを削除する
  |> list.map(fn(row) {
    case string.split(row, "//") {
      [head, _] -> {
        let r = head |> string.trim
        io.debug(r)
        r
      }
      [head] -> {
        let r = head |> string.trim
        io.debug(r)
        r
      }
      _ -> panic
    }
  })
}

pub fn parse_line(str: String) -> CommandType {
    io.debug("🟡")
    io.debug(str)
  case str {
    "push " <> segment_and_index -> {
      let parts =
        segment_and_index
        |> string.split(" ")
      case parts {
        [segment, index_str] -> {
          case segment, int.parse(index_str) {
            "local", Ok(index) -> CPush(Local, index)
            "argument", Ok(index) -> CPush(Argument, index)
            "this", Ok(index) -> CPush(This, index)
            "that", Ok(index) -> CPush(That, index)
            "pointer", Ok(index) -> CPush(Pointer, index)
            "temp", Ok(index) -> CPush(Temp, index)
            "constant", Ok(index) -> CPush(Constant, index)
            "static", Ok(index) -> CPush(Static, index)
            _, _ -> panic
          }
        }
        _ -> panic
      }
    }
    "pop " <> segment_and_index -> {
      let parts =
        segment_and_index
        |> string.split(" ")
      case parts {
        [segment, index_str] -> {
          case segment, int.parse(index_str) {
            "local", Ok(index) -> CPop(Local, index)
            "argument", Ok(index) -> CPop(Argument, index)
            "this", Ok(index) -> CPop(This, index)
            "that", Ok(index) -> CPop(That, index)
            "pointer", Ok(index) -> CPop(Pointer, index)
            "temp", Ok(index) -> CPop(Temp, index)
            "constant", Ok(index) -> CPop(Constant, index)
            "static", Ok(index) -> CPop(Static, index)
            _, _ -> panic
          }
        }
        _ -> panic
      }
    }
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
    "label " <> label -> CLabel(label)
    "if-goto " <> label -> CIfGoto(label)
    _ -> panic
  }
}
