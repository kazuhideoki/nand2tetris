import gleam/int
import gleam/io
import gleam/list
import gleam/string

pub type TokenType {
  Keyword(KeyWord)
  Symbol(String)
  IntConst(Int)
  StringConst(String)
  Identifier(String)
}

pub type KeyWord {
  Class
  Method
  Function
  Constructor
  Int
  Boolean
  Char
  Void
  Var
  Static
  Field
  Let
  Do
  If
  Else
  While
  Return
  True
  False
  Null
  This
}

// TODO 現実装だと
// - "main()" みたいになる。
// - ; , なども分離できない
// -> つまり、identifier で symbol がくっついてても判別できてない

// コメント除去 -> トークンパース を繰り返す
pub fn parse(raw_string: String) -> List(TokenType) {
  let raw_tokens = generate_raw_tokens(raw_string)
  io.debug(raw_tokens)
  raw_tokens |> list.map(parse_one_token)
}

// 再起的に remove_comment_and_space を適用し、トークンのリストを生成する
fn generate_raw_tokens(raw_string: String) -> List(String) {
  case raw_string {
    "" -> []
    _ -> {
      case remove_comment_and_space(raw_string) |> string.split(" ") {
        [token, ..rest] ->
          rest
          |> string.join(" ")
          |> generate_raw_tokens
          |> list.prepend(string.trim(token))
        _ -> panic
      }
    }
  }
}

// /＊から＊／までのコメント
// /**から＊／までのAPIコメント
// 行末までの／／コメント
fn remove_comment_and_space(str: String) -> String {
  case string.trim(str) {
    "//" <> rest -> {
      case string.split(rest, "\n") {
        [_, ..next] -> {
          next |> string.join("\n") |> string.trim |> remove_comment_and_space
        }
        _ -> panic
      }
    }
    "/**" <> rest -> {
      case string.split(rest, "*/") {
        [_, ..next] ->
          next |> string.join("\n") |> string.trim |> remove_comment_and_space
        _ -> panic
      }
    }
    "/*" <> rest -> {
      case string.split(rest, "*/") {
        [_, ..next] ->
          next |> string.join("\n") |> string.trim |> remove_comment_and_space
        _ -> panic
      }
    }
    _ -> str |> string.trim
  }
}

/// 1つのトークンをパースする
fn parse_one_token(str: String) {
  case int.parse(str) {
    Ok(int) -> IntConst(int)
    Error(_) ->
      case str {
        "class" -> Keyword(Class)
        "method" -> Keyword(Method)
        "function" -> Keyword(Function)
        "constructor" -> Keyword(Constructor)
        "int" -> Keyword(Int)
        "boolean" -> Keyword(Boolean)
        "char" -> Keyword(Char)
        "void" -> Keyword(Void)
        "var" -> Keyword(Var)
        "static" -> Keyword(Static)
        "field" -> Keyword(Field)
        "let" -> Keyword(Let)
        "do" -> Keyword(Do)
        "if" -> Keyword(If)
        "else" -> Keyword(Else)
        "while" -> Keyword(While)
        "return" -> Keyword(Return)
        "true" -> Keyword(True)
        "false" -> Keyword(False)
        "null" -> Keyword(Null)
        "this" -> Keyword(This)
        "{" -> Symbol("{")
        "}" -> Symbol("}")
        "(" -> Symbol("(")
        ")" -> Symbol(")")
        "[" -> Symbol("[")
        "]" -> Symbol("]")
        "." -> Symbol(".")
        "," -> Symbol(",")
        ";" -> Symbol(";")
        "+" -> Symbol("+")
        "-" -> Symbol("-")
        "*" -> Symbol("*")
        "/" -> Symbol("/")
        "&" -> Symbol("&")
        "|" -> Symbol("|")
        "<" -> Symbol("<")
        ">" -> Symbol(">")
        "=" -> Symbol("=")
        "~" -> Symbol("~")
        "\"" <> rest -> {
          case string.split(rest, "\"") {
            [str, ..] -> StringConst(str)
            _ -> panic
          }
        }
        _ -> Identifier(str)
      }
  }
}

pub fn add_xml(token: TokenType) -> String {
  case token {
    Keyword(keyword) -> {
      case keyword {
        Class -> "class"
        Method -> "method"
        Function -> "function"
        Constructor -> "constructor"
        Int -> "int"
        Boolean -> "boolean"
        Char -> "char"
        Void -> "void"
        Var -> "var"
        Static -> "static"
        Field -> "field"
        Let -> "let"
        Do -> "do"
        If -> "if"
        Else -> "else"
        While -> "while"
        Return -> "return"
        True -> "true"
        False -> "false"
        Null -> "null"
        This -> "this"
      }
      |> add_bracket("keyword")
    }
    Symbol(str) -> str |> add_bracket("symbol")
    IntConst(num) -> num |> int.to_string |> add_bracket("integerConstant")
    StringConst(str) -> str |> add_bracket("stringConstant")
    Identifier(str) -> str |> add_bracket("identifier")
  }
}

fn add_bracket(str: String, token_type_str: String) {
  "<" <> token_type_str <> "> " <> str <> " </" <> token_type_str <> ">"
}
