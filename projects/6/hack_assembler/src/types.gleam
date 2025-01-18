// 1 テキスト行はいずれか
// - アセンブリ命令 (A命令, C命令)
// - ラベル (完全版でのみ実装)
// - コメント
pub type Row {
  Instruction(str: String)
  Label(str: String)
  Comment(str: String)
}
