//// このモジュールは、P a r s e r によって解析されたVMコードをH a c k アセンブリ コードへと変換する

import argv
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string

import parser.{
  type CommandType, type Segment, Argument, CArithmetic, CPop, CPush, Constant,
  Local, Pointer, Static, Temp, That, This,
}

pub fn generate_first_lines() -> List(String) {
  [
    "@256", "D=A", "@SP", "M=D", "@1", "D=A", "@LCL", "M=D", "@2", "D=A", "@ARG",
    "M=D", "@3", "D=A", "@THIS", "M=D", "@4", "D=A", "@THAT", "M=D", "@5", "D=A",
    "@TEMP", "M=D", "@13", "D=A", "@R13", "M=D", "@14", "D=A", "@R14", "M=D",
    "@15", "D=A", "@R15", "M=D",
  ]
}

pub fn generate_last_lines() {
  ["(END)", "@END", "0;JMP"]
}

/// 算術論理コマンドの command に対応するアセンブリコードを出力ファイルに書き込む。
/// 一意なラベルを生成するために、label_counter を引数に取る。
pub fn write_arithmetic(
  command: String,
  label_counter: Int,
) -> #(List(String), Int) {
  case command {
    // ポインタ取得 -> スタック最上段の値取得 -> Dに格納 -> スタックのもう一段下の値取得 -> Dを加算して同じ位置に格納
    "add" -> #(["@SP", "AM=M-1", "D=M", "A=A-1", "M=M+D"], label_counter + 1)
    "sub" -> #(["@SP", "AM=M-1", "D=M", "A=A-1", "M=M-D"], label_counter + 1)
    "eq" -> {
      let eq_true_label = "EQ_TRUE_" <> int.to_string(label_counter)
      let eq_end_label = "EQ_END_" <> int.to_string(label_counter)
      // 差を計算する
      #(
        ["@SP", "AM=M-1", "D=M", "A=A-1", "D=M-D"]
          // 0 なら true(-1), それ以外なら false(0)
          |> list.append([
            "@" <> eq_true_label,
            "D;JEQ",
            "@SP",
            "A=M-1",
            "M=0",
            "@" <> eq_end_label,
            "0;JMP",
            "(" <> eq_true_label <> ")",
            "@SP",
            "A=M-1",
            "M=-1",
            "(" <> eq_end_label <> ")",
          ]),
        label_counter + 1,
      )
    }
    "lt" -> {
      let lt_true_label = "LT_TRUE_" <> int.to_string(label_counter)
      let lt_end_label = "LT_END_" <> int.to_string(label_counter)
      #(
        ["@SP", "AM=M-1", "D=M", "A=A-1", "D=M-D"]
          |> list.append([
            "@" <> lt_true_label,
            "D;JLT",
            "@SP",
            "A=M-1",
            "M=0",
            "@" <> lt_end_label,
            "0;JMP",
            "(" <> lt_true_label <> ")",
            "@SP",
            "A=M-1",
            "M=-1",
            "(" <> lt_end_label <> ")",
          ]),
        label_counter + 1,
      )
    }
    "gt" -> {
      let gt_true_label = "GT_TRUE_" <> int.to_string(label_counter)
      let gt_end_label = "GT_END_" <> int.to_string(label_counter)
      #(
        ["@SP", "AM=M-1", "D=M", "A=A-1", "D=M-D"]
          |> list.append([
            "@" <> gt_true_label,
            "D;JGT",
            "@SP",
            "A=M-1",
            "M=0",
            "@" <> gt_end_label,
            "0;JMP",
            "(" <> gt_true_label <> ")",
            "@SP",
            "A=M-1",
            "M=-1",
            "(" <> gt_end_label <> ")",
          ]),
        label_counter + 1,
      )
    }
    // "neg" -> #(["@SP", "AM=M-1", "M=-M"], label_counter)
    // SPデクリメントせずに、そのアドレスの値を反転するだけ
    "neg" -> #(["@SP", "A=M-1", "M=-M"], label_counter)
    "and" -> #(["@SP", "AM=M-1", "D=M", "A=A-1", "M=M&D"], label_counter)
    "or" -> #(["@SP", "AM=M-1", "D=M", "A=A-1", "M=M|D"], label_counter)
    "not" -> #(["@SP", "A=M-1", "M=!M"], label_counter)
    _ -> panic
  }
}

/// push の command に対応するアセンブリコードを出力ファイルに書き込む。
pub fn write_push(segment: Segment, index: Int) -> List(String) {
  let segment_code = case segment {
    Constant -> ["@" <> int.to_string(index), "D=A"]
    Local -> [
      "@LCL",
      "D=M",
      // D = RAM[LCL] (localセグメントのベースアドレス)
      "@" <> int.to_string(index),
      // A = LCL + index
      "A=D+A",
      // D = RAM[LCL + index] そこに入っている値
      "D=M",
    ]
    Argument -> ["@ARG", "D=M", "@" <> int.to_string(index), "A=D+A", "D=M"]
    This -> ["@THIS", "D=M", "@" <> int.to_string(index), "A=D+A", "D=M"]
    That -> ["@THAT", "D=M", "@" <> int.to_string(index), "A=D+A", "D=M"]
    Temp -> ["@TEMP", "D=M", "@" <> int.to_string(index), "A=D+A", "D=M"]
    Pointer -> {
      // 現在の値を stack に push する
      case index {
        0 -> ["@THIS", "D=M"]
        1 -> ["@THAT", "D=M"]
        _ -> panic
      }
    }
    Static -> {
      let file_name = case list.first(argv.load().arguments) {
        Ok(file_name) ->
          string.split(file_name, "/")
          |> list.last
          |> result.map(fn(l) { string.replace(l, ".vm", "") })
        Error(_) -> panic
      }
      case file_name {
        Ok(file_name) -> ["@" <> file_name <> int.to_string(index), "D=M"]
        Error(_) -> panic
      }
    }
    _ -> panic
  }
  segment_code
  // SP のインクリメント
  |> list.append(["@SP", "A=M", "M=D", "@SP", "M=M+1"])
}

/// pop の command に対応するアセンブリコードを出力ファイルに書き込む。
pub fn write_pop(segment: Segment, index: Int) -> List(String) {
  // SP のデクリメントは個別で行う。
  case segment {
    Local -> [
      "@LCL",
      "D=M",
      "@" <> int.to_string(index),
      "D=D+A",
      "@13",
      "M=D",
      // ↓ 最後にスタックトップを D に取り出して RAM[R13] に書き込む
      "@SP",
      "AM=M-1",
      "D=M",
      "@13",
      "A=M",
      "M=D",
    ]
    Argument -> [
      "@ARG",
      "D=M",
      "@" <> int.to_string(index),
      "D=D+A",
      "@13",
      "M=D",
      "@SP",
      "AM=M-1",
      "D=M",
      "@13",
      "A=M",
      "M=D",
    ]
    This -> [
      "@THIS",
      "D=M",
      "@" <> int.to_string(index),
      "D=D+A",
      "@13",
      "M=D",
      "@SP",
      "AM=M-1",
      "D=M",
      "@13",
      "A=M",
      "M=D",
    ]
    That -> [
      "@THAT",
      "D=M",
      "@" <> int.to_string(index),
      "D=D+A",
      "@13",
      "M=D",
      "@SP",
      "AM=M-1",
      "D=M",
      "@13",
      "A=M",
      "M=D",
    ]
    Temp -> [
      "@TEMP",
      "D=M",
      "@" <> int.to_string(index),
      "D=D+A",
      "@13",
      "M=D",
      "@SP",
      "AM=M-1",
      "D=M",
      "@13",
      "A=M",
      "M=D",
    ]
    Pointer ->
      case index {
        // pointer 0 = THIS -> RAM[3] へ pop
        0 -> [
          "@SP", "AM=M-1",
          // SP--
          "D=M",
          // D = *(SP)
          "@3", "M=D",
          // RAM[3] = D
        ]
        // pointer 1 = THAT -> RAM[4] へ pop
        1 -> ["@SP", "AM=M-1", "D=M", "@4", "M=D"]
        _ -> panic
      }
    Static -> {
      let file_name = case list.first(argv.load().arguments) {
        Ok(file_name) ->
          string.split(file_name, "/")
          |> list.last
          |> result.map(fn(l) { string.replace(l, ".vm", "") })
        Error(_) -> panic
      }
      io.debug(file_name)
      case file_name {
        Ok(file_name) -> {
          let file_name = file_name <> int.to_string(index)
          ["@SP", "AM=M-1", "D=M", "@" <> file_name, "M=D"]
        }
        Error(_) -> panic
      }
    }
    _ -> panic
  }
}

pub fn write_label(label: String) -> List(String) {
  todo
}

pub fn write_goto(label: String) -> List(String) {
  todo
}
