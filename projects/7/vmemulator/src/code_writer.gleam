//// このモジュールは、P a r s e r によって解析されたVMコードをH a c k アセンブリ コードへと変換する

import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import parser.{type CommandType, CArithmetic, CPop, CPush, Constant}
import segment_store.{type SegmentStore}

pub fn generate_first_lines(segment_store: SegmentStore) -> List(String) {
  let option_sp = segment_store.get(segment_store, "SP")
  case option_sp {
    Some(sp) -> {
      // SP の初期化
      ["@" <> int.to_string(sp), "D=A", "@SP", "M=D"]
    }
    None -> panic
  }
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
pub fn write_push_pop(
  command_type: CommandType,
  segment_store: SegmentStore,
) -> List(String) {
  case command_type {
    CPush(segment, index) -> {
      let segment_code = generate_by_segment(segment, index, segment_store)
      case segment {
        Constant ->
          segment_code
          |> list.append(["@SP", "A=M", "M=D", "@SP", "M=M+1"])
        _ -> panic
        // 必要な実装を追加
      }
    }
    CPop(segment, index) -> {
      let segment_code = generate_by_segment(segment, index, segment_store)
      // 🔶 TODO 不完全なので修正
      case segment {
        Constant ->
          segment_code |> list.append(["@SP", "A=M", "M=D", "@SP", "M=M-1"])
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

/// 🔶 TODO constant 意外にも対応する
/// constant(現状)に加え、local, argument, this, that, temp
fn generate_by_segment(
  segment: parser.Segment,
  index: Int,
  segment_store: SegmentStore,
) -> List(String) {
  case segment {
    Constant -> ["@" <> int.to_string(index), "D=A"]
    _ -> panic
  }
}
