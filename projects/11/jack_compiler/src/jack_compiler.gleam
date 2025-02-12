import argv
import gleam/list
import gleam/result
import gleam/string
import parser
import simplifile
import symbol_table
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

// ⭐️方針
// 生成した tokens を再起的にチェックして SymbolTable を更新していく
// var をチェックして宣言とする。
// それ以外は 使用時とする
// メソッド呼び出しをチェックして start_subroutine する
// •	クラス変数の処理
// → クラス宣言の段階で、static や field 宣言を検出してシンボルテーブルに登録する処理が必要。
// 	•	サブルーチンの引数の処理
// → メソッドのパラメータリストも、サブルーチンスコープの一部として define() で登録する必要がある。
// 	•	start_subroutine のタイミング
// → サブルーチン（メソッド）の開始時に start_subroutine() を呼んで、ローカルスコープをリセットするのは大事。
// 	•	「this」ポインタの扱い
// → メソッドの場合、暗黙の引数として this を扱う場合があるので、その処理も必要になるかも。

// 要するに、再帰的にトークンを処理して var 宣言をチェックし、サブルーチン開始時に start_subroutine を呼ぶという基本方針はOKだけど、クラススコープや引数宣言の処理、そして必要に応じた this の扱いをきちんと実装できているか確認しておけば、問題ないと思うよ。
pub fn main() {
  // コマンドライン引数から入力ファイルの内容を読み込む
  use raw_string <- result.try(argv.load().arguments |> parser.get_raw_string)

  // 入力文字列をトークンに分解する
  let tokens = tokenizer.tokenize(raw_string)

  // 新規シンボルテーブルを作成する
  let sym_table = symbol_table.new_symbol_table()

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
