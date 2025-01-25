import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option, None, Some}

pub type State =
  #(Stack, MemorySegment)

pub type Stack =
  List(StackValue)

pub type StackValue {
  SInt(Int)
  SBool(Bool)
}

pub type MemorySegment =
  Dict(String, Int)

pub fn init() -> State {
  #(
    // stack は最初空
    [],
    // メモリセグメントの初期値
    dict.from_list([
      #("SP", 256),
      #("LCL", 1),
      #("ARG", 2),
      #("THIS", 3),
      #("THAT", 4),
      #("TEMP", 5),
      #("R13", 13),
      #("R14", 14),
      #("R15", 15),
    ]),
  )
}

pub fn push(state: State, value: StackValue) -> State {
  let #(stack, memory_segment) = state
  #(list.prepend(to: stack, this: value), increment_sp(memory_segment))
}

pub fn pop(state: State) -> #(State, StackValue) {
  let #(stack, memory_segment) = state
  case stack {
    [value, ..rest] -> #(#(rest, decrement_sp(memory_segment)), value)
    [] -> panic
  }
}

pub fn add(state: State) -> State {
  let #(state1, value1) = pop(state)
  let #(state2, value2) = pop(state1)
  let added = case value1, value2 {
    SInt(a), SInt(b) -> SInt(a + b)
    _, _ -> panic
  }

  let updated_state = push(state2, added)

  updated_state
}

fn get_segment(segment: MemorySegment, key: String) -> Option(Int) {
  case dict.get(segment, key) {
    Ok(value) -> Some(value)
    Error(_) -> None
  }
}

fn increment_sp(segment: MemorySegment) -> MemorySegment {
  dict.upsert(segment, "SP", fn(value) {
    case value {
      Some(value) -> value + 1
      None -> panic
    }
  })
}

fn decrement_sp(segment: MemorySegment) -> MemorySegment {
  dict.upsert(segment, "SP", fn(value) {
    case value {
      Some(value) -> value - 1
      None -> panic
    }
  })
}
