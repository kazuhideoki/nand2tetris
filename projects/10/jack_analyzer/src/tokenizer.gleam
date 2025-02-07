import gleam/int
import gleam/string

type TokenType {
  Keyword(KeyWord)
  Symbol(String)
  IntConst(Int)
  StringConst(String)
  Identifier(String)
}

type KeyWord {
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

// コメント除去 -> トークンパース を繰り返す
fn parse() {
  todo
}

fn remove_head_comment_and_space(str: String) -> String {
  todo
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
            [str, _] -> StringConst(str)
            _ -> panic
          }
        }
        _ -> Identifier(str)
      }
  }
}
