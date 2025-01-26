//// このモジュールは、P a r s e r によって解析されたVMコードをH a c k アセンブリ コードへと変換する

import gleam/int
import gleam/io
import gleam/list

import parser.{
  type CommandType, type Segment, Argument, CArithmetic, CPop, CPush, Constant,
  Local, Temp, That, This,
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
  command_type: CommandType,
  label_counter: Int,
) -> #(List(String), Int) {
  case command_type {
    CArithmetic(value) ->
      case value {
        // ポインタ取得 -> スタック最上段の値取得 -> Dに格納 -> スタックのもう一段下の値取得 -> Dを加算して同じ位置に格納
        "add" -> #(
          ["@SP", "AM=M-1", "D=M", "A=A-1", "M=M+D"],
          label_counter + 1,
        )
        "sub" -> #(
          ["@SP", "AM=M-1", "D=M", "A=A-1", "M=M-D"],
          label_counter + 1,
        )
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
    _ -> panic
  }
}

/// pushまたはpopの command に対応するアセンブリコードを出力ファイルに書き込む。
pub fn write_push_pop(command_type: CommandType) -> List(String) {
  case command_type {
    CPush(segment, index) -> {
      let #(segment_code, _) = generate_by_segment(segment, index)
      segment_code
      // SP のインクリメント
      |> list.append(["@SP", "A=M", "M=D", "@SP", "M=M+1"])
    }
    CPop(segment, index) -> {
      let #(segment_code, simbol) = generate_by_segment(segment, index)
      segment_code
      // セグメントに値を格納
      |> list.append(["@" <> simbol, "M=D"])
      // SP のデクリメント
      |> list.append(["@SP", "A=M", "M=D", "@SP", "M=M-1"])
    }
    _ -> {
      io.println_error("not implemented")
      panic
    }
  }
}

/// セグメントの値を取得するアセンブリ + セグメントのシンボルを返す
fn generate_by_segment(segment: Segment, index: Int) -> #(List(String), String) {
  case segment {
    Constant -> #(["@" <> int.to_string(index), "D=A"], int.to_string(index))
    Local -> #(["@LCL", "D=M"], "LCL")
    Argument -> #(["@ARG", "D=M"], "ARG")
    This -> #(["@THIS", "D=M"], "THIS")
    That -> #(["@THAT", "D=M"], "THAT")
    Temp -> #(["@TEMP", "D=M"], "TEMP")
    _ -> panic
  }
}
