//// TODO メモリセグメントのマッピング。操作も

import gleam/dict.{type Dict}
import gleam/option.{type Option, None, Some}

pub type MemorySegment =
  Dict(String, Int)

pub fn init() -> MemorySegment {
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
  ])
}

pub fn get(segment: MemorySegment, key: String) -> Option(Int) {
  case dict.get(segment, key) {
    Ok(value) -> Some(value)
    Error(_) -> None
  }
}

pub fn increment_sp(segment: MemorySegment) -> MemorySegment {
  dict.upsert(segment, "SP", fn(value) {
    case value {
      Some(value) -> value + 1
      None -> panic
    }
  })
}

pub fn decrement_sp(segment: MemorySegment) -> MemorySegment {
  dict.upsert(segment, "SP", fn(value) {
    case value {
      Some(value) -> value - 1
      None -> panic
    }
  })
}
