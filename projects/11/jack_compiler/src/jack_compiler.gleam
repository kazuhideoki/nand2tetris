// jack_compiler.gleam

import argv
import files
import gleam/list
import gleam/result
import gleam/string
import simplifile
import symbol_table
import tokenizer

pub fn main() {
  let args = argv.load().arguments
  case args {
    [path, ..] -> {
      // Phase 1: 対象ファイルの収集と出力先ディレクトリの作成
      let assert Ok(#(output_dir, files)) = files.gather_files(path)
      // Phase 2: 各ファイルを順次コンパイル
      list.each(files, fn(file) { compile_file(file, output_dir) })
      Ok(Nil)
    }
    _ -> Ok(Nil)
  }
}

/// 単一の jack ファイルをコンパイルして、
/// output_dir/<basename>.xml に出力する
fn compile_file(path: String, output_dir: String) -> Result(Nil, Nil) {
  use raw_string <- result.try(files.get_raw_string(path))
  let tokens = tokenizer.tokenize(raw_string)
  let sym_table = symbol_table.new_symbol_table()
  let #(_, xml_tokens) = process_tokens(tokens, sym_table)
  let xml = "<tokens>\n" <> string.join(xml_tokens, "\n") <> "\n</tokens>"
  let file_basename = files.basename(path)
  let output_file =
    output_dir <> "/" <> files.replace_extension(file_basename, ".xml")
  let _ = simplifile.write(output_file, xml)
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
        #(tokenizer.Keyword, "static") | #(tokenizer.Keyword, "field") -> {
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
/// パターン例: static int x, y ;
fn process_class_var_dec(
  tokens: List(tokenizer.Token),
  sym_table: symbol_table.SymbolTable,
) -> #(symbol_table.SymbolTable, List(String), List(tokenizer.Token)) {
  // 最初は「static」または「field」、型、最初の識別子が出現する
  case tokens {
    [#(tokenizer.Keyword, kind), type_token, identifier_token, ..rest] -> {
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
        tokenizer.add_xml_with_symbol(identifier_token, new_sym_table, True),
      ]
      // カンマ区切りの追加識別子およびセミコロンまで処理するローカル関数

      process_rest1(type_token, symbol_kind, rest, new_sym_table, xmls)
    }
    _ -> #(sym_table, [], tokens)
  }
}

fn process_rest1(
  type_token: tokenizer.Token,
  symbol_kind: symbol_table.Kind,
  tokens: List(tokenizer.Token),
  table: symbol_table.SymbolTable,
  acc: List(String),
) -> #(symbol_table.SymbolTable, List(String), List(tokenizer.Token)) {
  case tokens {
    [#(tokenizer.Symbol, ","), next_id, ..more] -> {
      let new_table =
        symbol_table.define(table, next_id.1, type_token.1, symbol_kind)
      let acc2 =
        list.append(acc, [
          tokenizer.add_xml_with_symbol(#(tokenizer.Symbol, ","), table, False),
          tokenizer.add_xml_with_symbol(next_id, new_table, True),
        ])
      process_rest1(type_token, symbol_kind, more, new_table, acc2)
    }
    [#(tokenizer.Symbol, ";"), ..more] -> {
      let acc2 =
        list.append(acc, [
          tokenizer.add_xml_with_symbol(#(tokenizer.Symbol, ";"), table, False),
        ])
      #(table, acc2, more)
    }
    _ -> #(table, acc, tokens)
  }
}

/// ローカル変数宣言を処理する
/// パターン例: var int y, z ;
fn process_var_dec(
  tokens: List(tokenizer.Token),
  sym_table: symbol_table.SymbolTable,
) -> #(symbol_table.SymbolTable, List(String), List(tokenizer.Token)) {
  case tokens {
    [#(tokenizer.Keyword, "var"), type_token, identifier_token, ..rest] -> {
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
      ]

      process_rest2(type_token, rest, new_sym_table, xmls)
    }
    _ -> #(sym_table, [], tokens)
  }
}

fn process_rest2(
  type_token: tokenizer.Token,
  tokens: List(tokenizer.Token),
  table: symbol_table.SymbolTable,
  acc: List(String),
) -> #(symbol_table.SymbolTable, List(String), List(tokenizer.Token)) {
  case tokens {
    [#(tokenizer.Symbol, ","), next_id, ..more] -> {
      let new_table =
        symbol_table.define(table, next_id.1, type_token.1, symbol_table.Var)
      let acc2 =
        list.append(acc, [
          tokenizer.add_xml_with_symbol(#(tokenizer.Symbol, ","), table, False),
          tokenizer.add_xml_with_symbol(next_id, new_table, True),
        ])
      process_rest2(type_token, more, new_table, acc2)
    }
    [#(tokenizer.Symbol, ";"), ..more] -> {
      let acc2 =
        list.append(acc, [
          tokenizer.add_xml_with_symbol(#(tokenizer.Symbol, ";"), table, False),
        ])
      #(table, acc2, more)
    }
    _ -> #(table, acc, tokens)
  }
}

/// サブルーチン宣言を処理する
/// パラメータリストが0個以上の場合に対応するように修正
fn process_subroutine_dec(
  tokens: List(tokenizer.Token),
  sym_table: symbol_table.SymbolTable,
) -> #(symbol_table.SymbolTable, List(String), List(tokenizer.Token)) {
  // パターン: (constructor|function|method) return_type subroutineName "(" parameterList? ")" ...
  case tokens {
    [
      #(tokenizer.Keyword, sub_kw),
      return_type,
      subroutine_name,
      open_paren,
      ..rest
    ] -> {
      // サブルーチン開始時にローカルスコープをリセット
      let sub_sym_table = symbol_table.start_subroutine(sym_table)
      // open_paren の出力
      let xml_acc = [
        tokenizer.add_xml_with_symbol(open_paren, sub_sym_table, False),
      ]

      let #(sub_table, params_xml, after_params) =
        process_params(rest, sub_sym_table, xml_acc)
      let xmls =
        list.append(
          [
            tokenizer.add_xml_with_symbol(
              #(tokenizer.Keyword, sub_kw),
              sym_table,
              False,
            ),
            tokenizer.add_xml_with_symbol(return_type, sym_table, False),
            tokenizer.add_xml_with_symbol(subroutine_name, sub_table, True),
          ],
          params_xml,
        )
      #(sub_table, xmls, after_params)
    }
    _ -> #(sym_table, [], tokens)
  }
}

// パラメータリストを処理する local 関数
fn process_params(
  tokens: List(tokenizer.Token),
  table: symbol_table.SymbolTable,
  acc: List(String),
) -> #(symbol_table.SymbolTable, List(String), List(tokenizer.Token)) {
  case tokens {
    // パラメータがない場合、最初に閉じ括弧が来る
    [#(tokenizer.Symbol, ")"), ..more] -> {
      let acc2 =
        list.append(acc, [
          tokenizer.add_xml_with_symbol(#(tokenizer.Symbol, ")"), table, False),
        ])
      #(table, acc2, more)
    }
    // カンマが来た場合：consume comma, then process parameter
    [#(tokenizer.Symbol, ","), ..more] -> {
      let acc2 =
        list.append(acc, [
          tokenizer.add_xml_with_symbol(#(tokenizer.Symbol, ","), table, False),
        ])
      process_params(more, table, acc2)
    }
    // パラメータ: type_token, identifier_token, then続く
    [type_token, identifier_token, ..more] -> {
      let new_table =
        symbol_table.define(
          table,
          identifier_token.1,
          type_token.1,
          symbol_table.Argument,
        )
      let acc2 =
        list.append(acc, [
          tokenizer.add_xml_with_symbol(type_token, table, False),
          tokenizer.add_xml_with_symbol(identifier_token, new_table, True),
        ])
      process_params(more, new_table, acc2)
    }
    _ -> #(table, acc, tokens)
  }
}
