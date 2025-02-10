import gleam/list
import gleam/string

pub type State {
  Normal
  InString
  InLineComment
  InBlockComment
}

pub fn tokenize(input: String) -> List(String) {
  let chars = string.to_graphemes(input)
  tokenize_loop(chars, "", [], Normal)
}

fn tokenize_loop(
  chars: List(String),
  current: String,
  tokens: List(String),
  state: State,
) -> List(String) {
  case chars, state {
    // 入力がなくなったとき
    [], Normal ->
      case current {
        "" -> tokens
        _ -> list.append(tokens, [current])
      }
    [], InString ->
      // 終了していない文字列リテラルはそのままトークンにする
      list.append(tokens, [current])
    [], InLineComment -> tokens
    [], InBlockComment -> tokens

    // 文字列リテラル状態: " の間はすべてそのまま蓄積
    [char, ..rest], InString ->
      case char {
        "\"" -> tokenize_loop(rest, "", list.append(tokens, [current]), Normal)
        _ -> tokenize_loop(rest, current <> char, tokens, InString)
      }

    // 行コメント状態: 改行まで読み飛ばす
    [char, ..rest], InLineComment ->
      case char {
        "\n" -> tokenize_loop(rest, "", tokens, Normal)
        _ -> tokenize_loop(rest, current, tokens, InLineComment)
      }

    // ブロックコメント状態: "*/" が現れるまで読み飛ばす
    ["*", "/", ..rest2], InBlockComment ->
      tokenize_loop(rest2, "", tokens, Normal)
    [_, ..rest2], InBlockComment ->
      tokenize_loop(rest2, current, tokens, InBlockComment)

    // Normal 状態
    chars, Normal ->
      case chars {
        // "/" で始まる場合：次の文字でコメントか判定する
        ["/", next, ..rest2] ->
          case next {
            "/" -> {
              let new_tokens = case current {
                "" -> tokens
                _ -> list.append(tokens, [current])
              }
              tokenize_loop(rest2, "", new_tokens, InLineComment)
            }
            "*" -> {
              let new_tokens = case current {
                "" -> tokens
                _ -> list.append(tokens, [current])
              }
              tokenize_loop(rest2, "", new_tokens, InBlockComment)
            }
            _ -> {
              // コメント開始でなければ "/" を記号として扱う
              let new_tokens = case current {
                "" -> list.append(tokens, ["/"])
                _ -> list.append(tokens, [current, "/"])
              }
              tokenize_loop(list.prepend(rest2, next), "", new_tokens, Normal)
            }
          }

        // 通常の1文字処理
        [char, ..rest] ->
          case char == "\"" {
            True -> {
              // 文字列リテラルの開始
              let new_tokens = case current {
                "" -> tokens
                _ -> list.append(tokens, [current])
              }
              tokenize_loop(rest, "", new_tokens, InString)
            }
            False ->
              case is_whitespace(char) {
                True -> {
                  // 空白なら現在のバッファを確定
                  let new_tokens = case current {
                    "" -> tokens
                    _ -> list.append(tokens, [current])
                  }
                  tokenize_loop(rest, "", new_tokens, Normal)
                }
                False ->
                  case is_symbol(char) {
                    True -> {
                      // 記号なら、現在のバッファがあれば確定して記号を追加
                      let new_tokens = case current {
                        "" -> list.append(tokens, [char])
                        _ -> list.append(tokens, [current, char])
                      }
                      tokenize_loop(rest, "", new_tokens, Normal)
                    }
                    False -> {
                      // 通常文字はバッファに追加
                      tokenize_loop(rest, current <> char, tokens, Normal)
                    }
                  }
              }
          }
        [] -> tokens
      }
  }
}

fn is_whitespace(char: String) -> Bool {
  char == " " || char == "\n" || char == "\t"
}

fn is_symbol(char: String) -> Bool {
  case char {
    "{"
    | "}"
    | "("
    | ")"
    | "["
    | "]"
    | "."
    | ","
    | ";"
    | "+"
    | "-"
    | "*"
    | "/"
    | "&"
    | "|"
    | "<"
    | ">"
    | "="
    | "~" -> True
    _ -> False
  }
}

/// とりあえず全トークンを <token> タグで包む（本来は種類別に分ける）
pub fn add_xml(token: String) -> String {
  "<token>" <> token <> "</token>"
}
