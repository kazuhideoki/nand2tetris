import gleam/int
import gleam/io
import gleam/list
import gleam/string

pub type State {
  Normal
  InString
  InLineComment
  InBlockComment
}

pub type TokenKind {
  Keyword
  Symbol
  Identifier
  IntegerConstant
  StringConstant
}

pub type TokenI =
  #(TokenKind, String)

pub fn tokenize(input: String) -> List(TokenI) {
  let chars = string.to_graphemes(input)
  tokenize_loop(chars, "", [], Normal)
}

fn tokenize_loop(
  chars: List(String),
  current: String,
  tokens: List(TokenI),
  state: State,
) -> List(TokenI) {
  case chars, state {
    // 入力がなくなったとき
    [], Normal -> flush(current, tokens)
    [], InString ->
      // 終了していない文字列リテラルはそのままトークンにする
      list.append(tokens, [#(StringConstant, current)])
    [], InLineComment -> tokens
    [], InBlockComment -> tokens

    // 文字列リテラル状態: " の間はそのまま蓄積
    [char, ..rest], InString ->
      case char {
        "\"" ->
          tokenize_loop(
            rest,
            "",
            list.append(tokens, [#(StringConstant, current)]),
            Normal,
          )
        _ -> tokenize_loop(rest, current <> char, tokens, InString)
      }

    // 行コメント状態: 改行まで読み飛ばす
    [char, ..rest], InLineComment ->
      case char {
        "\r\n" -> tokenize_loop(rest, "", tokens, Normal)
        "\n" -> tokenize_loop(rest, "", tokens, Normal)
        "\r" -> tokenize_loop(rest, "", tokens, Normal)
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
        // "/" で始まる場合：次の文字でコメントかどうか判定
        ["/", next, ..rest2] ->
          case next {
            "/" -> {
              let new_tokens = flush(current, tokens)
              tokenize_loop(rest2, "", new_tokens, InLineComment)
            }
            "*" -> {
              let new_tokens = flush(current, tokens)
              tokenize_loop(rest2, "", new_tokens, InBlockComment)
            }
            _ -> {
              let new_tokens = case string.trim(current) {
                "" -> list.append(tokens, [#(Symbol, "/")])
                _ -> list.append(flush(current, tokens), [#(Symbol, "/")])
              }
              tokenize_loop(list.prepend(rest2, next), "", new_tokens, Normal)
            }
          }

        [char, ..rest] ->
          case char {
            "\"" -> {
              case string.trim(current) {
                "" -> tokenize_loop(rest, "", tokens, InString)
                _ -> {
                  let new_tokens = flush(current, tokens)
                  tokenize_loop(rest, "", new_tokens, InString)
                }
              }
            }
            c ->
              case is_whitespace(c) {
                True ->
                  case string.trim(current) {
                    "" -> tokenize_loop(rest, "", tokens, Normal)
                    _ -> {
                      let new_tokens = flush(current, tokens)
                      tokenize_loop(rest, "", new_tokens, Normal)
                    }
                  }
                False ->
                  case is_symbol(c) {
                    True ->
                      case string.trim(current) {
                        "" -> {
                          let new_tokens = list.append(tokens, [#(Symbol, c)])
                          tokenize_loop(rest, "", new_tokens, Normal)
                        }
                        _ -> {
                          let new_tokens = flush(current, tokens)
                          let new_tokens2 =
                            list.append(new_tokens, [#(Symbol, c)])
                          tokenize_loop(rest, "", new_tokens2, Normal)
                        }
                      }
                    False -> tokenize_loop(rest, current <> c, tokens, Normal)
                  }
              }
          }
        [] -> tokens
      }
  }
}

/// flush: 現在のバッファが空白のみなら何も追加せず、そうでなければ classify_token でトークン化
fn flush(current: String, tokens: List(TokenI)) -> List(TokenI) {
  let trimmed = string.trim(current)
  case trimmed {
    "" -> tokens
    _ -> list.append(tokens, [classify_token(trimmed)])
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

/// トークン文字列から種類を判定する
pub fn classify_token(token: String) -> TokenI {
  let trimmed = string.trim(token)
  case trimmed {
    "" -> #(Identifier, "")
    // 本来ここは呼ばれないはず
    _ -> {
      let keywords = [
        "class", "constructor", "function", "method", "field", "static", "var",
        "int", "char", "boolean", "void", "true", "false", "null", "this", "let",
        "do", "if", "else", "while", "return",
      ]
      case list.contains(keywords, trimmed) {
        True -> #(Keyword, trimmed)
        False ->
          case is_integer(trimmed) {
            True -> #(IntegerConstant, trimmed)
            False -> #(Identifier, trimmed)
          }
      }
    }
  }
}

fn is_integer(token: String) -> Bool {
  case int.parse(token) {
    Ok(_) -> True
    Error(_) -> False
  }
}

/// 各トークンを適切な XML タグで包む
pub fn add_xml(token: TokenI) -> String {
  let tag = case token.0 {
    Keyword -> "keyword"
    Symbol -> "symbol"
    Identifier -> "identifier"
    IntegerConstant -> "integerConstant"
    StringConstant -> "stringConstant"
  }
  let value = case token.0 {
    Symbol -> escape_xml(token.1)
    _ -> token.1
  }
  "<" <> tag <> "> " <> value <> " </" <> tag <> ">"
}

fn escape_xml(s: String) -> String {
  case s {
    "<" -> "&lt;"
    ">" -> "&gt;"
    "&" -> "&amp;"
    _ -> s
  }
}
