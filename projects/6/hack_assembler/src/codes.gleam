//// Hackのシンボルとニーモニックをバイナリコードに変換する ためのサービスを提供する

import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import types.{
  type Row, AInstruction, CInstruction, Comment, Comp, Jump, LInstruction,
}

// TODO for Max
// 1 シンボルテーブルつくる -> 定数、ラベル、変数。一覧 -> p136
// 2 jump に対応するために ラベルの保持

pub fn encode_rows(rows: List(Row)) -> List(String) {
  rows
  |> list.fold([], fn(acc, row) {
    case encode_row(row) {
      Some(bynary) -> list.append(acc, [bynary])
      None -> acc
    }
  })
}

fn encode_row(row: Row) -> Option(String) {
  case row {
    // 2進数に変換する
    AInstruction(str_val) -> {
      case int.parse(str_val) {
        Ok(num) -> {
          let bits = int.to_base2(num) |> string.pad_start(16, "0")
          Some(bits)
        }
        Error(_) -> {
          // TODO 数字以外はラベルとして扱う。登録する
          None
        }
      }
    }
    CInstruction(comp_or_jump) -> {
      case comp_or_jump {
        Comp(dest, comp) ->
          Some("111" <> encode_comp(comp) <> encode_dest(dest) <> "000")
        Jump(dest, jump) ->
          Some("111" <> "0000000" <> encode_dest(dest) <> encode_jump(jump))
      }
    }
    LInstruction(str) -> todo
    Comment(_) -> None
  }
}

pub fn encode_dest(str: String) {
  case str {
    "M" -> "001"
    "D" -> "010"
    "DM" -> "011"
    "A" -> "100"
    "AM" -> "101"
    "AD" -> "110"
    "ADM" -> "111"
    _ -> panic
  }
}

pub fn encode_comp(str: String) {
  case str {
    "0" -> "0101010"
    "1" -> "0111111"
    "-1" -> "0111010"
    "D" -> "0001100"
    "A" -> "0110000"
    "!D" -> "0001101"
    "!A" -> "0110001"
    "-D" -> "0001111"
    "-A" -> "0110011"
    "D+1" -> "0011111"
    "A+1" -> "0110111"
    "D-1" -> "0001110"
    "A-1" -> "0110010"
    "D+A" -> "0000010"
    "D-A" -> "0010011"
    "A-D" -> "0000111"
    "D&A" -> "0000000"
    "D|A" -> "0010101"
    "M" -> "1110000"
    "!M" -> "1110001"
    "-M" -> "1110011"
    "M+1" -> "1110111"
    "M-1" -> "1110010"
    "D+M" -> "1000010"
    "D-M" -> "1010011"
    "M-D" -> "1000111"
    "D&M" -> "1000000"
    "D|M" -> "1010101"
    _ -> panic
  }
}

pub fn encode_jump(str: String) {
  case str {
    "JGT" -> "001"
    "JEQ" -> "010"
    "JGE" -> "011"
    "JLT" -> "100"
    "JNE" -> "101"
    "JLE" -> "110"
    "JMP" -> "111"
    _ -> panic
  }
}
