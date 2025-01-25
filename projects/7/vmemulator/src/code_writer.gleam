//// このモジュールは、P a r s e r によって解析されたVMコードをH a c k アセンブリ コードへと変換する
//// ここでは state の変更は行わない

import gleam/int
import gleam/io
import parser.{
  type CommandType, type Segment, CArithmetic, CPop, CPush, Constant,
}
import state.{type State, SInt}

/// 算術論理コマンドの command に対応するアセンブリコードを出力ファイルに書き込む。
pub fn write_arithmetic(command_type: CommandType) -> List(String) {
  case command_type {
    CArithmetic(value) ->
      case value {
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
