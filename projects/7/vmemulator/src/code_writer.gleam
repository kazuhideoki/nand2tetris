//// このモジュールは、P a r s e r によって解析されたVMコードをH a c k アセンブリ コードへと変換する
//// ここでは state の変更は行わない

import gleam/int
import gleam/io
import gleam/option.{None, Some}
import parser.{type CommandType, CArithmetic, CPop, CPush, Constant}
import state.{type State}

pub fn generate_first_lines(state: State) -> List(String) {
  let #(_, memory_segment) = state
  // let sp = state.get_segment(memory_segment, "SP")
  let option_sp = state.get_segment(memory_segment, "SP")
  case option_sp {
    Some(sp) -> {
      ["@" <> int.to_string(sp), "D=A", "@SP", "M=D"]
    }
    None -> panic
  }
}

/// 算術論理コマンドの command に対応するアセンブリコードを出力ファイルに書き込む。
pub fn write_arithmetic(command_type: CommandType) -> List(String) {
  case command_type {
    CArithmetic(value) ->
      case value {
        // ポインタ取得 -> スタック最上段の値取得 -> Dに格納 -> スタックのもう一段下の値取得 -> Dを加算して同じ位置に格納
        "add" -> ["@SP", "AM=M-1", "D=M", "A=A-1", "M=M+D"]
        _ -> panic
      }
    _ -> panic
  }
}

/// pushまたはpopの command に対応するアセンブリコードを出力ファイルに書き込む。
pub fn write_push_pop(command_type: CommandType) -> List(String) {
  case command_type {
    CPush(segment, index) -> {
      io.debug("write_push_pop, push")
      io.debug(index)
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
        // または必要な実装を追加
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
        // または必要な実装を追加
      }
    }
    _ -> {
      io.println_error("not implemented")
      panic
    }
  }
}
