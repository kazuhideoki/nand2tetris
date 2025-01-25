//// このモジュールは、P a r s e r によって解析されたVMコードをH a c k アセンブリ コードへと変換する
//// ここでは state の変更は行わない

import gleam/int
import gleam/io
import gleam/option.{None, Some}
import parser.{type CommandType, CArithmetic, CPop, CPush, Constant}
import segment_store.{type SegmentStore}

pub fn generate_first_lines(segment_store: SegmentStore) -> List(String) {
  let option_sp = segment_store.get(segment_store, "SP")
  case option_sp {
    Some(sp) -> {
      ["@" <> int.to_string(sp), "D=A", "@SP", "M=D"]
    }
    None -> panic
  }
}

pub fn generate_last_lines() {
  ["(END)", "@END", "0;JMP"]
}

/// 算術論理コマンドの command に対応するアセンブリコードを出力ファイルに書き込む。
pub fn write_arithmetic(command_type: CommandType) -> List(String) {
  case command_type {
    CArithmetic(value) ->
      case value {
        // ポインタ取得 -> スタック最上段の値取得 -> Dに格納 -> スタックのもう一段下の値取得 -> Dを加算して同じ位置に格納
        "add" -> ["@SP", "AM=M-1", "D=M", "A=A-1", "M=M+D"]
        "sub" -> ["@SP", "AM=M-1", "D=M", "A=A-1", "M=M-D"]
        "eq" -> {
          // 片方not -> & -> 0かどうか?(0なら1, 違うなら0)
          todo
        }
        "lt" -> {
          todo
        }
        "gt" -> todo
        "neg" -> ["@SP", "AM=M-1", "M=-M"]
        "and" -> ["@SP", "AM=M-1", "D=M", "A=A-1", "M=M&D"]
        "or" -> ["@SP", "AM=M-1", "D=M", "A=A-1", "M=M|D"]
        "not" -> ["@SP", "AM=M-1", "D=M", "A=A-1", "M=!M"]
        _ -> panic
      }
    _ -> panic
  }
}

/// pushまたはpopの command に対応するアセンブリコードを出力ファイルに書き込む。
pub fn write_push_pop(command_type: CommandType) -> List(String) {
  case command_type {
    CPush(segment, index) -> {
      case segment {
        Constant -> [
          "@" <> int.to_string(index),
          "D=A",
          "@SP",
          "A=M",
          "M=D",
          "@SP",
          "M=M+1",
        ]
        _ -> panic
        // 必要な実装を追加
      }
    }
    CPop(segment, index) -> {
      case segment {
        Constant -> [
          "@" <> int.to_string(index),
          "D=A",
          "@SP",
          "A=M",
          "M=D",
          "@SP",
          "M=M-1",
        ]
        _ -> panic
        // 必要な実装を追加
      }
    }
    _ -> {
      io.println_error("not implemented")
      panic
    }
  }
}
