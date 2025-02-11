import argv
import gleam/list
import gleam/result
import gleam/string
import parser
import simbol_table
import simplifile
import tokenizer

// TODO 実行できるようになった。正しいかどうか調べる

// output例
// <tokens>
// <keyword> class </keyword>
// <identifier name="Main" kind="class" index="-1" use="used"> Main </identifier>
// <symbol> { </symbol>
// <keyword> function </keyword>
// <keyword> void </keyword>
// <identifier name="main" kind="class" index="-1" use="used"> main </identifier>
pub fn main() {
  // コマンドライン引数から入力ファイルの内容を読み込む
  use raw_string <- result.try(argv.load().arguments |> parser.get_raw_string)

  // 入力文字列をトークンに分解する
  let tokens = tokenizer.tokenize(raw_string)

  // 新規シンボルテーブルを作成する
  let sym_table = simbol_table.new_symbol_table()

  // ここで本来は構文解析の中で「宣言」と「使用」を判断しつつシンボルテーブルを更新する処理を行う。
  // 例：静的宣言や変数宣言の場合は sym_table.define(...) を呼び出し、
  //       識別子トークンの場合は lookup() して情報を得た上で XML に出力する。
  //
  // 今回は簡易例として、すべてのトークンを「used」として XML に出力する処理とする。
  let xml_tokens =
    tokens
    |> list.map(fn(token) {
      // token.0 が Identifier ならシンボルテーブルから lookup を行う。
      // 本来は宣言箇所なら is_declaration = True にすべきだが、ここでは簡略化して常に False とする。
      tokenizer.add_xml_with_symbol(token, sym_table, False)
    })

  let xml = "<tokens>\n" <> xml_tokens |> string.join("\n") <> "\n</tokens>"

  // 出力先（例： output/Output.xml ）へ書き込む
  let _ = simplifile.write("output/Output.xml", xml)

  Ok(Nil)
}
