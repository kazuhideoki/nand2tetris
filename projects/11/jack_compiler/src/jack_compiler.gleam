// jack_compiler.gleam

import argv
import gleam/list
import gleam/result
import gleam/string
import parser
import simplifile
import symbol_table
import tokenizer

pub fn main() {
  // コマンドライン引数から入力ファイルを読み込む
  use raw_string <- result.try(argv.load().arguments |> parser.get_raw_string)

  // 入力文字列をトークンに分解する
  let tokens = tokenizer.tokenize(raw_string)

  // 新規シンボルテーブルを作成する
  let sym_table = symbol_table.new_symbol_table()

  // tokens を再帰的に処理してシンボルテーブル更新＆XML用文字列リストを生成
  let #(final_sym_table, xml_tokens) = process_tokens(tokens, sym_table)

  let xml = "<tokens>\n" <> string.join(xml_tokens, "\n") <> "\n</tokens>"

  // 出力先へ書き込む
  let _ = simplifile.write("output/Output.xml", xml)

  Ok(Nil)
}

/// トークン列を先頭から走査して、宣言箇所ならシンボルテーブル更新＆XML文字列を生成する
fn process_tokens(
  tokens: List(tokenizer.Token),
  sym_table: symbol_table.SymbolTable,
) -> #(symbol_table.SymbolTable, List(String)) {
  case tokens {
    [] -> #(sym_table, [])
    [token, ..rest] ->
      case token {
        // クラス変数宣言（static, field）の開始とする
        #(tokenizer.Keyword, "static") -> {
          let #(new_sym_table, xml_decl, remaining) =
            process_class_var_dec([token, ..rest], sym_table)
          let #(final_sym_table, xml_rest) =
            process_tokens(remaining, new_sym_table)
          #(final_sym_table, list.append(xml_decl, xml_rest))
        }
        #(tokenizer.Keyword, "field") -> {
          let #(new_sym_table, xml_decl, remaining) =
            process_class_var_dec([token, ..rest], sym_table)
          let #(final_sym_table, xml_rest) =
            process_tokens(remaining, new_sym_table)
          #(final_sym_table, list.append(xml_decl, xml_rest))
        }
        // サブルーチン宣言（constructor/function/method）の開始とする
        #(tokenizer.Keyword, "constructor")
        | #(tokenizer.Keyword, "function")
        | #(tokenizer.Keyword, "method") -> {
          let #(new_sym_table, xml_decl, remaining) =
            process_subroutine_dec([token, ..rest], sym_table)
          let #(final_sym_table, xml_rest) =
            process_tokens(remaining, new_sym_table)
          #(final_sym_table, list.append(xml_decl, xml_rest))
        }
        // ローカル変数宣言： var
        #(tokenizer.Keyword, "var") -> {
          let #(new_sym_table, xml_decl, remaining) =
            process_var_dec([token, ..rest], sym_table)
          let #(final_sym_table, xml_rest) =
            process_tokens(remaining, new_sym_table)
          #(final_sym_table, list.append(xml_decl, xml_rest))
        }
        // それ以外は「使用」としてそのままXML出力
        _ -> {
          let xml = tokenizer.add_xml_with_symbol(token, sym_table, False)
          let #(new_sym_table, xml_rest) = process_tokens(rest, sym_table)
          #(new_sym_table, list.append([xml], xml_rest))
        }
      }
  }
}

/// クラス変数宣言を処理する
/// パターン例: static int x ;
fn process_class_var_dec(
  tokens: List(tokenizer.Token),
  sym_table: symbol_table.SymbolTable,
) -> #(symbol_table.SymbolTable, List(String), List(tokenizer.Token)) {
  case tokens {
    [
      #(tokenizer.Keyword, kind),
      type_token,
      identifier_token,
      semicolon_token,
      ..rest
    ] -> {
      let symbol_kind = case kind {
        "static" -> symbol_table.Static
        "field" -> symbol_table.Field
        _ -> symbol_table.NoneKind
      }
      let new_sym_table =
        symbol_table.define(
          sym_table,
          identifier_token.1,
          type_token.1,
          symbol_kind,
        )
      let xmls = [
        tokenizer.add_xml_with_symbol(
          #(tokenizer.Keyword, kind),
          sym_table,
          False,
        ),
        tokenizer.add_xml_with_symbol(type_token, sym_table, False),
        // 宣言時は is_declaration = True とする
        tokenizer.add_xml_with_symbol(identifier_token, new_sym_table, True),
        tokenizer.add_xml_with_symbol(semicolon_token, sym_table, False),
      ]
      #(new_sym_table, xmls, rest)
    }
    _ -> #(sym_table, [], tokens)
  }
}

/// ローカル変数宣言を処理する
/// パターン例: var int y ;
fn process_var_dec(
  tokens: List(tokenizer.Token),
  sym_table: symbol_table.SymbolTable,
) -> #(symbol_table.SymbolTable, List(String), List(tokenizer.Token)) {
  case tokens {
    [
      #(tokenizer.Keyword, "var"),
      type_token,
      identifier_token,
      semicolon_token,
      ..rest
    ] -> {
      let new_sym_table =
        symbol_table.define(
          sym_table,
          identifier_token.1,
          type_token.1,
          symbol_table.Var,
        )
      let xmls = [
        tokenizer.add_xml_with_symbol(
          #(tokenizer.Keyword, "var"),
          sym_table,
          False,
        ),
        tokenizer.add_xml_with_symbol(type_token, sym_table, False),
        tokenizer.add_xml_with_symbol(identifier_token, new_sym_table, True),
        tokenizer.add_xml_with_symbol(semicolon_token, sym_table, False),
      ]
      #(new_sym_table, xmls, rest)
    }
    _ -> #(sym_table, [], tokens)
  }
}

/// サブルーチン宣言を処理する
/// 簡略化のため、パラメータが1つのみまたは空のパターンのみ扱う。
fn process_subroutine_dec(
  tokens: List(tokenizer.Token),
  sym_table: symbol_table.SymbolTable,
) -> #(symbol_table.SymbolTable, List(String), List(tokenizer.Token)) {
  case tokens {
    // サブルーチン宣言＋1つのパラメータ例：
    // (constructor|function|method) return_type subroutineName "(" type varName ")" ...
    [
      #(tokenizer.Keyword, "constructor"),
      return_type,
      subroutine_name,
      open_paren,
      type_token,
      identifier_token,
      close_paren,
      ..rest
    ]
    | [
        #(tokenizer.Keyword, "function"),
        return_type,
        subroutine_name,
        open_paren,
        type_token,
        identifier_token,
        close_paren,
        ..rest
      ]
    | [
        #(tokenizer.Keyword, "method"),
        return_type,
        subroutine_name,
        open_paren,
        type_token,
        identifier_token,
        close_paren,
        ..rest
      ] -> {
      // サブルーチン開始時にローカルスコープをリセット
      let sub_sym_table = symbol_table.start_subroutine(sym_table)
      let new_sym_table =
        symbol_table.define(
          sub_sym_table,
          identifier_token.1,
          type_token.1,
          symbol_table.Argument,
        )
      let sub_kw = case tokens {
        [#(tokenizer.Keyword, kw), ..] -> kw
        _ -> "unknown"
      }
      let xmls = [
        tokenizer.add_xml_with_symbol(
          #(tokenizer.Keyword, sub_kw),
          sym_table,
          False,
        ),
        tokenizer.add_xml_with_symbol(return_type, sym_table, False),
        tokenizer.add_xml_with_symbol(subroutine_name, sub_sym_table, True),
        tokenizer.add_xml_with_symbol(open_paren, sub_sym_table, False),
        tokenizer.add_xml_with_symbol(type_token, sub_sym_table, False),
        tokenizer.add_xml_with_symbol(identifier_token, new_sym_table, True),
        tokenizer.add_xml_with_symbol(close_paren, new_sym_table, False),
      ]
      #(new_sym_table, xmls, rest)
    }
    // パラメータがない場合：
    // (constructor|function|method) return_type subroutineName "(" ")" ...
    [
      #(tokenizer.Keyword, "constructor"),
      return_type,
      subroutine_name,
      open_paren,
      close_paren,
      ..rest
    ]
    | [
        #(tokenizer.Keyword, "function"),
        return_type,
        subroutine_name,
        open_paren,
        close_paren,
        ..rest
      ]
    | [
        #(tokenizer.Keyword, "method"),
        return_type,
        subroutine_name,
        open_paren,
        close_paren,
        ..rest
      ] -> {
      let sub_sym_table = symbol_table.start_subroutine(sym_table)
      let sub_kw = case tokens {
        [#(tokenizer.Keyword, kw), ..] -> kw
        _ -> "unknown"
      }
      let xmls = [
        tokenizer.add_xml_with_symbol(
          #(tokenizer.Keyword, sub_kw),
          sym_table,
          False,
        ),
        tokenizer.add_xml_with_symbol(return_type, sym_table, False),
        tokenizer.add_xml_with_symbol(subroutine_name, sub_sym_table, True),
        tokenizer.add_xml_with_symbol(open_paren, sub_sym_table, False),
        tokenizer.add_xml_with_symbol(close_paren, sub_sym_table, False),
      ]
      #(sub_sym_table, xmls, rest)
    }
    _ -> #(sym_table, [], tokens)
  }
}
