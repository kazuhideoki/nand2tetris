import gleam/int
import gleam/list
import gleam/string

/// 状態の種類を表す列挙型
pub type State {
  /// 文字列リテラル状態: " の間はそのまま蓄積
  InString
  /// インラインコメントに入っている状態
  InLineComment
  /// ブロックコメントに入っている状態
  InBlockComment
  /// 文字列やコメント以外の状態
  Normal
}

pub type TokenKind {
  Keyword
  Symbol
  Identifier
  IntegerConstant
  StringConstant
}

/// Token の種類とトークン文字列
pub type Token =
  #(TokenKind, String)

pub fn tokenize(input: String) -> List(Token) {
  let chars = string.to_graphemes(input)
  tokenize_loop(chars, "", [], Normal)
}

fn tokenize_loop(
  chars: List(String),
  current: String,
  tokens: List(Token),
  state: State,
) -> List(Token) {
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
        // 終了のサイン
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
        // 終了のサイン
        "\r\n" | "\n" | "\r" -> tokenize_loop(rest, "", tokens, Normal)
        _ -> tokenize_loop(rest, current, tokens, InLineComment)
      }

    // ブロックコメント状態: "*/" が現れるまで読み飛ばす
    ["*", "/", ..rest], InBlockComment ->
      tokenize_loop(rest, "", tokens, Normal)
    [_, ..rest2], InBlockComment ->
      tokenize_loop(rest2, current, tokens, InBlockComment)

    // Normal 状態
    chars, Normal ->
      case chars {
        // "/" で始まる場合：次の文字でコメントかどうか判定
        ["/", next, ..rest] ->
          case next {
            "/" -> {
              let new_tokens = flush(current, tokens)
              tokenize_loop(rest, "", new_tokens, InLineComment)
            }
            "*" -> {
              let new_tokens = flush(current, tokens)
              tokenize_loop(rest, "", new_tokens, InBlockComment)
            }
            _ -> {
              // `/` のみは除算
              let new_tokens =
                list.append(flush(current, tokens), [#(Symbol, "/")])
              tokenize_loop(list.prepend(rest, next), "", new_tokens, Normal)
            }
          }

        // `\"` で、文字列リテラルに入る。
        ["\"", ..rest] -> {
          {
            let new_tokens = flush(current, tokens)
            tokenize_loop(rest, "", new_tokens, InString)
          }
        }

        [char, ..rest] ->
          case is_whitespace(char), is_symbol(char) {
            // 空白であれば Normal で進める
            True, _ -> {
              let new_tokens = flush(current, tokens)
              tokenize_loop(rest, "", new_tokens, Normal)
            }
            // 現在のバッファに文字列が蓄積されている場合、まず flush でその文字列をトークン化し（new_tokens）、
            // 次にシンボル自体（char）をトークンとして追加することで、両者を別々のトークンとして正しい順序で保持する。
            _, True -> {
              let new_tokens = flush(current, tokens)
              let new_tokens2 = list.append(new_tokens, [#(Symbol, char)])
              tokenize_loop(rest, "", new_tokens2, Normal)
            }
            // いずれにも該当しない場合、現在生成中のトークンに追加する
            False, False -> tokenize_loop(rest, current <> char, tokens, Normal)
          }
        [] -> tokens
      }
  }
}

/// 現在のバッファが空白のみなら何も追加せず、そうでなければ classify_token でトークン化
fn flush(current: String, tokens: List(Token)) -> List(Token) {
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
  [
    "{", "}", "(", ")", "[", "]", ".", ",", ";", "+", "-", "*", "/", "&", "|",
    "<", ">", "=", "~",
  ]
  |> list.contains(char)
}

/// トークン文字列から種類を判定する
pub fn classify_token(token: String) -> Token {
  let trimmed = string.trim(token)
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

fn is_integer(token: String) -> Bool {
  case int.parse(token) {
    Ok(_) -> True
    Error(_) -> False
  }
}

/// 各トークンを適切な XML タグで包む
pub fn add_xml(token: Token) -> String {
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
