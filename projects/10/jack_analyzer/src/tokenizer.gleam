import gleam/list
import gleam/string

pub type TokenType {
  Keyword(String)
  Symbol(String)
  IntConst(Int)
  StringConst(String)
  Identifier(String)
}

const keywords = [
  "class", "method", "function", "constructor", "int", "boolean", "char", "void",
  "var", "static", "field", "let", "do", "if", "else", "while", "return", "true",
  "false", "null", "this",
]

const symbols = [
  "{", "}", "(", ")", "[", "]", ".", ",", ";", "+", "-", "*", "/", "&", "|", "<",
  ">", "=", "~",
]

/// "//" 1行コメント, "/**" or "/*" 複数行コメント中であるかどうか
type TokenizerState {
  State(
    in_single_line_comment: Bool,
    in_double_line_comment: Bool,
    in_literal: Bool,
  )
}

// 新設計
// 0. 状態保持 [SLコメント, MLコメント]
// 1. 1文字づつ検証。creating_token に追加
// 2. creating_token を token として成り立ったかどうか確認
//  -> 成り立ったら結果 tokens に格納, creating_token をリセットして次の文字へ
//  -> 成り立たなければ 次の文字へ
// 3. 1~2 を繰り返す。文字がなくなったら終わり

fn parse(raw_string: String) {
  let chars = string.to_graphemes(raw_string)
  let initial_state =
    State(
      in_single_line_comment: False,
      in_double_line_comment: False,
      in_literal: False,
    )
}

// token の作成は？

/// 1文字を扱う
fn handle_char(
  char: String,
  // single_comment, doudle_comment, literal
  state: #(Bool, Bool, Bool),
  // token として格納される char, next token, state
) -> #(String, Bool, #(Bool, Bool, Bool)) {
  case state {
    // `//` のコメント中
    #(True, d, l) -> {
      let finished = case char {
        "\n" -> True
        _ -> False
      }

      #("", False, #(!finished, d, l))

      todo
    }
    #(_, True, _) -> {
      todo
    }
    #(_, _, True) -> {
      todo
    }
    _ -> {
      todo
    }
  }
}
