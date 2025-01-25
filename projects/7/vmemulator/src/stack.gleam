import gleam/list

pub type Stack =
  List(StackValue)

pub type StackValue {
  SInt(Int)
  SBool(Bool)
}

pub fn init() -> Stack {
  []
}

pub fn push(stack: Stack, value: StackValue) -> Stack {
  list.prepend(to: stack, this: value)
}

pub fn pop(stack: Stack) -> #(Stack, StackValue) {
  case stack {
    [value, ..rest] -> #(rest, value)
    [] -> panic
  }
}

pub fn add(stack: Stack) -> Stack {
  let #(stack1, value1) = pop(stack)
  let #(stack2, value2) = pop(stack1)
  let added = case value1, value2 {
    SInt(a), SInt(b) -> SInt(a + b)
    _, _ -> panic
  }

  push(stack2, added)
}
