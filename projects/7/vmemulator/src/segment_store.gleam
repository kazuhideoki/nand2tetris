import gleam/dict.{type Dict}
import gleam/option.{type Option, None, Some}

pub type SegmentStore =
  Dict(String, Int)

pub fn init() -> SegmentStore {
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

pub fn get_segment(segment_store: SegmentStore, key: String) -> Option(Int) {
  case dict.get(segment_store, key) {
    Ok(value) -> Some(value)
    Error(_) -> None
  }
}

pub fn increment_sp(segment_store: SegmentStore) -> SegmentStore {
  dict.upsert(segment_store, "SP", fn(value) {
    case value {
      Some(value) -> value + 1
      None -> panic
    }
  })
}

pub fn decrement_sp(segment_store: SegmentStore) -> SegmentStore {
  dict.upsert(segment_store, "SP", fn(value) {
    case value {
      Some(value) -> value - 1
      None -> panic
    }
  })
}
