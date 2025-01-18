pub type Row {
  AInstruction(str: String)
  CInstruction(CompOrJump)
  LInstruction(str: String)
  Comment(str: String)
}

pub type CompOrJump {
  Comp(dest: String, comp: String)
  Jump(dest: String, jump: String)
}
