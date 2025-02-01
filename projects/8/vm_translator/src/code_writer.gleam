//// このモジュールは、P a r s e r によって解析されたVMコードをH a c k アセンブリ コードへと変換する

import argv
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string

import parser.{
  type Segment, Argument, Constant, Local, Pointer, Static, Temp, That, This,
}

pub fn generate_first_lines() -> List(String) {
  [
    // "@256", "D=A", "@SP", "M=D", "@300", "D=A", "@LCL", "M=D", "@400", "D=A",
  // "@ARG", "M=D", "@3000", "D=A", "@THIS", "M=D", "@3010", "D=A", "@THAT",
  // "M=D",
  // "@3", "D=A", "@400", "M=D" // BasicLoop で使う
  // "@6", "D=A", "@400", "M=D", "@3000", "D=A", "@401", "M=D", // FibonacciSeries で使う argument[0]と[1]に初期値を入れる
  // for SimpleFunction
  // "@317", "D=A", "@SP", "M=D", "@317", "D=A", "@LCL", "M=D", "@310", "D=A",
  // "@ARG", "M=D", "@3000", "D=A", "@THIS", "M=D", "@4000", "D=A", "@THAT",
  // "M=D", "@1234", "D=A", "@310", "M=D", "@37", "D=A", "@311", "M=D", "@1000",
  // "D=A", "@312", "M=D", "@305", "D=A", "@313", "M=D", "@300", "D=A", "@314",
  // "M=D", "@3010", "D=A", "@315", "M=D", "@4010", "D=A", "@316", "M=D",
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
    Temp -> ["@" <> int.to_string(5 + index), "D=M"]
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
      "@" <> int.to_string(5 + index),
      "D=A",
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
  io.debug(label)
  ["(" <> label <> ")"]
}

pub fn write_goto(label: String) -> List(String) {
  ["@" <> label, "0;JMP"]
}

/// 条件付き goto
pub fn write_if(label: String) -> List(String) {
  // pop する
  // false(0) でなければ label の位置から実行を継続 (0 以外なら true)
  ["@SP", "AM=M-1", "D=M", "@" <> label, "D;JNE"]
}

// (f)                  // 関数の開始ラベルをコードに挿入する
// repeat nVars times:  // nVars = ローカル変数の数
//   push 0             // ローカル変数を0で初期化する
pub fn write_function(name: String, num_vars: Int) {
  let function_label = ["(" <> name <> ")"]

  let init_local_vars =
    list.range(0, num_vars - 1)
    |> list.map(fn(index) {
      ["@LCL", "D=M", "@" <> int.to_string(index), "A=D+A", "D=0"]
    })
    |> list.flatten

  function_label |> list.append(init_local_vars)
}

// push returnAddress   // ラベルを生成し、スタックにpushする
// push LCL             // 関数の呼び出し側のLCLを保存する
// push ARG             // 関数の呼び出し側のARGを保存する
// push THIS            // 関数の呼び出し側のTHISを保存する
// push THAT            // 関数の呼び出し側のTHATを保存する
// ARG = SP - 5 - nArgs // ARGを変更する
// LCL = SP             // LCLを変更する
// goto f               // 呼び出される側へ制御を移す
// (returnAddress)      // returnアドレスラベルをコードに挿入する
pub fn write_call(function_name: String, num_args: Int) {
  // 本当はもっと厳密にした方がいいが、簡易的に乱数生成して一意なラベルを生成している
  let prefix = int.random(1_000_000) |> int.to_string
  let return_address_label = prefix <> ".returnAddress"
  ["@" <> return_address_label, "D=A", "@SP", "A=M", "M=D", "@SP", "M=M+1"]
  // LCL の値をスタックに push
  |> list.append(["@LCL", "D=M", "@SP", "A=M", "M=D", "@SP", "M=M+1"])
  // ARG の値をスタックに push
  |> list.append(["@ARG", "D=M", "@SP", "A=M", "M=D", "@SP", "M=M+1"])
  // THIS の値をスタックに push
  |> list.append(["@THIS", "D=M", "@SP", "A=M", "M=D", "@SP", "M=M+1"])
  // THAT の値をスタックに push
  |> list.append(["@THAT", "D=M", "@SP", "A=M", "M=D", "@SP", "M=M+1"])
  // ARG を変更
  |> list.append([
    "@SP",
    "D=M",
    "@5",
    "D=D-A",
    "@" <> int.to_string(num_args),
    "D=D-A",
    "@ARG",
    "M=D",
  ])
  // LCL を変更
  |> list.append(["@SP", "D=M", "@LCL", "M=D"])
  // 関数の開始位置へジャンプ
  |> list.append(["@" <> function_name, "0;JMP"])
  // returnAddress ラベルを挿入
  |> list.append(["(" <> return_address_label <> ")"])
}

// frame = LCL            // frameは一時変数
// retAddr = *(frame-5)   // returnアドレスを一時変数に入れる
// *ARG = pop()           // 呼び出し側の戻り値の場所に移す
// SP = ARG + 1           // 呼び出し側のSPを別の場所に移す
// THAT = *(frame-1)      // 呼び出し側のTHATを復元する
// THIS = *(frame-2)      // 呼び出し側のTHISを復元する
// ARG = *(frame-3)       // 呼び出し側のARGを復元する
// LCL = *(frame-4)       // 呼び出し側のLCLを復元する
// goto retAddr           // returnアドレスへ移動する
pub fn write_return() {
  // LCL の値を (FRAME) として R13 に保存, return address を R14 に保存
  ["@LCL", "D=M", "@R13", "M=D", "@5", "A=D-A", "D=M", "@R14", "M=D"]
  |> list.append([
    // 返り値を ARG に格納
    "@SP", "AM=M-1", "D=M", "@ARG", "A=M", "M=D", "D=A+1", "@SP", "M=D",
  ])
  |> list.append([
    // THAT, THIS を復元
    "@R13", "AM=M-1", "D=M", "@THAT", "M=D", "@R13", "AM=M-1", "D=M", "@THIS",
    "M=D",
  ])
  |> list.append([
    // ARG, LCL を復元
    "@R13", "AM=M-1", "D=M", "@ARG", "M=D", "@R13", "AM=M-1", "D=M", "@LCL",
    "M=D",
  ])
  // return address へジャンプ
  |> list.append(["@R14", "A=M", "0;JMP"])
}
