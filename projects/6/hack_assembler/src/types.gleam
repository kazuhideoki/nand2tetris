pub type Row {
  AInstruction(str: String)
  CInstruction(CInstructionDetail)
  LInstruction(str: String)
  Comment(str: String)
}

pub type CInstructionDetail {
  DestAndComp(dest: String, comp: String)
  CompAndJump(comp: String, jump: String)
}
