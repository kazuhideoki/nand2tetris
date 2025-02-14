// nand2tetris/projects/11/jack_compiler/src/vm_writer.gleam
import gleam/int

pub type Segment {
  Const
  Arg
  Local
  Static
  This
  That
  Pointer
  Temp
}

pub type ArithmeticCommand {
  Add
  Sub
  Neg
  Eq
  Gt
  Lt
  And
  Or
  Not
}

/// Segment を文字列に変換する補助関数
fn segment_to_string(segment: Segment) -> String {
  case segment {
    Const -> "constant"
    Arg -> "argument"
    Local -> "local"
    Static -> "static"
    This -> "this"
    That -> "that"
    Pointer -> "pointer"
    Temp -> "temp"
  }
}

/// 算術コマンドを文字列に変換する補助関数
fn command_to_string(cmd: ArithmeticCommand) -> String {
  case cmd {
    Add -> "add"
    Sub -> "sub"
    Neg -> "neg"
    Eq -> "eq"
    Gt -> "gt"
    Lt -> "lt"
    And -> "and"
    Or -> "or"
    Not -> "not"
  }
}

/// VM 命令: push
pub fn write_push(segment: Segment, index: Int) -> String {
  "push " <> segment_to_string(segment) <> " " <> int.to_string(index)
}

/// VM 命令: pop
pub fn write_pop(segment: Segment, index: Int) -> String {
  "pop " <> segment_to_string(segment) <> " " <> int.to_string(index)
}

/// VM 命令: 算術・論理
pub fn write_arithmetic(cmd: ArithmeticCommand) -> String {
  command_to_string(cmd)
}

/// VM 命令: label
pub fn write_label(label: String) -> String {
  "label " <> label
}

/// VM 命令: goto
pub fn write_goto(label: String) -> String {
  "goto " <> label
}

/// VM 命令: if-goto
pub fn write_if(label: String) -> String {
  "if-goto " <> label
}

/// VM 命令: call
pub fn write_call(name: String, n_args: Int) -> String {
  "call " <> name <> " " <> int.to_string(n_args)
}

/// VM 命令: function
pub fn write_function(name: String, n_locals: Int) -> String {
  "function " <> name <> " " <> int.to_string(n_locals)
}

/// VM 命令: return
pub fn write_return() -> String {
  "return"
}
